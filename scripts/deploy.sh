#!/bin/bash
# scripts/deploy.sh - Deployment script for Odoo 18.0 on DigitalOcean

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Odoo 18.0 with OCA to DigitalOcean...${NC}"

# Check for required environment variables
required_vars=("DO_TOKEN" "DOMAIN_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: $var is not set${NC}"
        echo "Please set it in .env file or export it"
        exit 1
    fi
done

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo -e "${YELLOW}📋 Loading environment variables from .env...${NC}"
    export $(grep -v '^#' .env | xargs)
fi

# Function: Deploy using App Platform
deploy_app_platform() {
    echo -e "${GREEN}📦 Deploying to DigitalOcean App Platform...${NC}"

    # Check if doctl is installed
    if ! command -v doctl &> /dev/null; then
        echo -e "${RED}Error: doctl CLI not found${NC}"
        echo "Install it: brew install doctl (macOS) or visit https://docs.digitalocean.com/reference/doctl/"
        exit 1
    fi

    # Authenticate with DigitalOcean
    echo -e "${YELLOW}🔐 Authenticating with DigitalOcean...${NC}"
    doctl auth init --access-token "$DO_TOKEN"

    # Create or update app
    if [ -z "$APP_ID" ]; then
        echo -e "${YELLOW}Creating new app...${NC}"
        doctl apps create --spec app.yaml --wait
    else
        echo -e "${YELLOW}Updating existing app (ID: $APP_ID)...${NC}"
        doctl apps update "$APP_ID" --spec app.yaml
        doctl apps create-deployment "$APP_ID" --wait
    fi

    echo -e "${GREEN}✅ App Platform deployment complete!${NC}"
}

# Function: Deploy using Droplet + Docker
deploy_droplet() {
    echo -e "${GREEN}🖥️  Deploying to Droplet with Docker...${NC}"

    # Check if SSH key ID is provided
    if [ -z "$SSH_KEY_ID" ]; then
        echo -e "${YELLOW}No SSH_KEY_ID provided. Using first available SSH key...${NC}"
        SSH_KEY_ID=$(doctl compute ssh-key list --format ID --no-header | head -n 1)
        if [ -z "$SSH_KEY_ID" ]; then
            echo -e "${RED}Error: No SSH keys found. Please add an SSH key to your DigitalOcean account${NC}"
            exit 1
        fi
    fi

    echo -e "${YELLOW}Creating droplet with cloud-init...${NC}"

    # Create droplet
    DROPLET_ID=$(doctl compute droplet create odoo18-server \
        --image ubuntu-22-04-x64 \
        --size s-2vcpu-4gb \
        --region nyc3 \
        --ssh-keys "$SSH_KEY_ID" \
        --user-data-file terraform/cloud-init.yaml \
        --format ID \
        --no-header)

    echo -e "${GREEN}✅ Droplet created: $DROPLET_ID${NC}"

    # Wait for droplet to be ready
    echo -e "${YELLOW}⏳ Waiting for droplet to be ready (60 seconds)...${NC}"
    sleep 60

    # Get IP address
    IP=$(doctl compute droplet get "$DROPLET_ID" --format PublicIPv4 --no-header)
    echo -e "${GREEN}📍 Droplet IP: $IP${NC}"

    # Setup DNS (if domain is configured)
    if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "odoo.yourdomain.com" ]; then
        echo -e "${YELLOW}🌐 Setting up DNS...${NC}"
        DOMAIN_PARTS=(${DOMAIN_NAME//./ })
        BASE_DOMAIN="${DOMAIN_PARTS[-2]}.${DOMAIN_PARTS[-1]}"

        doctl compute domain records create "$BASE_DOMAIN" \
            --record-type A \
            --record-name "${DOMAIN_PARTS[0]}" \
            --record-data "$IP" \
            --record-ttl 300 || true

        echo -e "${GREEN}✅ DNS record created${NC}"
    fi

    echo -e "${GREEN}✅ Droplet deployment complete!${NC}"
    echo -e "${YELLOW}Access Odoo at: http://$IP:8069${NC}"
}

# Function: Deploy using Terraform
deploy_terraform() {
    echo -e "${GREEN}🏗️  Deploying with Terraform...${NC}"

    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: terraform not found${NC}"
        echo "Install it: brew install terraform (macOS) or visit https://www.terraform.io/downloads"
        exit 1
    fi

    cd terraform

    # Initialize Terraform
    echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
    terraform init

    # Format check
    echo -e "${YELLOW}📝 Checking Terraform formatting...${NC}"
    terraform fmt

    # Validate configuration
    echo -e "${YELLOW}✅ Validating Terraform configuration...${NC}"
    terraform validate

    # Plan
    echo -e "${YELLOW}📋 Creating Terraform plan...${NC}"
    terraform plan -out=tfplan \
        -var="do_token=$DO_TOKEN" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="admin_password=${ODOO_ADMIN_PASSWORD:-changeme123}"

    # Apply
    echo -e "${YELLOW}🚀 Applying Terraform plan...${NC}"
    read -p "Do you want to apply this plan? (yes/no): " CONFIRM

    if [ "$CONFIRM" = "yes" ]; then
        terraform apply tfplan

        # Get outputs
        echo -e "${GREEN}📊 Deployment Information:${NC}"
        echo -e "Odoo Server IP: $(terraform output -raw odoo_server_ip)"
        echo -e "Load Balancer IP: $(terraform output -raw load_balancer_ip)"
        echo -e "Database Host: $(terraform output -raw database_host)"
        echo -e "Spaces Bucket: $(terraform output -raw spaces_bucket_name)"

        echo -e "${GREEN}✅ Terraform deployment complete!${NC}"
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
    fi

    cd ..
}

# Function: Local development deployment
deploy_local() {
    echo -e "${GREEN}💻 Starting local development environment...${NC}"

    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: docker-compose not found${NC}"
        echo "Install Docker Desktop or docker-compose"
        exit 1
    fi

    # Create necessary directories
    mkdir -p addons oca config

    # Download OCA modules if not already present
    if [ ! -d "oca/web" ]; then
        echo -e "${YELLOW}📦 Downloading OCA modules...${NC}"
        ./scripts/download_oca_modules.sh
    fi

    # Start services
    echo -e "${YELLOW}🐳 Starting Docker containers...${NC}"
    docker-compose up -d

    # Wait for services to be ready
    echo -e "${YELLOW}⏳ Waiting for Odoo to start (30 seconds)...${NC}"
    sleep 30

    echo -e "${GREEN}✅ Local development environment ready!${NC}"
    echo -e "${YELLOW}Access Odoo at: http://localhost:8069${NC}"
    echo -e "${YELLOW}Database: odoo (user: odoo, password: odoo)${NC}"
}

# Main deployment logic
case "${1:-local}" in
    app)
        deploy_app_platform
        ;;
    droplet)
        deploy_droplet
        ;;
    terraform)
        deploy_terraform
        ;;
    local)
        deploy_local
        ;;
    *)
        echo "Usage: $0 [app|droplet|terraform|local]"
        echo ""
        echo "Deployment methods:"
        echo "  app       - Deploy to DigitalOcean App Platform (managed)"
        echo "  droplet   - Deploy to a single Droplet with Docker"
        echo "  terraform - Deploy full infrastructure with Terraform"
        echo "  local     - Start local development environment"
        echo ""
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "odoo.yourdomain.com" ]; then
    echo -e "${YELLOW}🌐 Access Odoo at: https://$DOMAIN_NAME${NC}"
fi
echo ""
