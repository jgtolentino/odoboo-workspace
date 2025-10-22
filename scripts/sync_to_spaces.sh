#!/usr/bin/env bash
set -euo pipefail

# DigitalOcean Spaces Configuration
# Set these environment variables before running:
# export AWS_ACCESS_KEY_ID=your_access_key
# export AWS_SECRET_ACCESS_KEY=your_secret_key
# export DO_SPACE=your-space-name
# export DO_REGION=sgp1

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  echo "Error: AWS_ACCESS_KEY_ID not set"
  exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Error: AWS_SECRET_ACCESS_KEY not set"
  exit 1
fi

SPACE="${DO_SPACE:-odoobo-backups}"
REGION="${DO_REGION:-sgp1}"
ENDPOINT="https://${REGION}.digitaloceanspaces.com"

echo "Syncing backups to DO Spaces: ${SPACE}"

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."
  apt-get update && apt-get install -y awscli
fi

# Sync backups
aws --endpoint-url "${ENDPOINT}" \
  s3 sync /opt/odoobo/backup "s3://${SPACE}/odoobo/backup" \
  --storage-class STANDARD

echo "✅ Backup sync complete"
