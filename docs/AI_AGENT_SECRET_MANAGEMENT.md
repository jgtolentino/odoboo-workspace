# AI Agent Secret Management

**Comprehensive secret management architecture for AI-driven development workflows**

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│           AI Agents (Claude & ChatGPT)              │
│  ┌─────────────────┐     ┌────────────────────────┐ │
│  │ Claude Desktop  │     │   ChatGPT Plugin       │ │
│  │    (MCP)        │     │  (Edge Function)       │ │
│  └────────┬────────┘     └───────────┬────────────┘ │
└───────────│──────────────────────────│──────────────┘
            │                          │
            ▼                          ▼
┌───────────────────────────────────────────────────────┐
│              Supabase Secret Management               │
│  ┌──────────────────┐      ┌────────────────────────┐│
│  │  Supabase Vault  │◄────►│  Edge Function Secrets ││
│  │  (Database-level)│      │  (Runtime Environment) ││
│  └──────────────────┘      └────────────────────────┘│
│           ▲                          ▲                │
│           └──────────┬───────────────┘                │
│                      │                                │
│         ┌────────────▼───────────┐                    │
│         │   vault_client.ts      │                    │
│         │  - Caching             │                    │
│         │  - Fallback            │                    │
│         │  - Audit Logging       │                    │
│         └────────────────────────┘                    │
└───────────────────────────────────────────────────────┘
```

## Secret Storage Locations

### 1. Supabase Vault (Primary)
**Purpose**: Database-level encrypted secret storage

**Features**:
- End-to-end encryption
- Access via service_role only
- Audit logging built-in
- Secret rotation support

**Access Pattern**:
```typescript
// Via Edge Function
import { getSecret } from './vault-client.ts'

const githubToken = await getSecret('github_token')
```

**SQL Functions**:
```sql
-- Store secret
SELECT public.store_secret('github_token', 'ghp_...', 'GitHub PAT');

-- Retrieve secret
SELECT public.get_secret('github_token');

-- Rotate secret
SELECT public.rotate_secret('github_token', 'ghp_new_value');

-- List secrets
SELECT * FROM public.list_secret_names();
```

### 2. Supabase Edge Function Secrets (Secondary)
**Purpose**: Runtime environment variables for Edge Functions

**Features**:
- Fast access (no database query)
- Encrypted at rest
- Deployed with function

**Access Pattern**:
```typescript
const token = Deno.env.get('GITHUB_TOKEN')
```

**Management**:
```bash
# Set secret
supabase secrets set GITHUB_TOKEN=ghp_... --project-ref spdtwktxdalcfigzeqrz

# List secrets
supabase secrets list --project-ref spdtwktxdalcfigzeqrz

# Remove secret
supabase secrets unset GITHUB_TOKEN --project-ref spdtwktxdalcfigzeqrz
```

### 3. Environment Variables (Fallback)
**Purpose**: Local development and backward compatibility

**Location**: `~/.zshrc`

**Usage**: Only during development, not in production

## AI Agent Access Patterns

### Claude Desktop (MCP)

**Configuration**: `/Users/tbwa/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": {
        "SUPABASE_PROJECT_REF": "spdtwktxdalcfigzeqrz",
        "SUPABASE_SERVICE_ROLE_KEY": "${SUPABASE_SERVICE_ROLE_KEY}"
      }
    }
  }
}
```

**Secret Access**: Direct via environment variables (MCP servers read from env)

**Security**: Secrets never leave local machine, used only by MCP servers

### ChatGPT Plugin (Edge Function)

**Configuration**: `supabase/functions/chatgpt-plugin/index.ts`

**Secret Access**: Multi-tier fallback
1. **Primary**: Supabase Vault via `vault-client.ts`
2. **Fallback**: Edge Function secrets (env vars)
3. **Cache**: In-memory cache (5min TTL)

**Initialization**:
```typescript
// Lazy-loaded on first request
if (!GITHUB_TOKEN) {
  await initializeSecrets() // Loads from Vault
}
```

**Security**: Bearer token authentication + CORS restrictions

## Secret Lifecycle

### 1. Creation

**Manual Creation**:
```bash
# Via migration script
./scripts/migrate-secrets-to-vault.sh

# Via SQL
psql "$POSTGRES_URL" <<EOF
SELECT public.store_secret(
  'new_secret',
  'secret_value',
  'Description of secret'
);
EOF
```

**Automated Creation** (via CI/CD):
```yaml
# .github/workflows/deploy.yml
- name: Store secret in Vault
  run: |
    psql "$POSTGRES_URL" -c "SELECT public.store_secret('${{ secrets.SECRET_NAME }}', '${{ secrets.SECRET_VALUE }}', 'Auto-created by CI');"
```

### 2. Access

**Edge Function Access**:
```typescript
import { getSecret, getSecrets } from './vault-client.ts'

// Single secret
const token = await getSecret('github_token')

// Multiple secrets (parallel)
const secrets = await getSecrets(['github_token', 'openai_api_key'])
```

**Direct SQL Access** (service_role only):
```sql
-- Service role JWT required
SELECT decrypted_secret
FROM vault.decrypted_secrets
WHERE name = 'github_token';
```

### 3. Rotation

**Manual Rotation**:
```bash
# Generate new token externally
# Then rotate in Vault
psql "$POSTGRES_URL" <<EOF
SELECT public.rotate_secret('github_token', 'ghp_new_token_here');
EOF

# Update Edge Function secrets
supabase secrets set GITHUB_TOKEN=ghp_new_token_here --project-ref spdtwktxdalcfigzeqrz

# Restart Edge Function
supabase functions deploy chatgpt-plugin --project-ref spdtwktxdalcfigzeqrz
```

**Automated Rotation** (future enhancement):
```typescript
// Scheduled Edge Function (runs daily)
async function checkAndRotateSecrets() {
  const expiringSecrets = await vault.checkExpiringSecrets(7) // 7 days threshold

  for (const secret of expiringSecrets) {
    // Send notification
    await sendRotationReminder(secret)
  }
}
```

### 4. Audit

**View Access Logs**:
```sql
-- Recent secret access
SELECT
  secret_name,
  accessed_by,
  access_type,
  success,
  error_message,
  created_at
FROM public.secret_access_log
ORDER BY created_at DESC
LIMIT 100;

-- Failed access attempts
SELECT *
FROM public.secret_access_log
WHERE success = FALSE
ORDER BY created_at DESC;

-- Access by secret
SELECT *
FROM public.secret_access_log
WHERE secret_name = 'github_token'
ORDER BY created_at DESC;
```

**Export Audit Log**:
```bash
psql "$POSTGRES_URL" -c "COPY (SELECT * FROM public.secret_access_log WHERE created_at > NOW() - INTERVAL '30 days') TO STDOUT WITH CSV HEADER" > audit-log.csv
```

## Security Best Practices

### 1. Access Control

**Principle of Least Privilege**:
- Use `anon` key for public frontend operations
- Use `service_role` key only in backend services
- Never expose `service_role` key to frontend

**RLS Policies**:
```sql
-- Example: Only service_role can access secrets
CREATE POLICY "service_role_only" ON vault.secrets
  FOR ALL
  TO service_role
  USING (TRUE);
```

### 2. Secret Rotation

**Rotation Schedule**:
| Secret Type | Frequency | Priority |
|-------------|-----------|----------|
| GitHub Tokens | 90 days | High |
| API Keys | 90 days | High |
| Service Keys | 180 days | Medium |
| Signing Keys | Manual | Critical |

**Rotation Process**:
1. Generate new secret value
2. Update Vault: `public.rotate_secret()`
3. Update Edge Function secrets
4. Redeploy affected services
5. Verify functionality
6. Revoke old secret

### 3. Monitoring

**Alerts to Set Up**:
- Failed authentication attempts (>5 in 1 hour)
- Secret access from unexpected sources
- Secrets approaching expiration
- Unusual access patterns

**Metrics to Track**:
- Secret access frequency
- Failed access rate
- Time since last rotation
- Number of services using each secret

### 4. Incident Response

**If Secret is Compromised**:

```bash
# 1. IMMEDIATE: Rotate in Vault
psql "$POSTGRES_URL" -c "SELECT public.rotate_secret('compromised_secret', 'emergency_replacement');"

# 2. Update Edge Function secrets
supabase secrets set COMPROMISED_SECRET=emergency_replacement

# 3. Redeploy all affected services
supabase functions deploy chatgpt-plugin --project-ref spdtwktxdalcfigzeqrz

# 4. Revoke old secret at provider
# (e.g., delete GitHub token, revoke API key)

# 5. Audit access logs
psql "$POSTGRES_URL" -c "SELECT * FROM public.secret_access_log WHERE secret_name = 'compromised_secret' ORDER BY created_at DESC LIMIT 100;"

# 6. Notify security team
# (send alert via Slack/email)
```

## AI Agent Workflows

### Workflow 1: GitHub Operations

**Secrets Required**: `github_token`

**Claude Desktop** (via MCP):
```typescript
// MCP GitHub server automatically uses GITHUB_PERSONAL_ACCESS_TOKEN
// Claude can perform: create repo, commit, PR, issues
```

**ChatGPT Plugin** (via Edge Function):
```typescript
// Edge Function loads github_token from Vault
const octokit = getOctokit() // Uses Vault-backed token
await octokit.rest.repos.createOrUpdateFileContents(...)
```

### Workflow 2: Database Operations

**Secrets Required**: `supabase_service_role_key`

**Claude Desktop** (via MCP):
```json
{
  "supabase": {
    "env": {
      "SUPABASE_SERVICE_ROLE_KEY": "${SUPABASE_SERVICE_ROLE_KEY}"
    }
  }
}
```

**Direct Access** (via psql):
```bash
export POSTGRES_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:${SUPABASE_DB_PASSWORD}@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
psql "$POSTGRES_URL"
```

### Workflow 3: Multi-Service Deployments

**Secrets Required**:
- `github_token` (code deployment)
- `do_access_token` (infrastructure)
- `supabase_access_token` (database migrations)

**Orchestration**:
```bash
# 1. Load secrets from Vault
GITHUB_TOKEN=$(psql "$POSTGRES_URL" -t -c "SELECT public.get_secret('github_token');")
DO_TOKEN=$(psql "$POSTGRES_URL" -t -c "SELECT public.get_secret('do_access_token');")

# 2. Deploy code
git push origin main

# 3. Deploy infrastructure
doctl apps create-deployment $APP_ID

# 4. Run migrations
supabase db push
```

## Caching Strategy

**vault-client.ts Caching**:
```typescript
interface SecretCache {
  value: string        // Decrypted secret
  cachedAt: number     // Timestamp
  ttl: number          // Time to live (5min default)
}
```

**Cache Behavior**:
- **Cache Hit**: Return immediately (no Vault query)
- **Cache Miss**: Fetch from Vault, cache result
- **Cache Expiry**: TTL = 5 minutes (configurable)
- **Cache Clear**: Manual via `clearSecretCache()`

**Benefits**:
- Reduced database queries
- Faster secret access
- Lower latency for Edge Functions

**Trade-offs**:
- Stale secrets (max 5min delay after rotation)
- Memory usage (minimal, ~100 bytes per secret)

## Migration Guide

### From Environment Variables to Vault

**Step 1: Run Migration Script**
```bash
chmod +x scripts/migrate-secrets-to-vault.sh
./scripts/migrate-secrets-to-vault.sh
```

**Step 2: Apply Database Migration**
```bash
supabase db push
```

**Step 3: Redeploy Edge Functions**
```bash
supabase functions deploy chatgpt-plugin --project-ref spdtwktxdalcfigzeqrz
```

**Step 4: Test Secret Access**
```bash
# Test health endpoint (should show "secret_source": "vault")
curl https://spdtwktxdalcfigzeqrz.supabase.co/functions/v1/chatgpt-plugin/health
```

**Step 5: Remove Secrets from ~/.zshrc** (optional)
```bash
# Backup first
cp ~/.zshrc ~/.zshrc.backup

# Remove secret lines (keep only exports for local development)
# Edit ~/.zshrc manually or use sed
```

## Troubleshooting

### Issue: "Secret not found"

**Cause**: Secret doesn't exist in Vault

**Solution**:
```sql
-- Check if secret exists
SELECT * FROM vault.secrets WHERE name = 'your_secret_name';

-- If missing, create it
SELECT public.store_secret('your_secret_name', 'value', 'description');
```

### Issue: "Access denied"

**Cause**: Attempting to access Vault without service_role

**Solution**: Ensure Edge Function uses service_role key in Supabase client

### Issue: Stale cached secrets

**Cause**: Secret rotated but cache still holds old value

**Solution**:
```typescript
// Clear cache manually
import { clearSecretCache } from './vault-client.ts'
clearSecretCache('secret_name') // Or clearSecretCache() for all

// Or wait 5 minutes for automatic expiry
```

### Issue: Performance degradation

**Cause**: Too many Vault queries

**Solution**:
- Increase cache TTL (default 5min)
- Preload secrets at Edge Function startup
- Use `getSecrets()` for batch fetching

## Future Enhancements

### 1. Automated Rotation
- Scheduled Edge Function to check expiring secrets
- Auto-generate new tokens via provider APIs
- Graceful rollover (dual-token period)

### 2. Multi-Region Replication
- Replicate secrets across Supabase regions
- Reduce latency for global deployments
- Disaster recovery

### 3. Integration with External Vaults
- AWS Secrets Manager
- HashiCorp Vault
- Azure Key Vault

### 4. Advanced Audit Analytics
- Secret usage patterns
- Anomaly detection
- Compliance reporting

## References

- [Supabase Vault Documentation](https://supabase.com/docs/guides/database/vault)
- [Edge Function Secrets](https://supabase.com/docs/guides/functions/secrets)
- [GitHub Token Best Practices](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
