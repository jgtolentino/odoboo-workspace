#!/usr/bin/env bash
set -euo pipefail

# Create backup directory
mkdir -p /opt/odoobo/backup

# Install cron jobs
cat >/etc/cron.d/odoobo_backup <<'CRON'
# Database backup (nightly at 2 AM)
0 2 * * * root cd /opt/odoobo && docker compose exec -T db pg_dump -U odoo -Fc insightpulseai.net > /opt/odoobo/backup/db_$(date +\%F).dump

# Filestore backup (nightly at 2:15 AM)
15 2 * * * root tar -C /var/lib/docker/volumes -czf /opt/odoobo/backup/filestore_$(date +\%F).tgz $(docker volume ls -q | grep odoobo_odoo-data)

# Cleanup old backups (keep 14 days)
30 3 * * * root find /opt/odoobo/backup -name "db_*.dump" -mtime +14 -delete
30 3 * * * root find /opt/odoobo/backup -name "filestore_*.tgz" -mtime +14 -delete
CRON

chmod 644 /etc/cron.d/odoobo_backup

echo "✅ Backup cron jobs installed"
echo "Backups will run nightly at 2 AM (database) and 2:15 AM (filestore)"
echo "Retention: 14 days"
