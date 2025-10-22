#!/usr/bin/env bash
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q' 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "PostgreSQL is up - executing command"

# Execute Odoo with configuration
# Note: Ignoring "$@" as the base image already sets the correct command
exec /usr/bin/odoo -c /etc/odoo/odoo.conf
