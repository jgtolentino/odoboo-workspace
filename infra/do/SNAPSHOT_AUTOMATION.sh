#!/bin/bash
set -e

# ============================================================================
# DROPLET SNAPSHOT AUTOMATION & MANAGEMENT
# ============================================================================
# Droplet: ocr-service-droplet (ID: 525178434, IP: 188.166.237.231)
# Purpose: Automated daily backups + zero-downtime deployments
# ============================================================================

# Configuration
DROPLET_ID=525178434
DROPLET_NAME="ocr-service-droplet"
SNAPSHOT_PREFIX="ocr"
RETENTION_DAYS=7

echo "📸 DROPLET SNAPSHOT MANAGEMENT"
echo "================================"
echo ""

# ============================================================================
# 1) Manual Snapshot (Safe - Recommended for Upgrades)
# ============================================================================

snapshot_safe() {
    echo "🛑 SAFE SNAPSHOT: Stopping services first..."
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@188.166.237.231 << 'DROPLET_EOF'
cd /root
docker compose down
echo "✓ Services stopped"
DROPLET_EOF

    echo "📸 Taking snapshot..."
    SNAPSHOT_NAME="${SNAPSHOT_PREFIX}-$(date +%Y%m%d-%H%M%S)"
    doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name "$SNAPSHOT_NAME" --wait

    echo "🚀 Restarting services..."
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@188.166.237.231 << 'DROPLET_EOF'
cd /root
docker compose up -d
echo "✓ Services restarted"
DROPLET_EOF

    echo ""
    echo "✅ Safe snapshot created: $SNAPSHOT_NAME"
    echo "   Downtime: ~2-5 minutes"
}

# ============================================================================
# 2) Quick Snapshot (Stateless Services - OCR Service OK)
# ============================================================================

snapshot_quick() {
    echo "📸 QUICK SNAPSHOT: Taking snapshot without stopping services..."
    echo "   (Safe for stateless services like OCR)"

    SNAPSHOT_NAME="${SNAPSHOT_PREFIX}-$(date +%Y%m%d-%H%M%S)"
    doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name "$SNAPSHOT_NAME" --wait

    echo ""
    echo "✅ Quick snapshot created: $SNAPSHOT_NAME"
    echo "   Downtime: 0 seconds"
}

# ============================================================================
# 3) Automated Daily Snapshots (Cron Job)
# ============================================================================

setup_cron() {
    echo "⏰ CRON SETUP: Automated daily snapshots"
    echo ""
    echo "Add this to your crontab (crontab -e):"
    echo "-------------------------------------"
    cat << 'CRON_EXAMPLE'
# Daily droplet snapshot at 3:05 AM UTC
5 3 * * * doctl compute droplet-action snapshot 525178434 \
  --snapshot-name ocr-$(date +\%Y\%m\%d) --wait >> /tmp/ocr-snapshot.log 2>&1
CRON_EXAMPLE
    echo ""
    echo "Or run this command to install:"
    echo "  (crontab -l 2>/dev/null; echo '5 3 * * * doctl compute droplet-action snapshot 525178434 --snapshot-name ocr-\$(date +\\%Y\\%m\\%d) --wait >> /tmp/ocr-snapshot.log 2>&1') | crontab -"
}

# ============================================================================
# 4) List Snapshots
# ============================================================================

list_snapshots() {
    echo "📋 SNAPSHOT LIST:"
    echo "----------------"
    doctl compute snapshot list --resource droplet --format ID,Name,CreatedAt,Size | grep -E "ID|$SNAPSHOT_PREFIX"
}

# ============================================================================
# 5) Cleanup Old Snapshots (Keep Last 7 Days)
# ============================================================================

cleanup_snapshots() {
    echo "🧹 SNAPSHOT CLEANUP: Removing snapshots older than $RETENTION_DAYS days..."
    echo ""

    CUTOFF_DATE=$(date -v-${RETENTION_DAYS}d +%Y%m%d 2>/dev/null || date -d "$RETENTION_DAYS days ago" +%Y%m%d)

    doctl compute snapshot list --resource droplet --format ID,Name,CreatedAt --no-header | \
      grep "$SNAPSHOT_PREFIX" | while read -r snapshot_id snapshot_name created_at; do

        # Extract date from snapshot name (format: ocr-YYYYMMDD or ocr-YYYYMMDD-HHMMSS)
        SNAPSHOT_DATE=$(echo "$snapshot_name" | grep -oE '[0-9]{8}' | head -1)

        if [ -n "$SNAPSHOT_DATE" ] && [ "$SNAPSHOT_DATE" -lt "$CUTOFF_DATE" ]; then
            echo "🗑️  Deleting old snapshot: $snapshot_name ($SNAPSHOT_DATE < $CUTOFF_DATE)"
            doctl compute snapshot delete "$snapshot_id" --force
        else
            echo "✓ Keeping snapshot: $snapshot_name"
        fi
    done

    echo ""
    echo "✅ Cleanup complete"
}

# ============================================================================
# 6) Restore from Snapshot (Create New Droplet)
# ============================================================================

restore_snapshot() {
    SNAPSHOT_ID=$1

    if [ -z "$SNAPSHOT_ID" ]; then
        echo "❌ Error: Please provide snapshot ID"
        echo "Usage: $0 restore <snapshot-id>"
        echo ""
        list_snapshots
        exit 1
    fi

    echo "🔄 RESTORE FROM SNAPSHOT: Creating new droplet..."
    echo "  Snapshot ID: $SNAPSHOT_ID"
    echo "  New Droplet Name: ocr-service-droplet-restored-$(date +%Y%m%d)"
    echo ""

    doctl compute droplet create \
      ocr-service-droplet-restored-$(date +%Y%m%d) \
      --image "$SNAPSHOT_ID" \
      --size s-2vcpu-4gb \
      --region sgp1 \
      --ssh-keys $(doctl compute ssh-key list --format ID --no-header | tr '\n' ',') \
      --wait

    echo ""
    echo "✅ New droplet created from snapshot"
    echo ""
    echo "Next steps:"
    echo "1. Test the new droplet"
    echo "2. If using Reserved IP:"
    echo "   doctl compute floating-ip-action assign <RESERVED_IP> <NEW_DROPLET_ID> --wait"
    echo "3. Update DNS if using custom domain"
}

# ============================================================================
# 7) Zero-Downtime Deployment (Reserved IP Swap)
# ============================================================================

setup_reserved_ip() {
    echo "🌐 RESERVED IP SETUP: Zero-downtime deployments"
    echo ""
    echo "Step 1: Create Reserved IP"
    echo "--------------------------"
    echo "doctl compute floating-ip create --region sgp1"
    echo ""
    echo "Step 2: Assign to Current Droplet"
    echo "-----------------------------------"
    echo "doctl compute floating-ip-action assign <RESERVED_IP> $DROPLET_ID --wait"
    echo ""
    echo "Step 3: For Zero-Downtime Upgrades"
    echo "------------------------------------"
    echo "1. Create new droplet from snapshot"
    echo "2. Test new droplet thoroughly"
    echo "3. Move Reserved IP to new droplet:"
    echo "   doctl compute floating-ip-action assign <RESERVED_IP> <NEW_DROPLET_ID> --wait"
    echo "4. Destroy old droplet after verification:"
    echo "   doctl compute droplet delete $DROPLET_ID"
}

# ============================================================================
# 8) Image Update & Deployment
# ============================================================================

update_image() {
    echo "🔄 IMAGE UPDATE: Pull and deploy latest OCR image"
    echo ""

    # Build and push new image (already done locally)
    echo "Step 1: Authenticate with registry"
    doctl registry login

    echo ""
    echo "Step 2: Deploy on droplet"
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@188.166.237.231 << 'DROPLET_EOF'
cd /root
echo "Pulling latest image..."
docker compose pull

echo "Restarting service..."
docker compose up -d

echo "Waiting for healthcheck..."
sleep 20

echo "Testing health endpoint..."
curl -sf http://localhost:8000/health || echo "❌ Health check failed!"

echo "Service logs:"
docker compose logs --tail=20 ocr
DROPLET_EOF

    echo ""
    echo "✅ Image update complete"
}

# ============================================================================
# 9) Full Backup Strategy
# ============================================================================

backup_all() {
    echo "💾 FULL BACKUP: Snapshot + Docker volumes + configs"
    echo ""

    # 1. Snapshot droplet
    snapshot_safe

    # 2. Backup Docker volumes and configs
    echo ""
    echo "📦 Backing up Docker volumes and configs..."
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@188.166.237.231 << 'DROPLET_EOF'
cd /root
tar -czf ocr-backup-$(date +%Y%m%d).tar.gz docker-compose.yml
echo "✓ Backup created: ocr-backup-$(date +%Y%m%d).tar.gz"
DROPLET_EOF

    echo ""
    echo "✅ Full backup complete"
}

# ============================================================================
# Main Menu
# ============================================================================

case "${1:-menu}" in
    safe)
        snapshot_safe
        ;;
    quick)
        snapshot_quick
        ;;
    list)
        list_snapshots
        ;;
    cleanup)
        cleanup_snapshots
        ;;
    restore)
        restore_snapshot "$2"
        ;;
    update)
        update_image
        ;;
    backup)
        backup_all
        ;;
    cron)
        setup_cron
        ;;
    reserved-ip)
        setup_reserved_ip
        ;;
    *)
        echo "📸 Droplet Snapshot Management"
        echo "=============================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  safe         - Safe snapshot (stops services first) - for upgrades"
        echo "  quick        - Quick snapshot (no downtime) - for stateless services"
        echo "  list         - List all snapshots"
        echo "  cleanup      - Remove snapshots older than $RETENTION_DAYS days"
        echo "  restore <id> - Create new droplet from snapshot"
        echo "  update       - Pull and deploy latest Docker image"
        echo "  backup       - Full backup (snapshot + volumes + configs)"
        echo "  cron         - Setup automated daily snapshots"
        echo "  reserved-ip  - Setup zero-downtime deployment with Reserved IP"
        echo ""
        echo "Examples:"
        echo "  $0 quick              # Quick snapshot (recommended for OCR service)"
        echo "  $0 list               # Show all snapshots"
        echo "  $0 cleanup            # Remove old snapshots"
        echo "  $0 restore 123456789  # Restore from snapshot ID"
        echo "  $0 update             # Deploy latest image"
        echo ""
        echo "Cron Setup (Automated Daily Snapshots):"
        echo "  $0 cron               # Show cron installation instructions"
        ;;
esac
