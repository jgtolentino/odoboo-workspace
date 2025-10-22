# Odoo 18 Production Monorepo

Production-ready Odoo 18 deployment with Docker Compose, Traefik TLS, OCA modules, and CI/CD.

## 🏗️ Architecture

```
Browser → Traefik (TLS) → Odoo 18 → PostgreSQL 15
                              ↓
                          Filestore
```

**Stack:**
- **Odoo:** 18.0-20251008
- **PostgreSQL:** 15.14
- **Traefik:** v3.1 (Let's Encrypt)
- **OCA Modules:** Git submodules (pinned commits)

**Domain:** https://insightpulseai.net

## 📁 Repository Structure

```
odoobo/
├── compose.yaml              # Docker Compose orchestration
├── .env                      # Development environment
├── .env.prod                 # Production secrets (not in git)
├── .env.example              # Template for .env.prod
├── Makefile                  # Common operations
├── config/
│   └── odoo/odoo.conf        # Odoo configuration
├── docker/
│   ├── odoo/
│   │   ├── Dockerfile        # Odoo 18 with dependencies
│   │   └── entrypoint.sh     # Startup script
│   └── traefik/
│       └── dynamic.yml       # Traefik routing config
├── addons/
│   ├── custom/               # Your custom modules
│   └── oca/                  # OCA modules (git submodules)
├── scripts/
│   ├── backup.sh             # DB + filestore backup
│   ├── restore.sh            # Full restore
│   ├── set_base_url.sh       # Domain configuration
│   ├── update.sh             # Update deployment
│   ├── bootstrap.sh          # Initial setup
│   └── health_check.sh       # Validation gates
└── .github/workflows/        # CI/CD pipelines
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Git
- SSH access to production server (188.166.237.231)

### Initial Setup

1. **Clone repository:**
```bash
git clone git@github.com:jgtolentino/odoobo.git
cd odoobo
```

2. **Configure production environment:**
```bash
cp .env.example .env.prod
# Edit .env.prod with production values
```

3. **Initialize OCA submodules:**
```bash
git submodule update --init --recursive
```

4. **Bootstrap (first-time setup):**
```bash
make bootstrap
```

5. **Restore production data:**
```bash
make restore DB_DUMP=backup.dump FILESTORE_TAR=filestore.tar.gz
```

6. **Set domain:**
```bash
make set-base-url URL=https://insightpulseai.net
```

7. **Validate:**
```bash
make health
```

## 📚 OCA Modules (Pinned Commits)

OCA modules are tracked as git submodules with specific commit SHAs for reproducibility:

| Module | Repository | Branch | Commit (SHA) |
|--------|-----------|--------|--------------|
| server-tools | OCA/server-tools | 18.0 | `a844903c494af97926314284dd31506ef52cc51a` |
| web | OCA/web | 18.0 | `c9d3aeede1bb9880ec27f2172323feace607f14e` |
| queue | OCA/queue | 18.0 | `edc21e4c4ef11a1ef746ca5ac641e9227602a35d` |
| reporting-engine | OCA/reporting-engine | 18.0 | `0049fa4ac2ff5e9814d5bfc0ac4f245c6a606dc2` |
| account-financial-tools | OCA/account-financial-tools | 18.0 | `adeca0de879bd201a6802570590cac87de4e82aa` |

**To add OCA modules:**
```bash
git submodule add https://github.com/OCA/server-tools addons/oca/server-tools
cd addons/oca/server-tools
git checkout 18.0
cd ../../..
git add .gitmodules addons/oca/server-tools
git commit -m "Add OCA server-tools at commit <SHA>"
```

**To update OCA modules:**
```bash
git submodule update --remote --merge
# Test thoroughly before committing
git add addons/oca/
git commit -m "Update OCA modules to latest 18.0 branch"
```

## 🛠️ Common Operations

### Development

```bash
make up              # Start services
make logs            # Follow Odoo logs
make restart         # Restart Odoo
make down            # Stop services
```

### Deployment

```bash
make update          # Pull latest code and rebuild
make backup          # Backup DB + filestore
make restore         # Restore from backup
make health          # Run health checks
```

### Database Operations

```bash
# Manual backup
docker compose exec -T db pg_dump -U odoo -Fc insightpulse_prod > backup.dump

# Manual restore
cat backup.dump | docker compose exec -T db pg_restore -U odoo -d insightpulse_prod --clean

# Filestore backup
docker cp odoo:/var/lib/odoo/filestore/insightpulse_prod ./filestore
tar -czf filestore.tar.gz filestore

# Filestore restore
tar -xzf filestore.tar.gz
docker cp filestore/insightpulse_prod odoo:/var/lib/odoo/filestore/
```

## 🔒 Security

### Domain Locking

Odoo is configured to only serve `insightpulseai.net`:

- `web.base.url` set to `https://insightpulseai.net`
- `web.base.url.freeze` = True
- `dbfilter = ^insightpulse_prod$`
- Traefik router only accepts `insightpulseai.net` Host header

### Disabled Features

- Odoo SaaS app store (`publisher_warranty_url = ''`)
- IAP services (`iap.endpoint = localhost`)
- Database expiration checks

### TLS Certificate

- Automatic Let's Encrypt via Traefik
- HTTP → HTTPS redirect
- Certificate auto-renewal

### Secrets Management

**Never commit:**
- `.env.prod` (production secrets)
- Database dumps
- Filestore archives
- SSL certificates

**GitHub Secrets (Actions):**
- `SSH_PRIVATE_KEY` - for deployment
- `POSTGRES_PASSWORD` - database password
- `ODOO_ADMIN_PASS` - admin password

## 🚨 Troubleshooting

### Service not starting

```bash
docker compose ps
docker compose logs odoo
docker compose logs db
```

### Database connection issues

```bash
docker compose exec db psql -U odoo -d insightpulse_prod -c "SELECT version();"
```

### TLS certificate issues

```bash
docker compose logs traefik
# Check Let's Encrypt logs
docker compose exec traefik cat /letsencrypt/acme.json
```

### Health check failing

```bash
./scripts/health_check.sh
curl -v https://insightpulseai.net/web/health
```

## 📋 Cutover Checklist

### Pre-Deployment

- [ ] Backup current production database
- [ ] Backup current production filestore
- [ ] Test blue-green setup under `new.insightpulseai.net`
- [ ] Verify all modules load correctly
- [ ] Run smoke tests (login, create record, send email)

### Deployment

- [ ] Build and start new stack: `make up`
- [ ] Restore database: `make restore`
- [ ] Set base URL: `make set-base-url`
- [ ] Run health checks: `make health`
- [ ] Verify `/web/health` returns 200
- [ ] Verify TLS certificate valid
- [ ] Test login and module functionality

### Post-Deployment

- [ ] Monitor logs for errors: `make logs`
- [ ] Validate all critical workflows
- [ ] Test email sending
- [ ] Test report generation
- [ ] Verify scheduled actions running
- [ ] Archive old containers

### Rollback Plan

If deployment fails:

```bash
# Stop new stack
make down

# Restore old containers
docker start odoo18 odoo-db

# Verify old setup works
curl -sf https://insightpulseai.net/web/health
```

## 🤖 CI/CD

GitHub Actions workflows:

- **Lint** (`.github/workflows/lint.yml`) - Code quality checks
- **Test** (`.github/workflows/test.yml`) - Odoo module tests
- **Deploy** (`.github/workflows/deploy.yml`) - Production deployment

**Triggers:**
- Push to `main` → auto-deploy to production
- Pull requests → lint + test
- Manual dispatch → on-demand deployment

**Health Gates:**
- All tests must pass
- `/web/health` must return 200
- TLS certificate must be valid
- Database must be accessible

## 📝 Changelog

### 2025-10-22 - Initial Release
- Odoo 18.0-20251008 production deployment
- PostgreSQL 15.14
- Traefik v3.1 with Let's Encrypt
- OCA modules as git submodules
- Automated backup/restore scripts
- GitHub Actions CI/CD
- Domain locking (insightpulseai.net)
- SaaS features disabled

## 📄 License

Proprietary - All rights reserved.

## 👥 Maintainers

- Jake Tolentino (@jgtolentino) - jgtolentino_rn@yahoo.com
