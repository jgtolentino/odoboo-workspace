/**
 * Test script for ChatGPT Plugin Server
 * Run with: node test.js
 */

const https = require('https');
const http = require('http');

require('dotenv').config();

const BASE_URL = process.env.HOST || 'http://localhost:3000';
const BEARER_TOKEN = process.env.PLUGIN_BEARER_TOKEN;

// Helper to make requests
function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const isHttps = url.protocol === 'https:';
    const lib = isHttps ? https : http;

    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${BEARER_TOKEN}`
      }
    };

    const req = lib.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

// Tests
async function runTests() {
  console.log('🧪 Running tests against:', BASE_URL);
  console.log('');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`✅ ${name}`);
      passed++;
    } catch (error) {
      console.error(`❌ ${name}`);
      console.error(`   Error: ${error.message}`);
      failed++;
    }
  }

  // Test 1: Health check
  await test('Health check', async () => {
    const res = await request('GET', '/health');
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
    if (res.data.status !== 'ok') throw new Error('Status not ok');
  });

  // Test 2: Plugin manifest
  await test('Plugin manifest', async () => {
    const res = await request('GET', '/.well-known/ai-plugin.json');
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
    if (!res.data.name_for_model) throw new Error('Invalid manifest');
  });

  // Test 3: OpenAPI spec
  await test('OpenAPI spec', async () => {
    const res = await request('GET', '/.well-known/openapi.yaml');
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
    if (!res.data.includes('openapi: 3.0.1')) throw new Error('Invalid OpenAPI spec');
  });

  // Test 4: Authentication (should fail without token)
  await test('Authentication required', async () => {
    const url = new URL('/repos/test/test/contents/README.md', BASE_URL);
    const isHttps = url.protocol === 'https:';
    const lib = isHttps ? https : http;

    return new Promise((resolve, reject) => {
      const req = lib.request(url, { method: 'GET' }, (res) => {
        if (res.statusCode === 401) {
          resolve();
        } else {
          reject(new Error(`Expected 401, got ${res.statusCode}`));
        }
      });
      req.on('error', reject);
      req.end();
    });
  });

  // Test 5: GitHub file read (requires valid repo)
  if (process.env.TEST_REPO) {
    const [owner, repo] = process.env.TEST_REPO.split('/');
    await test(`Read file from ${owner}/${repo}`, async () => {
      const res = await request('GET', `/repos/${owner}/${repo}/contents/README.md`);
      if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
      if (!res.data.content) throw new Error('No content returned');
    });
  } else {
    console.log('⏭️  Skipping GitHub tests (set TEST_REPO=owner/repo to enable)');
  }

  // Summary
  console.log('');
  console.log('═══════════════════════════════════');
  console.log(`Tests: ${passed + failed}`);
  console.log(`Passed: ${passed} ✅`);
  console.log(`Failed: ${failed} ❌`);
  console.log('═══════════════════════════════════');

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
