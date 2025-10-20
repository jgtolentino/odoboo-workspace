#!/usr/bin/env node
/* eslint-disable no-console */
const { execSync } = require('child_process');
const https = require('https');

const repo = process.env.GITHUB_REPOSITORY;
const prNumber = process.env.PR_NUMBER;
const agentUrl = process.env.ODOOBO_AGENT_URL;
const agentKey = process.env.ODOOBO_AGENT_KEY;
const githubToken = process.env.GITHUB_TOKEN;

if (!repo || !prNumber || !agentUrl || !agentKey || !githubToken) {
  console.error('Missing required environment variables');
  process.exit(1);
}

// 1) Gather diff
const diff = execSync(`gh pr diff ${prNumber}`, { encoding: 'utf8' });

// 2) Call odoobo-expert agent
const payload = JSON.stringify({
  messages: [
    {
      role: 'user',
      content: `Review this PR diff:\n\n${diff}`,
    },
  ],
});

const url = new URL(agentUrl);
const options = {
  hostname: url.hostname,
  path: url.pathname,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload),
    Authorization: `Bearer ${agentKey}`,
  },
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  res.on('end', () => {
    if (res.statusCode !== 200) {
      console.error(`Agent returned ${res.statusCode}: ${body}`);
      process.exit(1);
    }

    const parsed = JSON.parse(body);
    const review = parsed.content?.[0]?.text || 'No review content';

    // 3) Post as PR comment
    execSync(`gh pr comment ${prNumber} --body "${review.replace(/"/g, '\\"')}"`, {
      stdio: 'inherit',
    });

    console.log('✅ Review posted successfully');
  });
});

req.on('error', (err) => {
  console.error('Request failed:', err.message);
  process.exit(1);
});

req.write(payload);
req.end();
