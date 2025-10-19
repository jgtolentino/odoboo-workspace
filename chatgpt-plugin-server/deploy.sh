#!/bin/bash
set -e

echo "🚀 Deploying ChatGPT Plugin Server to Digital Ocean"

# Check for required tools
if ! command -v doctl &> /dev/null; then
    echo "❌ doctl not found. Install with: brew install doctl"
    exit 1
fi

# Check for DO token
if [ -z "$DO_ACCESS_TOKEN" ]; then
    echo "❌ DO_ACCESS_TOKEN not set in environment"
    exit 1
fi

# Authenticate doctl
echo "🔐 Authenticating with Digital Ocean..."
doctl auth init -t "$DO_ACCESS_TOKEN"

# Check if app exists
APP_NAME="chatgpt-plugin-server"
APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "$APP_NAME" | awk '{print $1}')

if [ -z "$APP_ID" ]; then
    echo "📦 Creating new app..."

    # Prompt for GitHub App credentials
    read -p "Enter GitHub App ID: " GITHUB_APP_ID
    read -sp "Enter GitHub Private Key (paste entire key): " GITHUB_PRIVATE_KEY
    echo ""

    # Generate plugin token
    PLUGIN_TOKEN=$(openssl rand -hex 32)
    echo "🔑 Generated plugin bearer token: $PLUGIN_TOKEN"
    echo "    (Save this! You'll need it to configure ChatGPT)"

    # Update app.yaml with values
    sed -i.bak "s/YOUR_APP_ID/$GITHUB_APP_ID/g" .do/app.yaml
    sed -i.bak "s|YOUR_PRIVATE_KEY_HERE|$GITHUB_PRIVATE_KEY|g" .do/app.yaml
    sed -i.bak "s/GENERATE_WITH_openssl_rand_hex_32/$PLUGIN_TOKEN/g" .do/app.yaml

    # Create app
    doctl apps create --spec .do/app.yaml --wait

    # Restore backup
    mv .do/app.yaml.bak .do/app.yaml

else
    echo "♻️  Updating existing app (ID: $APP_ID)..."

    # Update app
    doctl apps update "$APP_ID" --spec .do/app.yaml

    # Trigger deployment
    echo "🔄 Triggering deployment..."
    doctl apps create-deployment "$APP_ID" --force-rebuild --wait
fi

# Get app URL
APP_URL=$(doctl apps get "$APP_ID" --format DefaultIngress --no-header)

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Plugin URL: https://$APP_URL/.well-known/ai-plugin.json"
echo "   2. Test health: https://$APP_URL/health"
echo "   3. Register in ChatGPT:"
echo "      - Go to chat.openai.com"
echo "      - Create a Custom GPT"
echo "      - Add action from URL: https://$APP_URL/.well-known/openapi.yaml"
echo "      - Set authentication: Bearer token (use PLUGIN_BEARER_TOKEN from above)"
echo ""
