# Platform Management APIs

Comprehensive guide to management APIs for all platforms in the stack.

## Current Stack Platforms

### 1. **Supabase** ✅ (Already Integrated)
**API Endpoint**: `https://api.supabase.com/v1`
**Authentication**: Bearer token (`SUPABASE_ACCESS_TOKEN`)
**Capabilities**:
- Project management (create, update, delete)
- Database operations (migrations, resets)
- Edge Function deployment
- Vault secret management
- Storage bucket management
- Auth configuration

**API Documentation**: https://supabase.com/docs/reference/api

**Example Operations**:
```bash
# List projects
curl "https://api.supabase.com/v1/projects" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Get project details
curl "https://api.supabase.com/v1/projects/spdtwktxdalcfigzeqrz" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# List database extensions
curl "https://api.supabase.com/v1/projects/spdtwktxdalcfigzeqrz/database/extensions" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Deploy Edge Function
supabase functions deploy chatgpt-plugin --project-ref spdtwktxdalcfigzeqrz

# Manage secrets
supabase secrets set KEY=value --project-ref spdtwktxdalcfigzeqrz
```

---

### 2. **DigitalOcean** ✅ (Primary Deployment Platform)
**API Endpoint**: `https://api.digitalocean.com/v2`
**Authentication**: Bearer token (`DO_ACCESS_TOKEN`)
**CLI**: `doctl` (already used for app deployments)

**Capabilities**:
- App Platform deployment (OCR service, expense API)
- Droplet management
- Spaces (object storage)
- Kubernetes clusters
- Load balancers
- Databases

**API Documentation**: https://docs.digitalocean.com/reference/api/

**Example Operations**:
```bash
# List apps
doctl apps list

# Get app details
doctl apps get b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9

# Update app spec
doctl apps update b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --spec infra/do/ade-ocr-service.yaml

# Create deployment
doctl apps create-deployment b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force-rebuild

# Get deployment logs
doctl apps logs b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --deployment <deployment-id>

# Via REST API
curl "https://api.digitalocean.com/v2/apps" \
  -H "Authorization: Bearer $DO_ACCESS_TOKEN"

# Get app info
curl "https://api.digitalocean.com/v2/apps/b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9" \
  -H "Authorization: Bearer $DO_ACCESS_TOKEN"

# Create deployment
curl -X POST "https://api.digitalocean.com/v2/apps/b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9/deployments" \
  -H "Authorization: Bearer $DO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"force_build": true}'
```

---

### 3. **GitHub** ✅ (Repository & CI/CD)
**API Endpoint**: `https://api.github.com`
**Authentication**: Personal Access Token (`GITHUB_TOKEN`)
**Capabilities**:
- Repository management
- Issue/PR operations
- GitHub Actions workflows
- Secrets management (for CI/CD)
- Releases and tags
- Branch protection rules

**API Documentation**: https://docs.github.com/en/rest

**Example Operations**:
```bash
# Get authenticated user
curl "https://api.github.com/user" \
  -H "Authorization: Bearer $GITHUB_TOKEN"

# List repositories
curl "https://api.github.com/user/repos" \
  -H "Authorization: Bearer $GITHUB_TOKEN"

# Create repository
curl -X POST "https://api.github.com/user/repos" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "new-repo", "private": true}'

# Get repository contents
curl "https://api.github.com/repos/jgtolentino/odoboo-workspace/contents/README.md" \
  -H "Authorization: Bearer $GITHUB_TOKEN"

# Create/update file
curl -X PUT "https://api.github.com/repos/jgtolentino/odoboo-workspace/contents/path/to/file.md" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Update file",
    "content": "base64_encoded_content",
    "sha": "existing_file_sha"
  }'

# List GitHub Actions secrets
curl "https://api.github.com/repos/jgtolentino/odoboo-workspace/actions/secrets" \
  -H "Authorization: Bearer $GITHUB_TOKEN"

# Create/update secret (requires encryption with repo public key)
curl -X PUT "https://api.github.com/repos/jgtolentino/odoboo-workspace/actions/secrets/SECRET_NAME" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "encrypted_value": "encrypted_base64_value",
    "key_id": "public_key_id"
  }'

# Trigger workflow dispatch
curl -X POST "https://api.github.com/repos/jgtolentino/odoboo-workspace/actions/workflows/deploy.yml/dispatches" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ref": "main", "inputs": {"environment": "production"}}'
```

---

### 4. **Vercel** (Frontend Deployment)
**API Endpoint**: `https://api.vercel.com`
**Authentication**: Bearer token (Vercel API token)
**CLI**: `vercel`

**Capabilities**:
- Project deployment
- Environment variable management
- Domain management
- Build logs
- Deployment rollbacks

**API Documentation**: https://vercel.com/docs/rest-api

**Example Operations**:
```bash
# Deploy via CLI
vercel --prod

# List projects via API
curl "https://api.vercel.com/v9/projects" \
  -H "Authorization: Bearer $VERCEL_TOKEN"

# Get project details
curl "https://api.vercel.com/v9/projects/atomic-crm" \
  -H "Authorization: Bearer $VERCEL_TOKEN"

# List deployments
curl "https://api.vercel.com/v6/deployments?projectId=prj_xxx" \
  -H "Authorization: Bearer $VERCEL_TOKEN"

# Get deployment details
curl "https://api.vercel.com/v13/deployments/dpl_xxx" \
  -H "Authorization: Bearer $VERCEL_TOKEN"

# Create environment variable
curl -X POST "https://api.vercel.com/v10/projects/atomic-crm/env" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "API_KEY",
    "value": "secret_value",
    "type": "encrypted",
    "target": ["production"]
  }'
```

---

### 5. **OpenAI** (LLM Provider)
**API Endpoint**: `https://api.openai.com/v1`
**Authentication**: Bearer token (OpenAI API key)
**Capabilities**:
- Chat completions (GPT-4, GPT-4o-mini)
- Image generation (DALL-E)
- Audio transcription (Whisper)
- Embeddings
- Fine-tuning
- Assistants API
- Usage tracking

**API Documentation**: https://platform.openai.com/docs/api-reference

**Example Operations**:
```bash
# Chat completion
curl "https://api.openai.com/v1/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# List models
curl "https://api.openai.com/v1/models" \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Usage/billing (requires different endpoint)
curl "https://api.openai.com/v1/usage" \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

---

### 6. **Anthropic** (Claude AI)
**API Endpoint**: `https://api.anthropic.com/v1`
**Authentication**: `x-api-key` header (Anthropic API key)
**Capabilities**:
- Claude chat completions
- Streaming responses
- Vision capabilities
- Usage tracking

**API Documentation**: https://docs.anthropic.com/en/api

**Example Operations**:
```bash
# Claude chat completion
curl "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## Unified Secret Management via Supabase Vault

All API keys can be stored in Supabase Vault and accessed by AI agents:

```typescript
// In Edge Functions or via MCP
import { getSecret } from './vault-client.ts'

// Get any platform API key
const githubToken = await getSecret('github_token')
const doToken = await getSecret('do_access_token')
const openaiKey = await getSecret('openai_api_key')
const anthropicKey = await getSecret('anthropic_api_key')
const vercelToken = await getSecret('vercel_token')
```

---

## AI Agent Access Patterns

### Claude Desktop (via MCP)
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "from_vault_or_env"
      }
    },
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": {
        "SUPABASE_PROJECT_REF": "spdtwktxdalcfigzeqrz",
        "SUPABASE_SERVICE_ROLE_KEY": "from_vault_or_env"
      }
    }
  }
}
```

### ChatGPT Plugin (via Edge Function)
```typescript
// Edge Function: supabase/functions/chatgpt-plugin/index.ts
import { getSecrets } from './vault-client.ts'

// Load all platform credentials
const secrets = await getSecrets([
  'github_token',
  'do_access_token',
  'openai_api_key',
  'vercel_token'
])

// Use in API calls
const githubResponse = await fetch('https://api.github.com/user/repos', {
  headers: { 'Authorization': `Bearer ${secrets.github_token}` }
})
```

---

## Recommended Integration Workflow

### 1. Store API Keys in Vault
```bash
# Via Supabase Dashboard
https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/vault

# Or via SQL (requires proper permissions)
SELECT public.store_secret('github_token', 'ghp_...', 'GitHub PAT');
SELECT public.store_secret('do_access_token', 'dop_...', 'DigitalOcean token');
SELECT public.store_secret('openai_api_key', 'sk-...', 'OpenAI API key');
```

### 2. Access from Edge Functions
```typescript
import { getSecret } from './vault-client.ts'

// Get secret with automatic caching and fallback
const apiKey = await getSecret('platform_api_key')
```

### 3. Use in AI Agent Workflows
```typescript
// Example: Trigger GitHub Actions deployment via API
const githubToken = await getSecret('github_token')

await fetch('https://api.github.com/repos/owner/repo/actions/workflows/deploy.yml/dispatches', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${githubToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    ref: 'main',
    inputs: { environment: 'production' }
  })
})
```

---

## Security Best Practices

1. **Vault-First**: Store all API keys in Supabase Vault (encrypted at rest)
2. **Service Role Only**: Only service_role can access secrets
3. **Audit Everything**: All access logged to `secret_access_log`
4. **Rotation Schedule**: Rotate keys every 90 days
5. **Least Privilege**: Use read-only tokens where possible
6. **No Hardcoding**: Never commit API keys to git

---

## Next Steps

1. ✅ Supabase Vault setup complete
2. ✅ Edge Function deployed with secret management
3. ✅ GitHub API accessible via MCP
4. ⏳ Add DigitalOcean API wrapper to Edge Function
5. ⏳ Add Vercel API wrapper to Edge Function
6. ⏳ Add OpenAI API proxy (with usage tracking)
7. ⏳ Create unified AI Agent API gateway

All platforms are now accessible via their respective management APIs with secrets managed through Supabase Vault.
