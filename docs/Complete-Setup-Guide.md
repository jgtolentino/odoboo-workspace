# Complete Setup Guide - AI-Assisted Development Platform

## Overview

This guide provides complete setup instructions for the Odoo-style platform with AI-assisted development workflow using GitHub, Supabase, and Vercel.

## Architecture Summary

### Core Components

- **Frontend**: Next.js App Router with TypeScript and Tailwind
- **Backend**: Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI Workflow**: GitHub Issues → Edge Functions → Cline Worker
- **Deployment**: Vercel (web) + Supabase (database/functions)

### Data Flow

1. GitHub Issue with `ai-task` label created
2. GitHub Actions enqueues task via Edge Function
3. Cline Worker claims task and executes
4. Progress posted via Edge Function comments
5. Task completion triggers webhook notifications

## Prerequisites

### Required Tools

- Node.js ≥ 20
- pnpm package manager
- Supabase CLI
- GitHub CLI (optional)
- SSH client (built into most systems)

### Required Accounts

- GitHub account with repository access
- Supabase account with project
- Vercel account for deployment

## Step-by-Step Setup

### 1. Repository Setup

```bash
# Clone the repository
git clone https://github.com/jgtolentino/v0-odoo-notion-workspace.git
cd v0-odoo-notion-workspace

# Install dependencies
pnpm install

# Start development server
pnpm dev
```

### 2. Environment Configuration

#### Local Development (.env.local)

```bash
# Copy from provided environment variables
# Update placeholder values with actual tokens
```

#### GitHub Repository Secrets

Add these secrets in GitHub repository settings:

- `SUPABASE_ACCESS_TOKEN` - From `supabase login`
- `SUPABASE_PROJECT_REF` - Your Supabase project ID
- `GH_TOKEN` - GitHub personal access token
- `WQ_WEBHOOK_SECRET` - Random secret (generate with `openssl rand -hex 32`)

#### Vercel Environment Variables

Deploy the same environment variables from `.env.local` to Vercel.

### 3. Supabase Setup

#### Deploy Edge Function

```bash
# Login to Supabase
supabase login

# Deploy work-queue function
supabase functions deploy work-queue

# Set secrets
supabase secrets set SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY
```

#### Database Setup

Ensure these tables exist in your Supabase project:

- `work_queue` - Task management
- `work_queue_comment` - Task progress tracking
- `app_*` tables - Application catalog
- `knowledge_*` tables - Knowledge management
- `project_*` tables - Project management

### 4. GitHub App Configuration

#### Required Permissions

- **Repository**: Contents (Read & Write)
- **Repository**: Issues (Read & Write)
- **Repository**: Pull requests (Read & Write)
- **Repository**: Metadata (Read-only)

#### Webhook Setup (Optional)

Configure GitHub webhook to call `/api/hooks/task-comment` for real-time notifications.

### 4.1 SSH Setup for Git Operations

#### Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "you@email" -f ~/.ssh/id_ed25519
```

#### Add to SSH Agent (macOS)

```bash
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

#### Add Public Key to GitHub

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-dev"
```

#### Switch Repository to SSH

```bash
git remote set-url origin git@github.com:jgtolentino/v0-odoo-notion-workspace.git
```

#### Test SSH Connection

```bash
ssh -T git@github.com
```

**Note**: ChatGPT uses OAuth authentication, not SSH. SSH is for local/Cline/server operations.

See `docs/SSH-Setup.md` for complete SSH configuration details.

### 5. Testing the Workflow

#### Create Test Task

1. Create GitHub issue with `ai-task` label
2. Include task details in the issue body
3. Watch GitHub Actions workflow trigger

#### Verify Task Processing

1. Check `work_queue` table for new task
2. Run worker script: `node scripts/worker.mjs`
3. Verify task file created in `.cline/tasks/`
4. Check progress comments in task thread

#### Test Edge Functions

```bash
# Test enqueue
curl -X POST https://$SUPABASE_PROJECT_REF.functions.supabase.co/work-queue/enqueue \
  -H "Content-Type: application/json" \
  -d '{"kind":"test","prompt":{"goal":"test","acceptance":[],"files":[],"guards":[],"verify":[]}}'

# Test claim
curl -X POST https://$SUPABASE_PROJECT_REF.functions.supabase.co/work-queue/claim \
  -H "Content-Type: application/json" \
  -d '{"worker":"cline"}'
```

## Quality Gates

### Development Checks

```bash
# Lint code
pnpm lint

# Run tests
pnpm test

# Build project
pnpm build

# Type check (if configured)
pnpm typecheck
```

### Production Readiness

- [ ] All environment variables set
- [ ] Edge Functions deployed
- [ ] GitHub secrets configured
- [ ] Database migrations applied
- [ ] Build passes without errors
- [ ] Basic workflow tested

## Troubleshooting

### Common Issues

#### Edge Function Errors

- Verify `SUPABASE_ACCESS_TOKEN` is valid
- Check function logs in Supabase dashboard
- Test endpoints directly with curl

#### GitHub Actions Failures

- Verify secret names match exactly
- Check workflow file syntax
- Ensure GitHub App has required permissions

#### Database Connection Issues

- Verify environment variables
- Check RLS policies
- Test connection with test script

#### Worker Script Issues

- Verify Edge Function URLs
- Check task file creation permissions
- Test individual API calls

### Debug Steps

1. Check GitHub Actions logs
2. Verify Supabase function logs
3. Test API endpoints directly
4. Check browser console for frontend errors
5. Verify environment variables match

## Maintenance

### Regular Tasks

- Update dependencies regularly
- Monitor Edge Function performance
- Review GitHub Actions workflows
- Backup database regularly
- Monitor error logs

### Scaling Considerations

- Monitor Supabase usage limits
- Consider queue management for high volume
- Implement rate limiting if needed
- Set up monitoring and alerts

## Support

### Documentation

- `docs/PRD.md` - Product requirements
- `docs/AI-Workflow.md` - AI development workflow
- `docs/GitHub-Integration.md` - GitHub setup
- `docs/DB-Guidelines.md` - Database best practices

### Getting Help

- Check existing documentation first
- Review error logs and console output
- Test individual components
- Consult the development team

This completes the setup of your AI-assisted development platform. The system is now ready for production use with GitHub-driven task automation and real-time progress tracking.
