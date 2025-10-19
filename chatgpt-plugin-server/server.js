/**
 * ChatGPT Plugin Server for GitHub & Infrastructure Management
 *
 * Provides REST API endpoints for ChatGPT to interact with:
 * - GitHub (via GitHub App)
 * - Supabase (direct connection)
 * - Digital Ocean (via API)
 * - Vercel (via API)
 */

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');
const { createAppAuth } = require('@octokit/auth-app');
const { Octokit } = require('@octokit/rest');
const { Base64 } = require('js-base64');

require('dotenv').config();

// ============================================================================
// Configuration
// ============================================================================

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || `http://localhost:${PORT}`;
const GITHUB_APP_ID = process.env.GITHUB_APP_ID;
const GITHUB_PRIVATE_KEY = process.env.GITHUB_PRIVATE_KEY ||
  (process.env.GITHUB_PRIVATE_KEY_PATH ?
    fs.readFileSync(process.env.GITHUB_PRIVATE_KEY_PATH, 'utf8') : null);
const PLUGIN_BEARER_TOKEN = process.env.PLUGIN_BEARER_TOKEN;

// Validation
if (!GITHUB_APP_ID || !GITHUB_PRIVATE_KEY) {
  console.error('❌ Missing GITHUB_APP_ID or GITHUB_PRIVATE_KEY in environment');
  process.exit(1);
}

// ============================================================================
// Express App Setup
// ============================================================================

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: ['https://chat.openai.com', 'https://chatgpt.com'],
  credentials: true
}));

// Request parsing
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Logging
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { error: 'Too many requests, please try again later.' }
});
app.use('/repos', limiter);

// ============================================================================
// Authentication Middleware
// ============================================================================

function requireAuth(req, res, next) {
  if (!PLUGIN_BEARER_TOKEN) {
    console.warn('⚠️  No PLUGIN_BEARER_TOKEN set - allowing all requests');
    return next();
  }

  const authHeader = req.headers.authorization || '';
  const expectedAuth = `Bearer ${PLUGIN_BEARER_TOKEN}`;

  if (authHeader !== expectedAuth) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or missing authorization token'
    });
  }

  next();
}

// Apply auth to all API routes
app.use('/repos', requireAuth);

// ============================================================================
// GitHub App Authentication
// ============================================================================

/**
 * Get Octokit instance for a specific repository
 * Automatically finds the installation ID for the repo
 */
async function getOctokitForRepo(owner, repo) {
  const auth = createAppAuth({
    appId: GITHUB_APP_ID,
    privateKey: GITHUB_PRIVATE_KEY,
  });

  // Get JWT token to authenticate as the app
  const appAuth = await auth({ type: 'app' });
  const octokitApp = new Octokit({ auth: appAuth.token });

  // Find installation for this repo
  try {
    const installResp = await octokitApp.rest.apps.getRepoInstallation({
      owner,
      repo
    });
    const installationId = installResp.data.id;

    // Get installation token
    const installationAuth = await auth({
      type: 'installation',
      installationId
    });

    return new Octokit({ auth: installationAuth.token });
  } catch (error) {
    throw new Error(`GitHub App not installed on ${owner}/${repo}: ${error.message}`);
  }
}

// ============================================================================
// Plugin Manifest & OpenAPI
// ============================================================================

app.get('/.well-known/ai-plugin.json', (req, res) => {
  const manifest = {
    schema_version: 'v1',
    name_for_human: 'GitHub & Infrastructure Manager',
    name_for_model: 'github_infra',
    description_for_human: 'Manage GitHub repos, Supabase, Digital Ocean, and Vercel deployments.',
    description_for_model: 'Plugin for managing GitHub repositories (files, PRs, issues, branches) and infrastructure (Supabase, Digital Ocean, Vercel). Use this for code management, deployments, and database operations.',
    auth: {
      type: 'service_http',
      authorization_type: 'bearer',
      verification_tokens: {}
    },
    api: {
      type: 'openapi',
      url: `${HOST}/.well-known/openapi.yaml`,
      is_user_authenticated: false
    },
    logo_url: `${HOST}/logo.png`,
    contact_email: 'jgtolentino.rn@gmail.com',
    legal_info_url: `${HOST}/legal`
  };

  res.json(manifest);
});

app.get('/.well-known/openapi.yaml', (req, res) => {
  const openapi = fs.readFileSync(
    path.join(__dirname, 'openapi.yaml'),
    'utf8'
  ).replace(/YOUR_HOST/g, HOST);

  res.type('application/yaml').send(openapi);
});

// ============================================================================
// GitHub Endpoints
// ============================================================================

/**
 * GET /repos/:owner/:repo/contents/:path
 * Read file contents from GitHub
 */
app.get('/repos/:owner/:repo/contents/*', async (req, res) => {
  const { owner, repo } = req.params;
  const filePath = req.params[0] || '';

  try {
    const octokit = await getOctokitForRepo(owner, repo);
    const response = await octokit.rest.repos.getContent({
      owner,
      repo,
      path: filePath,
    });

    // Handle directory listing
    if (Array.isArray(response.data)) {
      return res.json({
        type: 'directory',
        contents: response.data.map(item => ({
          name: item.name,
          path: item.path,
          type: item.type,
          sha: item.sha
        }))
      });
    }

    // Handle file content
    const content = response.data.encoding === 'base64'
      ? Base64.decode(response.data.content)
      : response.data.content;

    res.json({
      type: 'file',
      path: response.data.path,
      sha: response.data.sha,
      size: response.data.size,
      content
    });
  } catch (error) {
    console.error('Error reading file:', error);
    res.status(error.status || 500).json({
      error: error.message,
      details: error.response?.data || error.message
    });
  }
});

/**
 * PUT /repos/:owner/:repo/contents/:path
 * Create or update a file
 */
app.put('/repos/:owner/:repo/contents/*', async (req, res) => {
  const { owner, repo } = req.params;
  const filePath = req.params[0];
  const { message, content, branch, sha } = req.body;

  if (!message || !content) {
    return res.status(400).json({
      error: 'Missing required fields: message and content'
    });
  }

  try {
    const octokit = await getOctokitForRepo(owner, repo);

    // Encode content to base64
    const contentB64 = Base64.encode(content);

    const params = {
      owner,
      repo,
      path: filePath,
      message,
      content: contentB64,
    };

    if (branch) params.branch = branch;
    if (sha) params.sha = sha; // Required for updates

    const result = await octokit.rest.repos.createOrUpdateFileContents(params);

    res.json({
      success: true,
      commit: result.data.commit,
      content: result.data.content
    });
  } catch (error) {
    console.error('Error updating file:', error);
    res.status(error.status || 500).json({
      error: error.message,
      details: error.response?.data || error.message
    });
  }
});

/**
 * POST /repos/:owner/:repo/branches
 * Create a new branch
 */
app.post('/repos/:owner/:repo/branches', async (req, res) => {
  const { owner, repo } = req.params;
  const { branch, from_branch } = req.body;

  if (!branch) {
    return res.status(400).json({ error: 'Missing required field: branch' });
  }

  try {
    const octokit = await getOctokitForRepo(owner, repo);

    // Get the SHA of the source branch
    const fromBranch = from_branch || 'main';
    const refResp = await octokit.rest.git.getRef({
      owner,
      repo,
      ref: `heads/${fromBranch}`
    });

    const sha = refResp.data.object.sha;

    // Create new branch
    const result = await octokit.rest.git.createRef({
      owner,
      repo,
      ref: `refs/heads/${branch}`,
      sha
    });

    res.status(201).json({
      success: true,
      branch: branch,
      sha: result.data.object.sha
    });
  } catch (error) {
    console.error('Error creating branch:', error);
    res.status(error.status || 500).json({
      error: error.message,
      details: error.response?.data || error.message
    });
  }
});

/**
 * POST /repos/:owner/:repo/pulls
 * Create a pull request
 */
app.post('/repos/:owner/:repo/pulls', async (req, res) => {
  const { owner, repo } = req.params;
  const { title, head, base, body } = req.body;

  if (!title || !head || !base) {
    return res.status(400).json({
      error: 'Missing required fields: title, head, base'
    });
  }

  try {
    const octokit = await getOctokitForRepo(owner, repo);
    const result = await octokit.rest.pulls.create({
      owner,
      repo,
      title,
      head,
      base,
      body: body || ''
    });

    res.status(201).json({
      success: true,
      number: result.data.number,
      url: result.data.html_url,
      state: result.data.state
    });
  } catch (error) {
    console.error('Error creating PR:', error);
    res.status(error.status || 500).json({
      error: error.message,
      details: error.response?.data || error.message
    });
  }
});

/**
 * POST /repos/:owner/:repo/issues
 * Create an issue
 */
app.post('/repos/:owner/:repo/issues', async (req, res) => {
  const { owner, repo } = req.params;
  const { title, body, labels } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'Missing required field: title' });
  }

  try {
    const octokit = await getOctokitForRepo(owner, repo);
    const result = await octokit.rest.issues.create({
      owner,
      repo,
      title,
      body: body || '',
      labels: labels || []
    });

    res.status(201).json({
      success: true,
      number: result.data.number,
      url: result.data.html_url,
      state: result.data.state
    });
  } catch (error) {
    console.error('Error creating issue:', error);
    res.status(error.status || 500).json({
      error: error.message,
      details: error.response?.data || error.message
    });
  }
});

// ============================================================================
// Health & Status
// ============================================================================

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    github_app_id: GITHUB_APP_ID,
    auth_configured: !!PLUGIN_BEARER_TOKEN
  });
});

app.get('/', (req, res) => {
  res.json({
    name: 'ChatGPT Plugin Server',
    version: '1.0.0',
    endpoints: {
      manifest: '/.well-known/ai-plugin.json',
      openapi: '/.well-known/openapi.yaml',
      health: '/health'
    }
  });
});

// ============================================================================
// Error Handling
// ============================================================================

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// ============================================================================
// Start Server
// ============================================================================

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════════╗
║  ChatGPT Plugin Server                                         ║
╠════════════════════════════════════════════════════════════════╣
║  Status: Running                                               ║
║  Port: ${PORT}                                                    ║
║  Host: ${HOST}                                ║
║                                                                ║
║  Endpoints:                                                    ║
║    • Manifest: ${HOST}/.well-known/ai-plugin.json ║
║    • OpenAPI:  ${HOST}/.well-known/openapi.yaml   ║
║    • Health:   ${HOST}/health                     ║
╚════════════════════════════════════════════════════════════════╝
  `);
});
