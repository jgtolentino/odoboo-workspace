#!/bin/bash
# Add local SSH public key to DigitalOcean droplet via recovery console automation
# This script uses DigitalOcean API to access droplet and add SSH key

set -e

DROPLET_IP="128.199.124.77"
PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

echo "Adding SSH key to droplet at $DROPLET_IP"
echo ""
echo "Method: Use DigitalOcean web console and run this command:"
echo ""
echo "cat >> ~/.ssh/authorized_keys << 'EOF'"
echo "$PUBLIC_KEY"
echo "EOF"
echo ""
echo "Then set permissions:"
echo "chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "After that, test with: ssh root@$DROPLET_IP"
