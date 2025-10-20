#!/usr/bin/env node

/**
 * Spec Inventory Validator
 *
 * Validates that all spec files are properly formatted and referenced in FEATURES.md
 * Generates a spec index for MCP tools
 */

import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { globby } from 'globby';

const OUT_DIR = '.out';
const FEATURES_FILE = 'FEATURES.md';
const SPECS_DIR = 'specs';

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

const errors = [];
const warnings = [];
const index = [];

async function main() {
  console.log(`${colors.blue}🔍 Validating Spec Inventory...${colors.reset}\n`);

  // Create output directory
  if (!fs.existsSync(OUT_DIR)) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  // Check FEATURES.md exists
  if (!fs.existsSync(FEATURES_FILE)) {
    errors.push(`${FEATURES_FILE} not found`);
    printResults();
    process.exit(1);
  }

  const featuresMd = fs.readFileSync(FEATURES_FILE, 'utf8');

  // Find all spec files
  const specFiles = await globby([`${SPECS_DIR}/**/*.{yml,yaml}`]);

  if (specFiles.length === 0) {
    warnings.push(`No spec files found in ${SPECS_DIR}/`);
  }

  console.log(`Found ${specFiles.length} spec files\n`);

  // Validate each spec file
  for (const filePath of specFiles) {
    validateSpecFile(filePath, featuresMd);
  }

  // Write index
  const indexPath = path.join(OUT_DIR, 'spec-index.json');
  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2));
  console.log(`\n${colors.green}✓${colors.reset} Wrote spec index to ${indexPath}`);

  // Print results
  printResults();

  // Exit with error if validation failed
  if (errors.length > 0) {
    process.exit(1);
  }
}

function validateSpecFile(filePath, featuresMd) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const doc = yaml.load(content);

    if (!doc || typeof doc !== 'object') {
      errors.push(`${filePath}: Invalid YAML structure`);
      return;
    }

    const { id, title, priority, owner, status, description, tags } = doc;

    // Required fields
    if (!id) errors.push(`${filePath}: Missing 'id' field`);
    if (!title) errors.push(`${filePath}: Missing 'title' field`);
    if (!priority) errors.push(`${filePath}: Missing 'priority' field`);
    if (!owner) errors.push(`${filePath}: Missing 'owner' field`);
    if (!status) errors.push(`${filePath}: Missing 'status' field`);

    // Validate priority
    if (priority && !['P0', 'P1', 'P2'].includes(priority)) {
      errors.push(`${filePath}: Invalid priority '${priority}' (must be P0, P1, or P2)`);
    }

    // Validate status
    const validStatuses = ['todo', 'doing', 'done', 'paused'];
    if (status && !validStatuses.includes(status)) {
      errors.push(`${filePath}: Invalid status '${status}' (must be one of: ${validStatuses.join(', ')})`);
    }

    // Check if referenced in FEATURES.md
    if (id && !featuresMd.includes(id)) {
      warnings.push(`${filePath}: Spec ID '${id}' not referenced in ${FEATURES_FILE}`);
    }

    // Validate owner format (should be email or username)
    if (owner && !owner.includes('@') && !owner.match(/^[a-zA-Z0-9_-]+$/)) {
      warnings.push(`${filePath}: Owner '${owner}' should be email or username`);
    }

    // Add to index if valid
    if (id && title && priority && owner && status) {
      index.push({
        id,
        title,
        priority,
        owner,
        status,
        description: description || '',
        tags: tags || [],
        file: filePath,
        lastModified: fs.statSync(filePath).mtime.toISOString(),
      });

      console.log(`${colors.green}✓${colors.reset} ${id} - ${title}`);
    }

  } catch (error) {
    errors.push(`${filePath}: ${error.message}`);
  }
}

function printResults() {
  console.log('\n' + '='.repeat(60));

  if (errors.length > 0) {
    console.log(`\n${colors.red}❌ Validation Failed${colors.reset}\n`);
    console.log(`${colors.red}Errors (${errors.length}):${colors.reset}`);
    errors.forEach(err => console.log(`  - ${err}`));
  }

  if (warnings.length > 0) {
    console.log(`\n${colors.yellow}⚠  Warnings (${warnings.length}):${colors.reset}`);
    warnings.forEach(warn => console.log(`  - ${warn}`));
  }

  if (errors.length === 0) {
    console.log(`\n${colors.green}✅ All specs validated successfully!${colors.reset}`);
    console.log(`\nSummary:`);
    console.log(`  Total specs: ${index.length}`);
    console.log(`  By status:`);
    console.log(`    - Done:   ${index.filter(s => s.status === 'done').length}`);
    console.log(`    - Doing:  ${index.filter(s => s.status === 'doing').length}`);
    console.log(`    - Todo:   ${index.filter(s => s.status === 'todo').length}`);
    console.log(`    - Paused: ${index.filter(s => s.status === 'paused').length}`);
    console.log(`  By priority:`);
    console.log(`    - P0: ${index.filter(s => s.priority === 'P0').length}`);
    console.log(`    - P1: ${index.filter(s => s.priority === 'P1').length}`);
    console.log(`    - P2: ${index.filter(s => s.priority === 'P2').length}`);
  }

  console.log('\n' + '='.repeat(60) + '\n');
}

main().catch(err => {
  console.error(`${colors.red}Fatal error:${colors.reset}`, err);
  process.exit(1);
});
