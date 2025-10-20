#!/bin/bash
# Download OCA modules for Odoo 18 enterprise features

set -e

OCA_DIR="./oca"
ODOO_VERSION="18.0"

echo "🔽 Downloading OCA modules for Odoo ${ODOO_VERSION}..."

# Create OCA directory
mkdir -p "${OCA_DIR}"
cd "${OCA_DIR}"

# List of OCA repositories
REPOS=(
    "knowledge:https://github.com/OCA/knowledge.git"
    "account-financial-tools:https://github.com/OCA/account-financial-tools.git"
    "account-financial-reporting:https://github.com/OCA/account-financial-reporting.git"
    "social:https://github.com/OCA/social.git"
    "web:https://github.com/OCA/web.git"
    "server-ux:https://github.com/OCA/server-ux.git"
    "project:https://github.com/OCA/project.git"
    "server-tools:https://github.com/OCA/server-tools.git"
)

# Download each repository
for repo_entry in "${REPOS[@]}"; do
    repo_name="${repo_entry%%:*}"
    repo_url="${repo_entry#*:}"

    if [ -d "${repo_name}" ]; then
        echo "⏭️  ${repo_name} already exists, skipping..."
    else
        echo "📦 Downloading ${repo_name}..."

        # Try 18.0 branch first, fallback to 17.0, then 16.0
        if git clone --depth 1 -b "${ODOO_VERSION}" "${repo_url}" "${repo_name}" 2>/dev/null; then
            echo "✅ ${repo_name} (${ODOO_VERSION})"
        elif git clone --depth 1 -b "17.0" "${repo_url}" "${repo_name}" 2>/dev/null; then
            echo "⚠️  ${repo_name} (17.0 - ${ODOO_VERSION} not available)"
        elif git clone --depth 1 -b "16.0" "${repo_url}" "${repo_name}" 2>/dev/null; then
            echo "⚠️  ${repo_name} (16.0 - ${ODOO_VERSION} not available)"
        else
            echo "❌ Failed to clone ${repo_name}"
        fi
    fi
done

cd ..

echo ""
echo "✅ OCA module download complete!"
echo ""
echo "📊 Downloaded modules:"
ls -1 "${OCA_DIR}"
echo ""
echo "🚀 Ready to start Odoo with: docker-compose -f docker-compose.local.yml up -d"
