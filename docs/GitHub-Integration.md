# GitHub Integration Setup

## Required Secrets

Add these secrets to your GitHub repository settings:

### Repository Secrets (GitHub Actions)

- `SUPABASE_ACCESS_TOKEN` - Supabase CLI access token for deployments
- `SUPABASE_PROJECT_REF` - Your Supabase project reference ID
- `GH_TOKEN` - GitHub token with repo permissions
- `WQ_WEBHOOK_SECRET` - Random secret for webhook authentication

### Environment Variables (Vercel/App)

- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (server only)
- `WQ_WEBHOOK_SECRET` - Same as GitHub secret

## Branch Configuration

- **Default Branch**: `main` (production)
- **Staging Branch**: `staging` (pre-production)
- **Development**: `develop` or feature branches

## GitHub App Permissions

Ensure your GitHub App has these permissions:

### Repository Permissions

- **Contents**: Read & Write
- **Issues**: Read & Write
- **Pull requests**: Read & Write
- **Metadata**: Read-only

### Organization Permissions (if applicable)

- **Members**: Read-only
- **Projects**: Read-only

## Workflow Triggers

### AI Task Automation

1. **Issue Creation**: Create issue with `ai-task` label
2. **Auto-enqueue**: GitHub Actions workflow triggers
3. **Task Processing**: Cline claims and executes task
4. **Progress Updates**: Posted via Edge Function comments
5. **Completion**: Task marked as done, PR created if needed

### Branch Protection Rules

- **main**: Require PR reviews, status checks
- **staging**: Require status checks
- **develop**: No restrictions for rapid development

## Secret Generation

### GitHub Token

```bash
# Create fine-grained personal access token
gh auth login
# Or create classic token with repo scope
```

### Supabase Access Token

```bash
# Install Supabase CLI
npm install -g supabase

# Login and get token
supabase login
```

### Webhook Secret

```bash
# Generate random secret
openssl rand -hex 32
```

## Testing the Integration

1. **Create test issue** with `ai-task` label
2. **Verify workflow** runs in GitHub Actions
3. **Check work_queue** table for new task
4. **Run worker** to claim and process task
5. **Verify comments** appear in task thread

## Troubleshooting

### Common Issues

- **Missing permissions**: Check GitHub App scopes
- **Secret not found**: Verify secret names in workflows
- **Webhook failures**: Check WQ_WEBHOOK_SECRET match
- **Edge Function errors**: Verify SUPABASE_ACCESS_TOKEN

### Debug Steps

1. Check GitHub Actions logs
2. Verify environment variables
3. Test Edge Function endpoints directly
4. Check Supabase logs for RPC calls
