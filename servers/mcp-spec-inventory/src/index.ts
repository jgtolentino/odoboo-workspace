#!/usr/bin/env node

/**
 * MCP Server: Spec Inventory
 *
 * Provides tools for querying and managing the odoboo-workspace spec inventory
 * Works natively in Claude Desktop/Cursor via MCP protocol
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { glob } from 'glob';

const SPECS_DIR = process.env.SPECS_DIR || 'specs';
const WORKSPACE_ROOT = process.env.WORKSPACE_ROOT || process.cwd();

interface Spec {
  id: string;
  title: string;
  priority: 'P0' | 'P1' | 'P2';
  owner: string;
  status: 'todo' | 'doing' | 'done' | 'paused';
  description?: string;
  tags?: string[];
  file?: string;
}

class SpecInventoryServer {
  private server: Server;

  constructor() {
    this.server = new Server(
      {
        name: 'spec-inventory',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'list_features',
          description: 'List all feature specs with their status, priority, and owner',
          inputSchema: {
            type: 'object',
            properties: {
              status: {
                type: 'string',
                enum: ['todo', 'doing', 'done', 'paused'],
                description: 'Filter by status (optional)',
              },
              priority: {
                type: 'string',
                enum: ['P0', 'P1', 'P2'],
                description: 'Filter by priority (optional)',
              },
              owner: {
                type: 'string',
                description: 'Filter by owner (optional)',
              },
            },
          },
        },
        {
          name: 'get_spec',
          description: 'Get full details of a specific spec by ID',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Spec ID (e.g., FEAT-001)',
              },
            },
            required: ['id'],
          },
        },
        {
          name: 'mark_done',
          description: 'Mark a spec as done (generates patch suggestion for review)',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Spec ID to mark as done',
              },
              commit: {
                type: 'string',
                description: 'Git commit SHA that completes this spec (optional)',
              },
              notes: {
                type: 'string',
                description: 'Additional notes (optional)',
              },
            },
            required: ['id'],
          },
        },
        {
          name: 'search_specs',
          description: 'Search specs by keyword in title, description, or tags',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'Search query',
              },
            },
            required: ['query'],
          },
        },
        {
          name: 'create_spec',
          description: 'Create a new spec file with all required fields',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Unique spec ID (e.g., FEAT-042)',
              },
              title: {
                type: 'string',
                description: 'Spec title',
              },
              priority: {
                type: 'string',
                enum: ['P0', 'P1', 'P2'],
                description: 'Priority level',
              },
              owner: {
                type: 'string',
                description: 'Owner email or username',
              },
              status: {
                type: 'string',
                enum: ['todo', 'doing', 'done', 'paused'],
                description: 'Current status',
              },
              description: {
                type: 'string',
                description: 'Detailed description (optional)',
              },
              tags: {
                type: 'array',
                items: { type: 'string' },
                description: 'Tags (optional)',
              },
            },
            required: ['id', 'title', 'priority', 'owner', 'status'],
          },
        },
        {
          name: 'update_spec',
          description: 'Update an existing spec (any field)',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Spec ID to update',
              },
              title: { type: 'string', description: 'New title (optional)' },
              priority: {
                type: 'string',
                enum: ['P0', 'P1', 'P2'],
                description: 'New priority (optional)',
              },
              owner: { type: 'string', description: 'New owner (optional)' },
              status: {
                type: 'string',
                enum: ['todo', 'doing', 'done', 'paused'],
                description: 'New status (optional)',
              },
              description: { type: 'string', description: 'New description (optional)' },
              tags: {
                type: 'array',
                items: { type: 'string' },
                description: 'New tags (optional)',
              },
            },
            required: ['id'],
          },
        },
        {
          name: 'move_spec',
          description: 'Move/rename a spec file to a new location',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Spec ID to move',
              },
              newPath: {
                type: 'string',
                description: 'New file path relative to specs/ (e.g., "features/auth/login.yml")',
              },
            },
            required: ['id', 'newPath'],
          },
        },
        {
          name: 'delete_spec',
          description: 'Delete a spec file (with confirmation)',
          inputSchema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Spec ID to delete',
              },
              confirm: {
                type: 'boolean',
                description: 'Must be true to confirm deletion',
              },
            },
            required: ['id', 'confirm'],
          },
        },
      ],
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      switch (name) {
        case 'list_features':
          return this.listFeatures(args);
        case 'get_spec':
          return this.getSpec(args);
        case 'mark_done':
          return this.markDone(args);
        case 'search_specs':
          return this.searchSpecs(args);
        case 'create_spec':
          return this.createSpec(args);
        case 'update_spec':
          return this.updateSpec(args);
        case 'move_spec':
          return this.moveSpec(args);
        case 'delete_spec':
          return this.deleteSpec(args);
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  private async listFeatures(args: any) {
    const { status, priority, owner } = args || {};

    const specs = await this.loadAllSpecs();

    // Apply filters
    let filtered = specs;
    if (status) filtered = filtered.filter(s => s.status === status);
    if (priority) filtered = filtered.filter(s => s.priority === priority);
    if (owner) filtered = filtered.filter(s => s.owner.includes(owner));

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

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(summary, null, 2),
        },
      ],
    };
  }

  private async getSpec(args: any) {
    const { id } = args;

    if (!id) {
      throw new Error('Spec ID is required');
    }

    const specPath = await this.findSpecFile(id);

    if (!specPath) {
      throw new Error(`Spec not found: ${id}`);
    }

    const content = fs.readFileSync(specPath, 'utf8');

    return {
      content: [
        {
          type: 'text',
          text: content,
        },
      ],
    };
  }

  private async markDone(args: any) {
    const { id, commit, notes } = args;

    if (!id) {
      throw new Error('Spec ID is required');
    }

    const specPath = await this.findSpecFile(id);

    if (!specPath) {
      throw new Error(`Spec not found: ${id}`);
    }

    // Generate patch suggestion (don't apply automatically)
    const suggestion = [
      `# Suggested change for spec ${id}`,
      `# File: ${specPath}`,
      '',
      'Change status from current to:',
      '  status: done',
      '',
      commit ? `Completed in commit: ${commit}` : '',
      notes ? `Notes: ${notes}` : '',
      '',
      '⚠️  This is a suggestion only. Review and apply manually or via CI.',
      '',
      'To apply:',
      `  1. Edit ${specPath}`,
      '  2. Change status: done',
      `  3. git add ${specPath}`,
      `  4. git commit -m "feat: mark ${id} as done"`,
    ].filter(Boolean).join('\n');

    return {
      content: [
        {
          type: 'text',
          text: suggestion,
        },
      ],
    };
  }

  private async searchSpecs(args: any) {
    const { query } = args;

    if (!query) {
      throw new Error('Search query is required');
    }

    const specs = await this.loadAllSpecs();
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

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            query,
            matches: matches.length,
            results: matches,
          }, null, 2),
        },
      ],
    };
  }

  private async createSpec(args: any) {
    const { id, title, priority, owner, status, description, tags } = args;

    // Validate required fields
    if (!id || !title || !priority || !owner || !status) {
      throw new Error('Missing required fields: id, title, priority, owner, status');
    }

    // Check if spec already exists
    const existing = await this.findSpecFile(id);
    if (existing) {
      throw new Error(`Spec ${id} already exists at ${existing}`);
    }

    // Create spec object
    const spec: Spec = {
      id,
      title,
      priority,
      owner,
      status,
      ...(description && { description }),
      ...(tags && { tags }),
    };

    // Determine file path based on ID
    const fileName = `${id.toLowerCase().replace(/[^a-z0-9-]/g, '-')}.yml`;
    const filePath = path.join(WORKSPACE_ROOT, SPECS_DIR, fileName);

    // Ensure directory exists
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // Write spec file
    const yamlContent = yaml.dump(spec, { indent: 2, lineWidth: 100 });
    fs.writeFileSync(filePath, yamlContent, 'utf8');

    return {
      content: [
        {
          type: 'text',
          text: [
            `✅ Created spec ${id}`,
            `📄 File: ${path.relative(WORKSPACE_ROOT, filePath)}`,
            '',
            '```yaml',
            yamlContent,
            '```',
            '',
            '⚠️  Remember to:',
            '1. Add reference to FEATURES.md',
            `2. git add ${path.relative(WORKSPACE_ROOT, filePath)}`,
            `3. git commit -m "feat: add spec ${id}"`,
          ].join('\n'),
        },
      ],
    };
  }

  private async updateSpec(args: any) {
    const { id, ...updates } = args;

    if (!id) {
      throw new Error('Spec ID is required');
    }

    const specPath = await this.findSpecFile(id);
    if (!specPath) {
      throw new Error(`Spec not found: ${id}`);
    }

    // Load existing spec
    const content = fs.readFileSync(specPath, 'utf8');
    const spec = yaml.load(content) as Spec;

    // Apply updates
    const updated = { ...spec, ...Object.fromEntries(Object.entries(updates).filter(([_, v]) => v !== undefined)) };

    // Write updated spec
    const yamlContent = yaml.dump(updated, { indent: 2, lineWidth: 100 });
    fs.writeFileSync(specPath, yamlContent, 'utf8');

    return {
      content: [
        {
          type: 'text',
          text: [
            `✅ Updated spec ${id}`,
            `📄 File: ${path.relative(WORKSPACE_ROOT, specPath)}`,
            '',
            'Changes:',
            ...Object.entries(updates).filter(([_, v]) => v !== undefined).map(([k, v]) => `  - ${k}: ${JSON.stringify(v)}`),
            '',
            '```yaml',
            yamlContent,
            '```',
          ].join('\n'),
        },
      ],
    };
  }

  private async moveSpec(args: any) {
    const { id, newPath } = args;

    if (!id || !newPath) {
      throw new Error('Spec ID and newPath are required');
    }

    const oldPath = await this.findSpecFile(id);
    if (!oldPath) {
      throw new Error(`Spec not found: ${id}`);
    }

    // Ensure newPath is relative to specs/ and has .yml extension
    let targetPath = newPath;
    if (!targetPath.endsWith('.yml') && !targetPath.endsWith('.yaml')) {
      targetPath += '.yml';
    }
    const fullNewPath = path.join(WORKSPACE_ROOT, SPECS_DIR, targetPath);

    // Ensure directory exists
    const dir = path.dirname(fullNewPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // Move file
    fs.renameSync(oldPath, fullNewPath);

    return {
      content: [
        {
          type: 'text',
          text: [
            `✅ Moved spec ${id}`,
            `From: ${path.relative(WORKSPACE_ROOT, oldPath)}`,
            `To:   ${path.relative(WORKSPACE_ROOT, fullNewPath)}`,
            '',
            '⚠️  Remember to:',
            `1. git add ${path.relative(WORKSPACE_ROOT, fullNewPath)}`,
            `2. git rm ${path.relative(WORKSPACE_ROOT, oldPath)}`,
            `3. git commit -m "refactor: move spec ${id}"`,
          ].join('\n'),
        },
      ],
    };
  }

  private async deleteSpec(args: any) {
    const { id, confirm } = args;

    if (!id) {
      throw new Error('Spec ID is required');
    }

    if (!confirm) {
      return {
        content: [
          {
            type: 'text',
            text: [
              `⚠️  Delete confirmation required for spec ${id}`,
              '',
              'To confirm deletion, call again with:',
              '  { id: "' + id + '", confirm: true }',
            ].join('\n'),
          },
        ],
      };
    }

    const specPath = await this.findSpecFile(id);
    if (!specPath) {
      throw new Error(`Spec not found: ${id}`);
    }

    // Delete file
    fs.unlinkSync(specPath);

    return {
      content: [
        {
          type: 'text',
          text: [
            `✅ Deleted spec ${id}`,
            `📄 File: ${path.relative(WORKSPACE_ROOT, specPath)}`,
            '',
            '⚠️  Remember to:',
            '1. Remove reference from FEATURES.md',
            `2. git rm ${path.relative(WORKSPACE_ROOT, specPath)}`,
            `3. git commit -m "feat: remove spec ${id}"`,
          ].join('\n'),
        },
      ],
    };
  }

  private async loadAllSpecs(): Promise<Spec[]> {
    const specsPath = path.join(WORKSPACE_ROOT, SPECS_DIR);
    const files = await glob(`${specsPath}/**/*.{yml,yaml}`);

    const specs: Spec[] = [];

    for (const file of files) {
      try {
        const content = fs.readFileSync(file, 'utf8');
        const spec = yaml.load(content) as Spec;

        if (spec && spec.id) {
          specs.push({
            ...spec,
            file: path.relative(WORKSPACE_ROOT, file),
          });
        }
      } catch (error) {
        console.error(`Error loading ${file}:`, error);
      }
    }

    return specs;
  }

  private async findSpecFile(id: string): Promise<string | null> {
    const specs = await this.loadAllSpecs();
    const spec = specs.find(s => s.id === id);
    return spec?.file ? path.join(WORKSPACE_ROOT, spec.file) : null;
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Spec Inventory MCP server running on stdio');
  }
}

const server = new SpecInventoryServer();
server.run().catch(console.error);
