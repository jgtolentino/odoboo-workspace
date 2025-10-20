# 🚀 MCP Connectors Deployment Guide

**Deploy spec-inventory and odoo MCP servers to insightpulseai.net DO droplet**

**Last Updated**: 2025-10-20

---

## 📋 Overview

This guide deploys:
- ✅ **Spec Inventory Gateway** (HTTP API for ChatGPT)
- ✅ **Odoo MCP Server** (XML-RPC wrapper)
- ✅ **Supabase MCP** (already hosted)
- ✅ **Claude/Cursor config** (local MCP clients)

All running on single DO droplet at `188.166.237.231` (insightpulseai.net)

---

## 🎯 Architecture

```
insightpulseai.net (DO Droplet)
├── NGINX (port 80/443)
│   ├── / → Odoo (port 8069)
│   ├── /ocr/ → OCR Service (port 8000)
│   └── /agent/spec/ → Spec Gateway (port 8787) ← NEW
│
├── Docker Compose Services:
│   ├── odoo18
│   ├── ocr-service
│   ├── agent-service
│   ├── spec-gateway ← NEW
│   └── mcp-odoo ← NEW
```

---

## 📦 Step 1: Push Code to Repo

```bash
cd /path/to/odoboo-workspace

# Ensure all MCP files are committed
git add servers/ gateways/ openapi/ .github/workflows/
git commit -m "feat: complete MCP deployment setup"
git push origin main
```

---

## 🚀 Step 2: Deploy to DO Droplet

### A. SSH to Droplet

```bash
ssh root@188.166.237.231
cd /opt/fin-workspace
```

### B. Pull Latest Code

```bash
git pull origin main

# Or if this is first time:
git clone https://github.com/jgtolentino/odoboo-workspace.git /opt/fin-workspace
cd /opt/fin-workspace
```

### C. Create Environment File

```bash
# Create .env if it doesn't exist
cat > .env << 'EOF'
# MCP Admin Token (generate with: openssl rand -base64 32)
MCP_ADMIN_TOKEN=your-secure-token-here

# Odoo Credentials
ODOO_URL=https://insightpulseai.net
ODOO_DB=odoboo_prod
ODOO_USER=admin@insightpulseai.net
ODOO_PWD=your-odoo-password

# Workspace paths
WORKSPACE_ROOT=/opt/fin-workspace
SPECS_DIR=specs
EOF

# Secure the .env file
chmod 600 .env
```

### D. Add Services to docker-compose.yml

```bash
# Backup existing compose file
cp docker-compose.yml docker-compose.yml.backup

# Append new services
cat >> docker-compose.yml << 'EOF'

  # Spec Inventory HTTP Gateway (for ChatGPT Actions)
  spec-gateway:
    image: node:20-alpine
    container_name: spec-gateway
    working_dir: /app
    command: sh -c "npm install -g express js-yaml glob && node /app/spec-inventory-http.js"
    volumes:
      - ./gateways:/app:ro
      - ./specs:/opt/fin-workspace/specs:ro
    environment:
      - PORT=8787
      - MCP_ADMIN_TOKEN=${MCP_ADMIN_TOKEN}
      - WORKSPACE_ROOT=/opt/fin-workspace
      - SPECS_DIR=specs
    networks:
      - default
    ports:
      - "127.0.0.1:8787:8787"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8787/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Odoo MCP Server (for Claude/Cursor via stdio)
  mcp-odoo:
    image: python:3.11-slim
    container_name: mcp-odoo
    working_dir: /app
    command: python main.py
    volumes:
      - ./servers/mcp-odoo:/app:ro
    environment:
      - ODOO_URL=${ODOO_URL}
      - ODOO_DB=${ODOO_DB}
      - ODOO_USER=${ODOO_USER}
      - ODOO_PWD=${ODOO_PWD}
      - MCP_ADMIN_TOKEN=${MCP_ADMIN_TOKEN}
    networks:
      - default
    restart: unless-stopped
EOF
```

### E. Update NGINX Configuration

```bash
# Edit nginx config
nano config/nginx.conf

# Add inside the server block (port 443):
```

```nginx
# ChatGPT Action (HTTP bridge)
location /agent/spec/ {
    proxy_pass http://spec-gateway:8787/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Serve OpenAPI schema
location = /agent/spec/openapi.yaml {
    alias /opt/fin-workspace/openapi/spec-inventory.yaml;
    default_type text/yaml;
    add_header Access-Control-Allow-Origin *;
}

# Secure write operations (optional - already handled by Bearer token)
map $http_authorization $mcp_admin_ok {
    default 0;
    "~*Bearer\s+${MCP_ADMIN_TOKEN}" 1;
}

location ~ ^/agent/spec/(create_spec|update_spec|mark_done)$ {
    if ($mcp_admin_ok = 0) {
        return 401 '{"error": "Unauthorized - Admin token required"}';
    }
    proxy_pass http://spec-gateway:8787$request_uri;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### F. Deploy Services

```bash
# Build and start new services
docker compose up -d spec-gateway mcp-odoo

# Restart nginx to pick up config changes
docker compose restart nginx

# Verify services are running
docker compose ps

# Check logs
docker compose logs -f spec-gateway
docker compose logs -f mcp-odoo
```

### G. Test Deployment

```bash
# Test health endpoint
curl -fsSL https://insightpulseai.net/agent/spec/health | jq

# Test list_features (no auth required)
curl -fsSL https://insightpulseai.net/agent/spec/list_features \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{}' | jq

# Test OpenAPI spec
curl -fsSL https://insightpulseai.net/agent/spec/openapi.yaml | head -20

# Test write operation (requires auth)
curl -fsSL https://insightpulseai.net/agent/spec/mark_done \
  -X POST \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $MCP_ADMIN_TOKEN" \
  -d '{"id": "TEST-001"}' | jq
```

---

## 🔧 Step 3: Configure Claude Desktop / Cursor

### A. Cursor Configuration

On your **local machine** (where you run Cursor):

```bash
# Create MCP config directory
mkdir -p ~/.cursor

# Create MCP config
cat > ~/.cursor/mcp.json << 'EOF'
{
  "mcpServers": {
    "spec-inventory": {
      "command": "node",
      "args": ["/absolute/path/to/odoboo-workspace/servers/mcp-spec-inventory/dist/index.js"],
      "env": {
        "WORKSPACE_ROOT": "/absolute/path/to/odoboo-workspace",
        "SPECS_DIR": "specs"
      }
    },
    "odoo": {
      "command": "python3",
      "args": ["/absolute/path/to/odoboo-workspace/servers/mcp-odoo/main.py"],
      "env": {
        "ODOO_URL": "https://insightpulseai.net",
        "ODOO_DB": "odoboo_prod",
        "ODOO_USER": "admin@insightpulseai.net",
        "ODOO_PWD": "your-password"
      }
    },
    "supabase": {
      "url": "https://mcp.supabase.com/mcp?project_ref=spdtwktxdalcfigzeqrz&features=docs%2Cdatabase%2Caccount%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching%2Cstorage"
    }
  }
}
EOF

# Build the TypeScript MCP servers
cd /path/to/odoboo-workspace/servers/mcp-spec-inventory
npm install
npm run build
```

### B. Claude Desktop Configuration

```bash
# Create MCP config directory
mkdir -p ~/.claude

# Create MCP config
cat > ~/.claude/mcp.json << 'EOF'
{
  "mcpServers": {
    "spec-inventory": {
      "command": "node",
      "args": ["/absolute/path/to/odoboo-workspace/servers/mcp-spec-inventory/dist/index.js"],
      "env": {
        "WORKSPACE_ROOT": "/absolute/path/to/odoboo-workspace",
        "SPECS_DIR": "specs"
      }
    },
    "odoo": {
      "command": "python3",
      "args": ["/absolute/path/to/odoboo-workspace/servers/mcp-odoo/main.py"],
      "env": {
        "ODOO_URL": "https://insightpulseai.net",
        "ODOO_DB": "odoboo_prod",
        "ODOO_USER": "admin@insightpulseai.net",
        "ODOO_PWD": "your-password"
      }
    },
    "supabase": {
      "url": "https://mcp.supabase.com/mcp?project_ref=spdtwktxdalcfigzeqrz&features=docs%2Cdatabase%2Caccount%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching%2Cstorage"
    }
  }
}
EOF
```

### C. Test Claude/Cursor MCP Tools

Open Claude Desktop or Cursor and try:

```
List all feature specs

Search for specs about "authentication"

Create a new spec:
ID: FEAT-042
Title: Add OAuth2 login
Priority: P1
Owner: developer@company.com
Status: todo

Get details for spec FEAT-001

Update spec FEAT-042 status to "doing"

Query Odoo for hr expenses:
search_read model="hr.expense" domain=[] fields=["name","amount","employee_id"] limit=10
```

---

## 🎯 Step 4: Configure ChatGPT Actions

### A. Create GPT with Actions

1. Go to https://chat.openai.com/gpts/editor
2. Create new GPT
3. Go to "Configure" → "Actions"
4. Click "Create new action"

### B. Import OpenAPI Schema

**Schema URL**:
```
https://insightpulseai.net/agent/spec/openapi.yaml
```

Or paste the entire contents of `openapi/spec-inventory.yaml`

### C. Configure Authentication

**Authentication Type**: API Key

**API Key**:
```
Authorization: Bearer your-mcp-admin-token-here
```

### D. Test in ChatGPT

Try these prompts:

```
List all feature specs

Show me all P0 specs that are in "todo" status

Get spec FEAT-001

Create a new spec for user profile feature

Mark spec FEAT-042 as done

Search for specs about "database"
```

---

## 🔐 Step 5: Set GitHub Secrets

```bash
# On your local machine
gh secret set MCP_ADMIN_TOKEN -b "$(openssl rand -base64 32)"
gh secret set ODOO_USER -b "admin@insightpulseai.net"
gh secret set ODOO_PWD -b "your-odoo-password"
```

Or manually via GitHub UI:
https://github.com/jgtolentino/odoboo-workspace/settings/secrets/actions

---

## ✅ Verification Checklist

After deployment:

- [ ] **Services running**: `docker compose ps` shows spec-gateway and mcp-odoo as "Up"
- [ ] **Health check**: `curl https://insightpulseai.net/agent/spec/health` returns `{"status": "ok"}`
- [ ] **List features**: Can list specs via API
- [ ] **OpenAPI spec**: `curl https://insightpulseai.net/agent/spec/openapi.yaml` returns YAML
- [ ] **Claude Desktop**: Can use spec-inventory tools
- [ ] **Cursor**: Can use spec-inventory tools
- [ ] **ChatGPT**: Actions are working
- [ ] **CI Health Check**: Workflow passes every 30 minutes

---

## 🔧 Troubleshooting

### Service Not Starting

```bash
# Check logs
docker compose logs spec-gateway
docker compose logs mcp-odoo

# Check environment variables
docker compose exec spec-gateway env | grep MCP
docker compose exec mcp-odoo env | grep ODOO

# Restart services
docker compose restart spec-gateway mcp-odoo
```

### NGINX 502 Bad Gateway

```bash
# Check if service is listening
docker compose exec spec-gateway netstat -tlnp

# Check NGINX config
docker compose exec nginx nginx -t

# Reload NGINX
docker compose exec nginx nginx -s reload
```

### MCP Tools Not Working in Claude/Cursor

```bash
# Check MCP config
cat ~/.claude/mcp.json
cat ~/.cursor/mcp.json

# Test MCP server directly
cd /path/to/servers/mcp-spec-inventory
npm run build
echo '{"method": "tools/list", "params": {}}' | node dist/index.js

# Check logs in Claude/Cursor developer console
```

### Authentication Errors

```bash
# Verify token
echo $MCP_ADMIN_TOKEN

# Test with auth
curl -fsSL https://insightpulseai.net/agent/spec/create_spec \
  -H "Authorization: Bearer $MCP_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "TEST", "title": "Test", "priority": "P2", "owner": "test", "status": "todo"}'
```

---

## 📚 Related Documentation

- [Secret Management Architecture](./SECRET_MANAGEMENT_ARCHITECTURE.md)
- [Authentication Fix Guide](./AUTHENTICATION_FIX_GUIDE.md)
- [Database Migrations Guide](./DATABASE_MIGRATIONS.md)
- [GitHub Secrets Setup](./GITHUB_SECRETS_SETUP.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-20
**Next Review**: After deployment
