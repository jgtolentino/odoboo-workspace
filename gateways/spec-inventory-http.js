#!/usr/bin/env node

/**
 * HTTP Gateway for Spec Inventory (ChatGPT compatibility)
 *
 * Exposes MCP tools as REST API for ChatGPT Actions
 */

import express from 'express';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { glob } from 'glob';

const app = express();
const PORT = process.env.PORT || 8787;
const MCP_ADMIN_TOKEN = process.env.MCP_ADMIN_TOKEN;
const WORKSPACE_ROOT = process.env.WORKSPACE_ROOT || '/opt/fin-workspace';
const SPECS_DIR = process.env.SPECS_DIR || 'specs';

app.use(express.json());

// CORS for ChatGPT
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// Authentication middleware
function authenticate(req, res, next) {
  const auth = req.headers.authorization;

  // Public read operations don't require auth
  if (req.path === '/list_features' || req.path === '/get_spec' || req.path === '/search_specs') {
    return next();
  }

  // Write operations require admin token
  if (!MCP_ADMIN_TOKEN) {
    return res.status(500).json({ error: 'MCP_ADMIN_TOKEN not configured' });
  }

  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized - Bearer token required' });
  }

  const token = auth.substring(7);
  if (token !== MCP_ADMIN_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized - Invalid token' });
  }

  next();
}

// Helper: Load all specs
async function loadAllSpecs() {
  const specsPath = path.join(WORKSPACE_ROOT, SPECS_DIR);
  const files = await glob(`${specsPath}/**/*.{yml,yaml}`);

  const specs = [];

  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf8');
      const spec = yaml.load(content);

      if (spec && spec.id) {
        specs.push({
          ...spec,
          file: path.relative(WORKSPACE_ROOT, file),
        });
      }
    } catch (error) {
      console.error(`Error loading ${file}:`, error.message);
    }
  }

  return specs;
}

// Helper: Find spec file by ID
async function findSpecFile(id) {
  const specs = await loadAllSpecs();
  const spec = specs.find(s => s.id === id);
  return spec?.file ? path.join(WORKSPACE_ROOT, spec.file) : null;
}

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'spec-inventory-gateway', timestamp: new Date().toISOString() });
});

app.post('/list_features', async (req, res) => {
  try {
    const { status, priority, owner } = req.body || {};

    const specs = await loadAllSpecs();

    // Apply filters
    let filtered = specs;
    if (status) filtered = filtered.filter(s => s.status === status);
    if (priority) filtered = filtered.filter(s => s.priority === priority);
    if (owner) filtered = filtered.filter(s => s.owner && s.owner.includes(owner));

    const summary = {
      total: filtered.length,
      byStatus: {
        todo: filtered.filter(s => s.status === 'todo').length,
        doing: filtered.filter(s => s.status === 'doing').length,
        done: filtered.filter(s => s.status === 'done').length,
        paused: filtered.filter(s => s.status === 'paused').length,
      },
      byPriority: {
        P0: filtered.filter(s => s.priority === 'P0').length,
        P1: filtered.filter(s => s.priority === 'P1').length,
        P2: filtered.filter(s => s.priority === 'P2').length,
      },
      specs: filtered,
    };

    res.json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/get_spec', async (req, res) => {
  try {
    const { id } = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Spec ID is required' });
    }

    const specPath = await findSpecFile(id);

    if (!specPath) {
      return res.status(404).json({ error: `Spec not found: ${id}` });
    }

    const content = fs.readFileSync(specPath, 'utf8');
    const spec = yaml.load(content);

    res.json(spec);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/search_specs', async (req, res) => {
  try {
    const { query } = req.body;

    if (!query) {
      return res.status(400).json({ error: 'Search query is required' });
    }

    const specs = await loadAllSpecs();
    const lowerQuery = query.toLowerCase();

    const matches = specs.filter(spec => {
      const searchText = [
        spec.id,
        spec.title,
        spec.description || '',
        ...(spec.tags || []),
      ].join(' ').toLowerCase();

      return searchText.includes(lowerQuery);
    });

    res.json({
      query,
      matches: matches.length,
      results: matches,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/create_spec', authenticate, async (req, res) => {
  try {
    const { id, title, priority, owner, status, description, tags } = req.body;

    if (!id || !title || !priority || !owner || !status) {
      return res.status(400).json({ error: 'Missing required fields: id, title, priority, owner, status' });
    }

    const existing = await findSpecFile(id);
    if (existing) {
      return res.status(409).json({ error: `Spec ${id} already exists at ${existing}` });
    }

    const spec = {
      id,
      title,
      priority,
      owner,
      status,
      ...(description && { description }),
      ...(tags && { tags }),
    };

    const fileName = `${id.toLowerCase().replace(/[^a-z0-9-]/g, '-')}.yml`;
    const filePath = path.join(WORKSPACE_ROOT, SPECS_DIR, fileName);

    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(filePath, yaml.dump(spec, { indent: 2, lineWidth: 100 }), 'utf8');

    res.json({
      success: true,
      id,
      file: path.relative(WORKSPACE_ROOT, filePath),
      spec,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/update_spec', authenticate, async (req, res) => {
  try {
    const { id, ...updates } = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Spec ID is required' });
    }

    const specPath = await findSpecFile(id);
    if (!specPath) {
      return res.status(404).json({ error: `Spec not found: ${id}` });
    }

    const content = fs.readFileSync(specPath, 'utf8');
    const spec = yaml.load(content);

    const updated = { ...spec, ...Object.fromEntries(Object.entries(updates).filter(([_, v]) => v !== undefined)) };

    fs.writeFileSync(specPath, yaml.dump(updated, { indent: 2, lineWidth: 100 }), 'utf8');

    res.json({
      success: true,
      id,
      file: path.relative(WORKSPACE_ROOT, specPath),
      spec: updated,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/mark_done', authenticate, async (req, res) => {
  try {
    const { id, commit, notes } = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Spec ID is required' });
    }

    const specPath = await findSpecFile(id);
    if (!specPath) {
      return res.status(404).json({ error: `Spec not found: ${id}` });
    }

    const content = fs.readFileSync(specPath, 'utf8');
    const spec = yaml.load(content);

    spec.status = 'done';
    if (commit) spec.completedInCommit = commit;
    if (notes) spec.completionNotes = notes;

    fs.writeFileSync(specPath, yaml.dump(spec, { indent: 2, lineWidth: 100 }), 'utf8');

    res.json({
      success: true,
      id,
      message: `Spec ${id} marked as done`,
      file: path.relative(WORKSPACE_ROOT, specPath),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Spec Inventory HTTP Gateway listening on port ${PORT}`);
  console.log(`Workspace: ${WORKSPACE_ROOT}`);
  console.log(`Specs directory: ${SPECS_DIR}`);
  console.log(`Authentication: ${MCP_ADMIN_TOKEN ? 'Enabled' : 'Disabled (read-only)'}`);
});
