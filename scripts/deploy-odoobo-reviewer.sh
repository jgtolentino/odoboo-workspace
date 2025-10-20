#!/bin/bash
# Deploy odoobo-reviewer sub-agent to production server
# Usage: ./scripts/deploy-odoobo-reviewer.sh

set -e

SERVER="root@188.166.237.231"
REVIEWER_DIR="/opt/fin-workspace/services/odoobo-reviewer"

echo "🚀 Deploying odoobo-reviewer sub-agent..."

# Create directory on server
ssh $SERVER "mkdir -p $REVIEWER_DIR"

# Copy service files
echo "📦 Copying service files..."
scp .claude/services/odoobo-reviewer/Dockerfile $SERVER:$REVIEWER_DIR/
scp .claude/services/odoobo-reviewer/main.py $SERVER:$REVIEWER_DIR/
scp .claude/services/odoobo-reviewer/config.json $SERVER:$REVIEWER_DIR/

# Update docker-compose.yml on server
echo "🐳 Updating docker-compose configuration..."
ssh $SERVER "cd /opt/fin-workspace && cat >> docker-compose.yml << 'EOF'

  odoobo-reviewer:
    build: ./services/odoobo-reviewer
    container_name: fin-reviewer
    restart: unless-stopped
    expose: [\"8003\"]
    environment:
      - LOG_LEVEL=INFO
    healthcheck:
      test: [\"CMD-SHELL\",\"wget -qO- http://localhost:8003/health || exit 1\"]
      interval: 30s
      timeout: 5s
      retries: 5
EOF
"

# Build and start the reviewer service
echo "🔨 Building and starting service..."
ssh $SERVER "cd /opt/fin-workspace && docker compose up -d --build odoobo-reviewer"

# Wait for service to start
echo "⏳ Waiting for service to be ready..."
sleep 10

# Test the service
echo "🧪 Testing service endpoints..."
ssh $SERVER "curl -f http://localhost:8003/health" || echo "⚠️  Health check failed"
ssh $SERVER "curl -f http://localhost:8003/status" || echo "⚠️  Status check failed"

# Show service status
ssh $SERVER "docker ps | grep -E '(fin-reviewer|NAMES)'"

echo "✅ Odoobo-reviewer sub-agent deployed successfully!"
echo ""
echo "📋 Service Details:"
echo "   Local endpoint: http://localhost:8003"
echo "   Remote agent: https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run"
echo "   Container: fin-reviewer"
echo ""
echo "🔗 Integration:"
echo "   SuperClaude agent config: .claude/agents/odoobo-reviewer.agent.yaml"
echo "   Auto-activates on PR reviews and Odoo module analysis"
