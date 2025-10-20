#!/bin/bash

# deploy-agent-service.sh - Deploy agent + OCR services to Singapore droplet
# Usage: ./scripts/deploy-agent-service.sh [DROPLET_IP]

set -e

# Configuration
DROPLET_IP="${1:-188.166.237.231}"
DROPLET_USER="root"
REMOTE_DIR="/opt/services"

echo "🚀 Deploying agent + OCR services to $DROPLET_IP"

# Check prerequisites
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. Copy .env.example to .env and configure."
    exit 1
fi

if ! command -v scp &> /dev/null; then
    echo "❌ Error: scp not found. Please install OpenSSH client."
    exit 1
fi

# Step 1: Create remote directory
echo "📁 Creating remote directory..."
ssh ${DROPLET_USER}@${DROPLET_IP} "mkdir -p ${REMOTE_DIR}"

# Step 2: Copy services
echo "📦 Copying OCR service..."
scp -r services/ocr-service ${DROPLET_USER}@${DROPLET_IP}:${REMOTE_DIR}/

echo "📦 Copying agent service..."
scp -r services/agent-service ${DROPLET_USER}@${DROPLET_IP}:${REMOTE_DIR}/

# Step 3: Copy configuration
echo "⚙️  Copying configuration files..."
scp docker-compose.services.yml ${DROPLET_USER}@${DROPLET_IP}:${REMOTE_DIR}/docker-compose.yml
scp nginx.conf ${DROPLET_USER}@${DROPLET_IP}:${REMOTE_DIR}/
scp .env ${DROPLET_USER}@${DROPLET_IP}:${REMOTE_DIR}/

# Step 4: Deploy services
echo "🔧 Installing Docker and dependencies..."
ssh ${DROPLET_USER}@${DROPLET_IP} << 'EOF'
# Install Docker if not exists
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Install Docker Compose if not exists
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    apt install -y docker-compose
fi

# Verify installation
docker --version
docker-compose --version
EOF

echo "🏗️  Building and starting services..."
ssh ${DROPLET_USER}@${DROPLET_IP} << 'EOF'
cd /opt/services

# Stop existing services
docker-compose down 2>/dev/null || true

# Build and start services
docker-compose up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
docker-compose ps
docker-compose logs --tail=20
EOF

# Step 5: Verify deployment
echo "✅ Verifying deployment..."
sleep 10

# Check OCR service
if curl -sf http://${DROPLET_IP}/ocr/health > /dev/null; then
    echo "✅ OCR Service: HEALTHY"
else
    echo "❌ OCR Service: NOT RESPONDING"
fi

# Check agent service
if curl -sf http://${DROPLET_IP}/agent/health > /dev/null; then
    echo "✅ Agent Service: HEALTHY"
else
    echo "❌ Agent Service: NOT RESPONDING"
fi

# Check nginx
if curl -sf http://${DROPLET_IP}/health > /dev/null; then
    echo "✅ Nginx: HEALTHY"
else
    echo "❌ Nginx: NOT RESPONDING"
fi

# Step 6: Display access information
echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 Service Endpoints:"
echo "  - OCR Service: http://${DROPLET_IP}/ocr/"
echo "  - Agent Service: http://${DROPLET_IP}/agent/"
echo "  - Health Check: http://${DROPLET_IP}/health"
echo ""
echo "📚 API Documentation:"
echo "  - OCR: http://${DROPLET_IP}/ocr/docs"
echo "  - Agent: http://${DROPLET_IP}/agent/docs"
echo ""
echo "🔍 View logs:"
echo "  ssh ${DROPLET_USER}@${DROPLET_IP} 'cd ${REMOTE_DIR} && docker-compose logs -f'"
echo ""
echo "🔄 Restart services:"
echo "  ssh ${DROPLET_USER}@${DROPLET_IP} 'cd ${REMOTE_DIR} && docker-compose restart'"
echo ""
