# DigitalOcean Resource Optimization Plan

**Project**: odoboo-workspace
**Current Monthly Cost**: $15/month
**Current Customer Count**: 0
**Review Date**: 2025-10-19

---

## 🎯 Executive Summary

**Problem**: Spending $15/month on 3 App Platform services with ZERO customers:
- ✅ 1 working service (chatgpt-plugin-server)
- ❌ 2 misconfigured/broken services wasting $10/month

**Opportunity**: Optimize to $5-6/month (67% cost reduction) while maintaining ALL functionality for future customers.

**Strategy**: Fix misconfigured services OR consolidate to single working infrastructure.

---

## 📊 Current Resource Audit

### Deployed Resources

| Service | Status | Cost | Issue | Customer Impact |
|---------|--------|------|-------|----------------|
| **chatgpt-plugin-server** | ✅ HEALTHY | $5/mo | GitHub App ID pending | None (ready for customers) |
| **ade-ocr-backend** | ❌ MISCONFIGURED | $5/mo | Deploys Next.js instead of OCR service | Would fail on first customer |
| **expense-flow-api** | ❌ NO ACCESS | $5/mo | No ingress + exposed secrets | Cannot be used by customers |
| **Total** | **1/3 working** | **$15/mo** | **$10/mo wasted** | **Only 1 service production-ready** |

### Resource Inventory
- **Droplets**: 0 (none)
- **Databases**: 0 (using Supabase free tier)
- **Volumes**: 0 (none)
- **Load Balancers**: 0 (none)
- **App Platform Apps**: 3 ($15/month total)

---

## 🚨 Critical Issues

### 1. ade-ocr-backend: Wrong Service Deployed
**Problem**: Configured to deploy OCR backend but actually deploying Next.js frontend

**Evidence from logs**:
```bash
> my-v0-project@0.1.0 start /workspace
> next start
   ▲ Next.js 15.2.4
   - Local:        http://localhost:8080
 ✓ Ready in 964ms
```

**Expected**: Python FastAPI OCR service with PaddleOCR-VL
**Actual**: Next.js web application

**Root Cause**:
- Spec points to wrong `source_dir` OR
- Dockerfile in `backend/` directory is for Next.js, not OCR service

**Impact**:
- ❌ OCR endpoint `/v1/parse` doesn't exist
- ❌ Health check `/health` fails
- ❌ Service marked OFFLINE
- ❌ $5/month wasted

### 2. expense-flow-api: Security + Access Issues
**Problems**:
1. ❌ No public ingress configured (not accessible)
2. 🚨 **CRITICAL**: Supabase service role key exposed in plaintext
3. ❌ Duplicate of ade-ocr-backend (same `backend/` directory)
4. ❌ Different OCR implementation (tesseract vs paddle)

**Impact**:
- ❌ Cannot be accessed even if it worked
- 🚨 Security vulnerability requiring immediate key rotation
- ❌ $5/month wasted on duplicate service

### 3. chatgpt-plugin-server: Minor Issues
**Problems**:
1. ⚠️ GitHub App ID still shows "PENDING_APP_CREATION"
2. ⚠️ Uses different Supabase project (xkxyvboeubffxxbebsll vs spdtwktxdalcfigzeqrz)

**Impact**:
- ⚠️ Plugin cannot interact with GitHub until App ID configured
- ⚠️ Split across 2 Supabase projects (inefficient)
- ✅ Service is HEALTHY and usable (just needs completion)

---

## ✅ Optimization Options

### Option 1: Fix All Services (Recommended for Multi-Service Architecture)
**Goal**: Make all 3 services work properly for $15/month
**Timeline**: 2-4 hours
**Cost**: Keep at $15/month, get full value

**Actions**:
1. **Fix ade-ocr-backend** (1-2 hours)
   ```bash
   # Step 1: Create proper backend/Dockerfile for OCR service
   # Step 2: Update app spec to use correct source_dir
   # Step 3: Redeploy with force rebuild
   doctl apps create-deployment b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force-rebuild
   ```

2. **Delete expense-flow-api** (5 minutes)
   ```bash
   # Security risk + duplicate service
   doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force
   # Savings: $5/month
   ```

3. **Complete chatgpt-plugin-server** (30 minutes)
   ```bash
   # Create GitHub App at https://github.com/settings/apps
   # Update GITHUB_APP_ID environment variable
   # Test plugin integration
   ```

**Result**:
- ✅ 2 working services (ChatGPT plugin + OCR)
- ✅ $10/month (33% savings from $15)
- ✅ Production-ready for first customers

### Option 2: Consolidate to Minimum (Maximum Cost Savings)
**Goal**: Keep only chatgpt-plugin-server running
**Timeline**: 15 minutes
**Cost**: $5/month (67% savings from $15)

**Actions**:
1. **Delete ade-ocr-backend** (broken, needs major fix)
   ```bash
   doctl apps delete b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force
   ```

2. **Delete expense-flow-api** (security risk + no ingress)
   ```bash
   doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force
   ```

3. **Deploy OCR when you get first customer**
   ```bash
   # Use deployment script from docs/PERCY_LANDING_AI_SELF_HOSTING.md
   # Deploy on droplet for $24-48/month when needed
   ```

**Result**:
- ✅ $5/month (only chatgpt-plugin-server)
- ✅ Zero waste
- ⚠️ Need to deploy OCR when first customer arrives
- ⚠️ Deployment delay when customer ready

### Option 3: Self-Host Everything on Droplet (Long-term Best)
**Goal**: Replace App Platform with single $6/month droplet
**Timeline**: 3-4 hours
**Cost**: $6/month (60% savings from $15)

**Actions**:
1. **Deploy CapRover on $6/month droplet**
   ```bash
   # Create droplet
   doctl compute droplet create caprover \
     --image ubuntu-22-04-x64 \
     --size s-1vcpu-2gb \
     --region sgp1

   # Install CapRover (1-click app manager)
   # Migrate all 3 services to CapRover
   ```

2. **Benefits**:
   - ✅ Unlimited apps on single droplet
   - ✅ $6/month total (vs $15 App Platform)
   - ✅ More control, same functionality
   - ✅ Can add Percy + Landing AI later for free

**Result**:
- ✅ $6/month (60% savings)
- ✅ All 3 services running
- ✅ Room to grow without extra cost
- ⚠️ Requires server management

---

## 💡 Recommendation (No Customers Scenario)

Since you have **ZERO customers** currently, here's my phased approach:

### Phase 1: Immediate (Today)
**Delete broken/risky services to stop wasting money**

```bash
# Delete expense-flow-api (security risk + duplicate)
doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force

# Delete ade-ocr-backend (misconfigured, needs rebuild)
doctl apps delete b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force
```

**Savings**: $10/month → **New cost: $5/month**
**Keep**: chatgpt-plugin-server (only working service)

### Phase 2: When First Customer Arrives
**Deploy OCR service on-demand**

**Option A**: App Platform ($5/month)
- Deploy fixed ade-ocr-backend with proper Python/FastAPI service
- Total: $10/month

**Option B**: Droplet ($24/month for dedicated OCR)
- Use deployment script from `scripts/deploy-percy-landing-ai.sh`
- Better performance for ML workload
- Total: $29/month ($5 App Platform + $24 droplet)

**Option C**: CapRover droplet ($6/month for everything)
- Migrate chatgpt-plugin-server to CapRover
- Deploy OCR service on same droplet
- Add Percy + Landing AI visual testing
- Total: $6/month (unlimited apps)

### Phase 3: Scale with Customers
**As you grow beyond 10-20 customers**
- Monitor resource usage (CPU, memory, latency)
- Scale vertically (bigger droplets) or horizontally (more instances)
- Add managed database if needed (~$15/month)
- Consider CDN for static assets ($5/month)

---

## 📋 Immediate Action Items

### Critical (Do Today)
1. ✅ **Delete expense-flow-api** (security risk + wasted $5/month)
   ```bash
   doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force
   ```

2. ✅ **Delete ade-ocr-backend** (misconfigured + wasted $5/month)
   ```bash
   doctl apps delete b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force
   ```

3. ✅ **Verify chatgpt-plugin-server still works**
   ```bash
   curl -s https://chatgpt-plugin-server-8j3hb.ondigitalocean.app/health | jq
   ```

### High Priority (This Week)
4. ⏳ **Complete GitHub App setup for chatgpt-plugin-server**
   - Create GitHub App at https://github.com/settings/apps
   - Update `GITHUB_APP_ID` environment variable
   - Test plugin with ChatGPT

5. ⏳ **Document OCR deployment options** (for when first customer arrives)
   - App Platform spec (quick deploy)
   - Droplet deployment (better performance)
   - CapRover migration (best value)

### Medium Priority (This Month)
6. ⏳ **Evaluate CapRover migration**
   - Test deployment on $6/month droplet
   - Migrate chatgpt-plugin-server
   - Prepare OCR service for CapRover
   - Save $9/month vs current App Platform

7. ⏳ **Create customer acquisition plan**
   - How will you get first customers?
   - What services do they need immediately?
   - Can you defer OCR deployment until needed?

---

## 💰 Cost Comparison

| Scenario | Monthly Cost | Services | Notes |
|----------|--------------|----------|-------|
| **Current (broken)** | $15 | 3 apps (1 working) | ❌ Wasting $10/month |
| **Optimized (Phase 1)** | $5 | 1 app (working) | ✅ Zero waste, deploy OCR when needed |
| **With OCR (App Platform)** | $10 | 2 apps (both working) | ✅ Ready for customers |
| **With OCR (Droplet)** | $29 | 1 app + 1 droplet | ✅ Better ML performance |
| **CapRover Migration** | $6 | All services | ✅ Best long-term value |
| **Percy + Landing AI (Droplets)** | $84 | Full self-hosted stack | ⚠️ Overkill for 0 customers |

---

## 🎯 Success Metrics

### Cost Efficiency
- **Current**: $15/month with 1/3 services working = **$15 per working service**
- **Phase 1**: $5/month with 1/1 services working = **$5 per working service** (67% improvement)
- **Phase 2**: $10/month with 2/2 services working = **$5 per working service** (maintain efficiency)
- **CapRover**: $6/month unlimited apps = **$2 per service** (87% improvement)

### Service Health
- **Current**: 33% services healthy (1/3)
- **Phase 1**: 100% services healthy (1/1)
- **Phase 2**: 100% services healthy (2/2)

### Customer Readiness
- **Current**: Only ChatGPT plugin ready, OCR broken
- **Phase 1**: ChatGPT plugin ready, OCR deployable on-demand
- **Phase 2**: Both services production-ready

---

## 🚀 Next Steps

**Recommended Path**: Phase 1 Immediate Cost Reduction

1. **Execute deletions** (5 minutes)
   ```bash
   # Delete both broken services
   doctl apps delete 7f7b673b-35ed-4b20-a2ae-11e74c2109bf --force  # expense-flow-api
   doctl apps delete b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9 --force  # ade-ocr-backend
   ```

2. **Verify remaining service** (2 minutes)
   ```bash
   curl https://chatgpt-plugin-server-8j3hb.ondigitalocean.app/health
   ```

3. **Update project documentation** (10 minutes)
   - Document current state ($5/month, 1 service)
   - Plan OCR deployment for first customer
   - Evaluate CapRover for long-term optimization

**Result**: Save $10/month immediately, maintain all working functionality, deploy additional services only when customers arrive.

---

**Review Date**: 2025-10-19
**Next Review**: When first customer signs up OR 2025-11-19 (monthly)
**Optimization Target**: $5-6/month until customer acquisition
