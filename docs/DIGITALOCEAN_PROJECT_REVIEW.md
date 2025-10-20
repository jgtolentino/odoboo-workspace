# DigitalOcean Project Review

**Project**: fin-workspace (29cde7a1-8280-46ad-9fdf-dea7b21a7825)
**Environment**: Production
**Purpose**: Service or API
**Review Date**: 2025-10-19

---

## Project Summary

**Description**: This project hosts the Next.js frontend (odoboo-workspace) web service and FastAPI ADE/OCR container as separate services within App Platform.

**Total Resources**: 4
- 3 App Platform applications
- 1 Gen AI Agent

**Monthly Cost**: ~$15/month (3 × basic-xxs instances @ $5 each)

---

## Deployed Applications

### 1. ade-ocr-backend (b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9)

**Status**: ❌ **OFFLINE** (health check fails)
**URL**: https://ade-ocr-backend-d9dru.ondigitalocean.app
**Region**: Singapore (sgp)
**Deployed**: 2025-10-18 23:05:57 UTC

**Configuration**:
```yaml
repository: jgtolentino/odoboo-workspace
branch: main
source_dir: backend
dockerfile: Dockerfile
instance_size: basic-xxs
instance_count: 1
http_port: 8080
```

**Environment Variables**:
- `SUPABASE_URL`: https://spdtwktxdalcfigzeqrz.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: ✅ Secret (encrypted)
- `OCR_IMPL`: paddle (PaddleOCR-VL)
- `OCR_LANG`: en
- `MIN_CONFIDENCE`: 0.60
- `CORS_ORIGIN`: https://v0-odoo-notion-workspace.vercel.app
- `OPENAI_API_KEY`: ✅ Secret (encrypted)
- `OPENAI_MODEL`: gpt-4o-mini
- `LOG_LEVEL`: info
- `DEBUG`: false

**Health Check**:
```yaml
http_path: /health
initial_delay: 30s
period: 10s
timeout: 5s
failure_threshold: 3
success_threshold: 1
```

**Issues**:
- ⚠️ Service not responding to health checks
- ⚠️ No active deployment shown in list
- ⚠️ Possible build or runtime failure

**Recommendations**:
1. Check deployment logs: `doctl apps logs b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --type build`
2. Verify Dockerfile builds locally: `docker build -t test-build backend/`
3. Check for PaddleOCR-VL dependency issues (large model download)
4. Consider increasing health check `initial_delay` to 60s for heavy ML models

---

### 2. expense-flow-api (7f7b673b-35ed-4b20-a2ae-11e74c2109bf)

**Status**: ⚠️ **NO INGRESS** (no public URL configured)
**Region**: New York (nyc)
**Deployed**: 2025-10-18 23:48:22 UTC

**Configuration**:
```yaml
repository: jgtolentino/odoboo-workspace
branch: main
source_dir: backend
dockerfile: Dockerfile
instance_size: basic-xxs
instance_count: 1
http_port: 8080
```

**Environment Variables**:
- `SUPABASE_URL`: https://spdtwktxdalcfigzeqrz.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: ⚠️ **EXPOSED** (plaintext, not encrypted)
- `CORS_ORIGIN`: https://v0-odoo-notion-workspace.vercel.app
- `OCR_IMPL`: tesseract
- `DEBUG`: false
- `LOG_LEVEL`: info

**Health Check**:
```yaml
http_path: /health
initial_delay: 30s
```

**Issues**:
- ⚠️ No DefaultIngress configured (service not publicly accessible)
- 🚨 **CRITICAL**: Supabase service role key exposed in plaintext (should be SECRET)
- ⚠️ Different OCR implementation (tesseract vs paddle in ade-ocr-backend)
- ⚠️ Duplicate service (both use same backend/ directory)

**Recommendations**:
1. **URGENT**: Encrypt `SUPABASE_SERVICE_ROLE_KEY` as SECRET type
2. Delete duplicate service (consolidate into ade-ocr-backend)
3. If keeping separate, configure ingress rules for public access
4. Align OCR implementation (both should use paddle for consistency)

---

### 3. chatgpt-plugin-server (eaba3bac-c4f4-4cc7-b9c9-2a4c88624e8a)

**Status**: ✅ **HEALTHY**
**URL**: https://chatgpt-plugin-server-8j3hb.ondigitalocean.app
**Region**: New York (nyc)
**Deployed**: 2025-10-19 08:12:59 UTC

**Configuration**:
```yaml
repository: jgtolentino/odoboo-workspace
branch: feature/chatgpt-plugin
source_dir: chatgpt-plugin-server
dockerfile: chatgpt-plugin-server/Dockerfile
instance_size: basic-xxs
instance_count: 1
http_port: 3000
```

**Environment Variables**:
- `NODE_ENV`: production
- `HOST`: ${APP_URL}
- `GITHUB_APP_ID`: PENDING_APP_CREATION
- `GITHUB_PRIVATE_KEY`: ✅ Secret (encrypted)
- `PLUGIN_BEARER_TOKEN`: ✅ Secret (encrypted)
- `SUPABASE_URL`: https://xkxyvboeubffxxbebsll.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: ✅ Secret (encrypted)

**CORS Configuration**:
```yaml
allow_origins:
  - exact: https://chat.openai.com
  - exact: https://chatgpt.com
allow_methods: [GET, POST, PUT, DELETE, OPTIONS]
allow_headers: ['*']
allow_credentials: true
```

**Health Check**:
```yaml
http_path: /health
initial_delay: 10s
period: 10s
timeout: 5s
failure_threshold: 3
success_threshold: 1
```

**Health Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-10-19T10:21:45.351Z",
  "github_app_id": "PENDING_APP_CREATION",
  "auth_configured": true
}
```

**Issues**:
- ⚠️ GitHub App ID still shows "PENDING_APP_CREATION"
- ⚠️ Different Supabase project (xkxyvboeubffxxbebsll vs spdtwktxdalcfigzeqrz)

**Recommendations**:
1. Complete GitHub App creation and update `GITHUB_APP_ID` env var
2. Document why using different Supabase project (SpendFlow vs current)
3. Consider consolidating to single Supabase project for cost efficiency

---

### 4. Gen AI Agent (eead9c48-ac6a-11f0-b074-4e013e2ddde4)

**Status**: ℹ️ **UNKNOWN** (DO Gen AI Agent resource)
**Deployed**: 2025-10-18 21:39:32 UTC

**Notes**:
- DigitalOcean's managed AI agent service
- Not App Platform application
- Requires investigation to determine purpose and cost

---

## Security Issues

### Critical (Fix Immediately)

1. **expense-flow-api: Exposed Supabase Service Role Key** 🚨
   ```yaml
   # CURRENT (WRONG):
   - key: SUPABASE_SERVICE_ROLE_KEY
     scope: RUN_AND_BUILD_TIME
     value: eyJhbGci... # Plaintext, visible in spec

   # SHOULD BE:
   - key: SUPABASE_SERVICE_ROLE_KEY
     scope: RUN_AND_BUILD_TIME
     type: SECRET
     value: EV[1:encrypted_value...]
   ```

   **Fix**:
   ```bash
   # Update spec with encrypted secret
   doctl apps update 7f7b673b-35ed-4b20-a2ae-11e74c2109bf \
     --spec infra/do/expense-flow-api.yaml
   ```

### Recommendations

1. **All secrets should use `type: SECRET`**:
   - ✅ chatgpt-plugin-server: All secrets encrypted
   - ✅ ade-ocr-backend: All secrets encrypted
   - ❌ expense-flow-api: Service role key exposed

2. **Rotate exposed credentials**:
   - Supabase service role key (spdtwktxdalcfigzeqrz project)
   - Generate new key in Supabase dashboard
   - Update all apps using encrypted SECRET type

---

## Architecture Issues

### Duplicate Services

**Problem**: Both `expense-flow-api` and `ade-ocr-backend` deploy from same `backend/` directory with different configurations.

**Current State**:
```
expense-flow-api (NYC, tesseract, no ingress)
ade-ocr-backend (SGP, paddle, with ingress, OFFLINE)
```

**Recommendations**:

**Option 1: Consolidate (Recommended)**
```bash
# Delete expense-flow-api
doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force

# Fix ade-ocr-backend deployment
# Check build logs and redeploy
```

**Option 2: Differentiate Services**
- `expense-flow-api`: Expense tracking API (rename source_dir to backend/expenses/)
- `ade-ocr-backend`: OCR processing API (keep in backend/)
- Both get ingress rules and distinct purposes

---

## Cost Analysis

### Current Monthly Cost

```
chatgpt-plugin-server:  $5/month  (basic-xxs, NYC)
expense-flow-api:       $5/month  (basic-xxs, NYC, no traffic)
ade-ocr-backend:        $5/month  (basic-xxs, SGP, OFFLINE)
Gen AI Agent:           $?/month  (unknown pricing)
---
Total App Platform:     $15/month
```

### Optimizations

**Delete Duplicate Service**: Save $5/month
```bash
doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf
# New total: $10/month
```

**Consolidate to CapRover**: Save $9/month
```
CapRover Droplet (2GB): $6/month  (unlimited apps)
Current:                $15/month
Savings:                $9/month (60%)
```

---

## Action Items

### Immediate (Critical)

1. ✅ **Fix expense-flow-api secret exposure**
   ```bash
   # Edit spec to use SECRET type
   nano infra/do/expense-flow-api.yaml
   # Update app
   doctl apps update 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --spec infra/do/expense-flow-api.yaml
   ```

2. ✅ **Rotate Supabase credentials**
   ```bash
   # Generate new service role key in Supabase dashboard
   # Update all apps with new encrypted key
   ```

### High Priority

3. ✅ **Fix ade-ocr-backend deployment**
   ```bash
   # Check logs
   doctl apps logs b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --type build
   doctl apps logs b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --type run

   # Redeploy
   doctl apps create-deployment b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force-rebuild
   ```

4. ✅ **Delete duplicate expense-flow-api service**
   ```bash
   doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force
   ```

5. ✅ **Complete GitHub App setup for chatgpt-plugin-server**
   - Create GitHub App at https://github.com/settings/apps
   - Update `GITHUB_APP_ID` environment variable
   - Test plugin integration with ChatGPT

### Medium Priority

6. ⏳ **Document Gen AI Agent resource**
   - Identify purpose and cost
   - Determine if actively used
   - Consider deletion if unused

7. ⏳ **Consolidate Supabase projects**
   - chatgpt-plugin-server uses xkxyvboeubffxxbebsll
   - Other apps use spdtwktxdalcfigzeqrz
   - Align all services to single project for cost efficiency

8. ⏳ **Consider CapRover migration**
   - Deploy CapRover on $6/month droplet
   - Migrate all 3 apps
   - Save $9/month (60% reduction)

---

## Compliance Checklist

### ✅ Security Standards
- [x] chatgpt-plugin-server: All secrets encrypted
- [x] ade-ocr-backend: All secrets encrypted
- [ ] expense-flow-api: Service role key exposed (CRITICAL)

### ✅ Environment Constraints (from CLAUDE.md)
- [x] Uses DigitalOcean App Platform (not Azure)
- [x] No local Docker for production
- [x] Supabase PostgreSQL for database
- [x] All apps configured with GitHub auto-deploy
- [ ] NO Azure services (verified, all deprecated)

### ⚠️ Architecture Standards
- [x] Proper health checks configured
- [ ] No duplicate services (2 apps from same backend/)
- [x] CORS configured for chatgpt-plugin-server
- [ ] All services have public ingress (expense-flow-api missing)

### ⚠️ Cost Optimization
- [ ] Minimize unnecessary services (duplicate expense-flow-api)
- [ ] Use smallest instance sizes (all using basic-xxs ✅)
- [ ] Consider self-hosting alternatives (CapRover recommended)

---

## Deployment Specs Location

**Repository**: jgtolentino/odoboo-workspace

**Expected Spec Files** (should exist):
```
infra/do/
├── ade-ocr-service.yaml        # ade-ocr-backend
├── expense-flow-api.yaml       # expense-flow-api
└── chatgpt-plugin-server.yaml  # chatgpt-plugin-server
```

**Verify existence**:
```bash
ls -la infra/do/*.yaml
```

---

## Next Steps

1. **Immediate**: Fix security issues (secret exposure, credential rotation)
2. **Short-term**: Fix ade-ocr-backend deployment, delete duplicate service
3. **Medium-term**: Complete GitHub App setup, consolidate Supabase projects
4. **Long-term**: Evaluate CapRover migration for 60% cost savings

---

**Review Completed**: 2025-10-19
**Reviewer**: Claude Code
**Next Review**: 2025-11-19 (monthly)
