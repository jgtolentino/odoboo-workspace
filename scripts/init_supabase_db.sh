#!/bin/bash
# init_supabase_db.sh - Initialize Odoo database on Supabase using Python

echo "Creating Odoo database on Supabase..."

docker exec -i odoo18 python3 << 'PYTHON_SCRIPT'
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import os

# Supabase connection details
HOST = "aws-1-us-east-1.pooler.supabase.com"
PORT = "5432"
USER = "postgres.spdtwktxdalcfigzeqrz"
PASSWORD = "SHWYXDMFAwXI1drT"
DBNAME = "postgres"  # Connect to default database first

try:
    # Connect to PostgreSQL server
    connection = psycopg2.connect(
        user=USER,
        password=PASSWORD,
        host=HOST,
        port=PORT,
        dbname=DBNAME,
        sslmode="require"
    )
    connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

    cursor = connection.cursor()

    # Create odoo_workspace database if not exists
    cursor.execute("SELECT 1 FROM pg_database WHERE datname = 'notion_workspace'")
    exists = cursor.fetchone()

    if not exists:
        print("Creating database 'notion_workspace'...")
        cursor.execute("CREATE DATABASE notion_workspace")
        print("✅ Database 'notion_workspace' created successfully!")
    else:
        print("ℹ️  Database 'notion_workspace' already exists")

    # Update admin user credentials if needed
    cursor.execute("SELECT 1 FROM pg_database WHERE datname = 'notion_workspace'")
    cursor.close()
    connection.close()

    # Now connect to the new database to set up admin user
    connection = psycopg2.connect(
        user=USER,
        password=PASSWORD,
        host=HOST,
        port=PORT,
        dbname="notion_workspace",
        sslmode="require"
    )
    cursor = connection.cursor()

    # Check if res_users table exists
    cursor.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'res_users'
        )
    """)
    table_exists = cursor.fetchone()[0]

    if table_exists:
        print("Updating admin user credentials...")
        cursor.execute("""
            UPDATE res_users
            SET login = 'jgtolentino_rn@yahoo.com', password = 'Postgres_26'
            WHERE id = 2
        """)
        connection.commit()
        print("✅ Admin credentials updated!")
    else:
        print("ℹ️  Database structure not yet initialized (will be done by Odoo)")

    cursor.close()
    connection.close()
    print("✅ Connection successful and closed.")

except Exception as e:
    print(f"❌ Failed to connect: {e}")
    exit(1)

PYTHON_SCRIPT

echo "✅ Database initialization complete!"
echo "🌐 Opening Odoo at http://localhost:8069"
open http://localhost:8069
