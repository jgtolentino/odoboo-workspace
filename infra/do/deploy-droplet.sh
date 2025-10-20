#!/bin/bash
set -e

echo "📦 DigitalOcean OCR Service Droplet Deployment"
echo "=============================================="

# Configuration
DROPLET_NAME="ocr-service-droplet"
REGION="sgp1"  # Singapore
SIZE="s-2vcpu-4gb"  # $24/month ($12 with trial credits)
IMAGE="docker-20-04"  # Ubuntu 20.04 with Docker pre-installed
SSH_KEY_NAME="$(doctl compute ssh-key list --format Name --no-header | head -1)"

echo ""
echo "Step 1: Create Droplet"
echo "----------------------"
echo "Name: $DROPLET_NAME"
echo "Region: $REGION"
echo "Size: $SIZE ($24/month)"
echo "Image: $IMAGE"

# Check if droplet already exists
EXISTING_DROPLET=$(doctl compute droplet list --format ID,Name --no-header | grep "$DROPLET_NAME" | awk '{print $1}' || true)

if [ -n "$EXISTING_DROPLET" ]; then
    echo "⚠️  Droplet already exists (ID: $EXISTING_DROPLET)"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing droplet..."
        doctl compute droplet delete "$EXISTING_DROPLET" --force
        sleep 10
    else
        echo "Using existing droplet ID: $EXISTING_DROPLET"
        DROPLET_ID="$EXISTING_DROPLET"
    fi
fi

if [ -z "$DROPLET_ID" ]; then
    echo "Creating new droplet..."
    DROPLET_ID=$(doctl compute droplet create "$DROPLET_NAME" \
        --region "$REGION" \
        --size "$SIZE" \
        --image "$IMAGE" \
        --ssh-keys "$(doctl compute ssh-key list --format ID --no-header | head -1)" \
        --wait \
        --format ID \
        --no-header)

    echo "✅ Droplet created: ID $DROPLET_ID"
fi

echo ""
echo "Step 2: Get Droplet IP"
echo "---------------------"
sleep 5  # Wait for IP assignment
DROPLET_IP=$(doctl compute droplet get "$DROPLET_ID" --format PublicIPv4 --no-header)
echo "✅ Droplet IP: $DROPLET_IP"

echo ""
echo "Step 3: Wait for SSH"
echo "-------------------"
echo "Waiting for SSH to be available..."
for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@"$DROPLET_IP" "echo 'SSH ready'" 2>/dev/null; then
        echo "✅ SSH is ready"
        break
    fi
    echo "Attempt $i/30: SSH not ready yet..."
    sleep 10
done

echo ""
echo "Step 4: Deploy OCR Service"
echo "-------------------------"
echo "Copying deployment files..."
scp -o StrictHostKeyChecking=no \
    ./docker-compose-droplet.yml \
    ./nginx.conf \
    root@"$DROPLET_IP":/root/

echo "Logging into DO Container Registry on droplet..."
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "doctl registry login || docker login registry.digitalocean.com -u \$(doctl registry docker-credentials --expiry-seconds 3600 | jq -r '.auths.\"registry.digitalocean.com\".username') -p \$(doctl registry docker-credentials --expiry-seconds 3600 | jq -r '.auths.\"registry.digitalocean.com\".password')"

echo "Pulling OCR service image..."
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "docker pull registry.digitalocean.com/fin-workspace/ocr-service:latest"

echo "Starting services..."
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "cd /root && docker-compose -f docker-compose-droplet.yml up -d"

echo ""
echo "Step 5: Health Check"
echo "-------------------"
sleep 15  # Wait for service to start
echo "Checking OCR service health..."
for i in {1..10}; do
    if ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "curl -sf http://localhost:8000/health" | jq; then
        echo "✅ OCR service is healthy"
        break
    fi
    echo "Attempt $i/10: Service not ready yet..."
    sleep 10
done

echo ""
echo "=============================================="
echo "🚀 Deployment Complete!"
echo "=============================================="
echo ""
echo "OCR Service URL: http://$DROPLET_IP:8000"
echo "Health Check: http://$DROPLET_IP:8000/health"
echo "Droplet IP: $DROPLET_IP"
echo "Droplet ID: $DROPLET_ID"
echo ""
echo "Next Steps:"
echo "1. Configure your domain DNS to point to $DROPLET_IP"
echo "2. Run: ssh root@$DROPLET_IP"
echo "3. Setup SSL: ./setup-ssl.sh your-domain.com"
echo "4. Update Odoo system parameter: hr_expense_ocr_audit.ocr_api_url = https://your-domain.com/ocr"
echo ""
echo "To view logs: ssh root@$DROPLET_IP 'docker-compose -f docker-compose-droplet.yml logs -f'"
echo "To check status: ssh root@$DROPLET_IP 'docker-compose -f docker-compose-droplet.yml ps'"
echo ""
