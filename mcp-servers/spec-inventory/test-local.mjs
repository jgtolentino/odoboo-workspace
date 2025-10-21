#!/usr/bin/env node

/**
 * Test script for MCP Spec Inventory Server
 * Usage: node test-local.mjs
 */

import { spawn } from 'child_process';
import { writeFileSync } from 'fs';

const tests = [
  {
    name: 'list_features (all)',
    request: {
      jsonrpc: '2.0',
      id: 1,
      method: 'tools/call',
      params: {
        name: 'list_features',
        arguments: { status: 'all' },
      },
    },
  },
  {
    name: 'list_features (implemented only)',
    request: {
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/call',
      params: {
        name: 'list_features',
        arguments: { status: 'implemented' },
      },
    },
  },
  {
    name: 'search_specs (knowledge base)',
    request: {
      jsonrpc: '2.0',
      id: 3,
      method: 'tools/call',
      params: {
        name: 'search_specs',
        arguments: { query: 'knowledge base', category: 'all' },
      },
    },
  },
  {
    name: 'read_spec (knowledge-base-integration.md)',
    request: {
      jsonrpc: '2.0',
      id: 4,
      method: 'tools/call',
      params: {
        name: 'read_spec',
        arguments: { filename: '03-knowledge-base-integration.md' },
      },
    },
  },
  {
    name: 'get_feature_stats',
    request: {
      jsonrpc: '2.0',
      id: 5,
      method: 'tools/call',
      params: {
        name: 'get_feature_stats',
        arguments: {},
      },
    },
  },
];

async function runTest(test) {
  return new Promise((resolve, reject) => {
    console.log(`\n📝 Running: ${test.name}`);
    console.log(`Request: ${JSON.stringify(test.request, null, 2)}\n`);

    const server = spawn('node', ['dist/index.js'], {
      cwd: process.cwd(),
      stdio: ['pipe', 'pipe', 'inherit'],
    });

    let output = '';

    server.stdout.on('data', (data) => {
      output += data.toString();
    });

    server.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Server exited with code ${code}`));
        return;
      }

      try {
        const response = JSON.parse(output);
        console.log(`✅ Response:\n${JSON.stringify(response, null, 2)}\n`);
        resolve(response);
      } catch (error) {
        reject(new Error(`Failed to parse response: ${error.message}`));
      }
    });

    // Send request
    server.stdin.write(JSON.stringify(test.request) + '\n');
    server.stdin.end();

    // Timeout after 5 seconds
    setTimeout(() => {
      server.kill();
      reject(new Error('Test timed out after 5 seconds'));
    }, 5000);
  });
}

async function main() {
  console.log('🧪 MCP Spec Inventory Server - Local Test Suite\n');
  console.log('================================================\n');

  let passed = 0;
  let failed = 0;
  const results = [];

  for (const test of tests) {
    try {
      const response = await runTest(test);
      results.push({
        name: test.name,
        status: 'PASS',
        response,
      });
      passed++;
    } catch (error) {
      console.error(`❌ Test failed: ${error.message}\n`);
      results.push({
        name: test.name,
        status: 'FAIL',
        error: error.message,
      });
      failed++;
    }
  }

  // Summary
  console.log('\n================================================');
  console.log(`\n📊 Test Summary:`);
  console.log(`   Passed: ${passed}/${tests.length}`);
  console.log(`   Failed: ${failed}/${tests.length}`);
  console.log(`   Success Rate: ${((passed / tests.length) * 100).toFixed(1)}%\n`);

  // Write results to file
  writeFileSync(
    'test-results.json',
    JSON.stringify(results, null, 2)
  );
  console.log(`✅ Results saved to test-results.json\n`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
