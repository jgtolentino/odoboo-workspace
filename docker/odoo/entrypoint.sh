#!/usr/bin/env bash
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -d "postgres" -c '\q' 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "PostgreSQL is up - executing command"

# Execute Odoo with configuration
# Pass through all command arguments (e.g., --longpolling-port)
if [ $# -eq 0 ]; then
  # No arguments provided, use default
  exec /usr/bin/odoo -c /etc/odoo/odoo.conf
else
  # Arguments provided (e.g., from compose.yaml command:), use them
  exec "$@"
fi
