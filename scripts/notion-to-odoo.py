#!/usr/bin/env python3
"""
Notion to Odoo Migration Script
Imports Notion HTML pages and CSV databases into Odoo 18

Usage:
    export ODOO_URL="https://insightpulseai.net"
    export ODOO_DB="insightpulse_prod"
    export ODOO_USER="admin@example.com"
    export ODOO_PASS="your-password"
    python3 notion-to-odoo.py notion-export-1.zip [notion-export-2.zip ...]
"""

import zipfile
import csv
import re
import os
import sys
import base64
from xmlrpc import client as xc
from html import unescape

# Configuration from environment
URL = os.getenv("ODOO_URL", "https://insightpulseai.net")
DB = os.getenv("ODOO_DB", "insightpulse_prod")
USER = os.getenv("ODOO_USER", "admin@example.com")
PASS = os.getenv("ODOO_PASS")

if not PASS:
    print("ERROR: ODOO_PASS environment variable not set")
    sys.exit(1)


def login():
    """Authenticate with Odoo and return UID + models proxy"""
    common = xc.ServerProxy(f"{URL}/xmlrpc/2/common")
    uid = common.authenticate(DB, USER, PASS, {})
    if not uid:
        raise SystemExit("❌ Authentication failed. Check ODOO_USER and ODOO_PASS.")
    models = xc.ServerProxy(f"{URL}/xmlrpc/2/object")
    print(f"✅ Authenticated as user ID {uid}")
    return uid, models


def upsert(models, uid, model, domain, vals):
    """Create or update a record"""
    ids = models.execute_kw(DB, uid, PASS, model, 'search', [domain], {'limit': 1})
    if ids:
        models.execute_kw(DB, uid, PASS, model, 'write', [ids, vals])
        return ids[0]
    return models.execute_kw(DB, uid, PASS, model, 'create', [vals])


def extract_title_and_body(html_bytes):
    """Extract title and body HTML from Notion export"""
    s = html_bytes.decode('utf-8', errors='ignore')

    # Extract title
    t = re.search(r'<title>(.*?)</title>', s, flags=re.I | re.S)
    title = unescape(t.group(1).strip()) if t else "Untitled"

    # Extract body content
    body = re.search(r'<body[^>]*>(.*)</body>', s, flags=re.I | re.S)
    content = body.group(1).strip() if body else s

    return title, content


# Map Notion statuses to Odoo project stages
TASK_STAGE_MAP = {
    "Backlog": "New",
    "Todo": "New",
    "To Do": "New",
    "In Progress": "In Progress",
    "Doing": "In Progress",
    "Review": "In Review",
    "In Review": "In Review",
    "Done": "Done",
    "Completed": "Done",
    "Closed": "Done"
}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    uid, models = login()

    # Ensure default project stages exist
    print("\n📊 Creating project stages...")
    stage_ids = {}
    for name in ["New", "In Progress", "In Review", "Done"]:
        stage_ids[name] = upsert(
            models, uid,
            'project.task.type',
            [('name', '=', name)],
            {'name': name}
        )
    print(f"✅ Created {len(stage_ids)} project stages")

    # Create wiki root (document.page)
    print("\n📚 Creating wiki root...")
    wiki_root_id = upsert(
        models, uid,
        'document.page',
        [('name', '=', 'Notion Import')],
        {'name': 'Notion Import'}
    )
    print(f"✅ Wiki root created (ID: {wiki_root_id})")

    # Process each ZIP file
    total_pages = 0
    total_projects = 0
    total_tasks = 0

    for zip_path in sys.argv[1:]:
        print(f"\n📦 Processing {os.path.basename(zip_path)}...")

        with zipfile.ZipFile(zip_path) as zf:
            names = zf.namelist()

            # 1) PAGES → document.page
            html_files = [n for n in names if n.lower().endswith('.html')]
            print(f"📄 Found {len(html_files)} HTML pages")

            for n in html_files:
                try:
                    title, content = extract_title_and_body(zf.read(n))
                    upsert(
                        models, uid,
                        'document.page',
                        [('name', '=', title), ('parent_id', '=', wiki_root_id)],
                        {
                            'name': title,
                            'content': content,
                            'parent_id': wiki_root_id
                        }
                    )
                    total_pages += 1
                    print(f"  ✅ {title}")
                except Exception as e:
                    print(f"  ⚠️  Failed to import {n}: {e}")

            # 2) DATABASES → project.project / project.task

            # Import Projects
            proj_csv = [n for n in names if 'table/projects.csv' in n.lower()]
            if proj_csv:
                print(f"\n🏗️  Found Projects CSV: {proj_csv[0]}")
                with zf.open(proj_csv[0]) as f:
                    reader = csv.DictReader(
                        (l.decode('utf-8', 'ignore') for l in f.readlines())
                    )
                    for row in reader:
                        name = (row.get('Name') or row.get('Project') or '').strip()
                        if not name:
                            continue
                        upsert(
                            models, uid,
                            'project.project',
                            [('name', '=', name)],
                            {'name': name}
                        )
                        total_projects += 1
                        print(f"  ✅ Project: {name}")

            # Import Tasks
            task_csv = [n for n in names if 'table/tasks.csv' in n.lower()]
            if task_csv:
                print(f"\n✓ Found Tasks CSV: {task_csv[0]}")

                # Build project name → ID map
                proj_ids = {}
                ids = models.execute_kw(
                    DB, uid, PASS,
                    'project.project',
                    'search',
                    [[('id', '>', 0)]]
                )
                recs = models.execute_kw(
                    DB, uid, PASS,
                    'project.project',
                    'read',
                    [ids, ['name']]
                )
                for r in recs:
                    proj_ids[r['name']] = r['id']

                with zf.open(task_csv[0]) as f:
                    reader = csv.DictReader(
                        (l.decode('utf-8', 'ignore') for l in f.readlines())
                    )
                    for row in reader:
                        name = (row.get('Name') or row.get('Task') or '').strip()
                        if not name:
                            name = 'Untitled'

                        proj = (row.get('Project') or row.get('Project Name') or '').strip()
                        status = (row.get('Status') or row.get('State') or '').strip()

                        # Map status to stage
                        stage_name = TASK_STAGE_MAP.get(status, "New")
                        stage = stage_ids.get(stage_name)

                        vals = {
                            'name': name,
                            'stage_id': stage
                        }

                        # Link to project if found
                        if proj and proj in proj_ids:
                            vals['project_id'] = proj_ids[proj]

                        upsert(
                            models, uid,
                            'project.task',
                            [
                                ('name', '=', name),
                                ('project_id', '=', vals.get('project_id') or False)
                            ],
                            vals
                        )
                        total_tasks += 1
                        print(f"  ✅ Task: {name} ({status} → {stage_name})")

    # Summary
    print("\n" + "=" * 60)
    print("✅ Import complete!")
    print(f"📄 Pages imported: {total_pages}")
    print(f"🏗️  Projects created: {total_projects}")
    print(f"✓ Tasks created: {total_tasks}")
    print("=" * 60)
    print(f"\n🌐 Access your data at: {URL}")
    print("   - Wiki: Knowledge → Notion Import")
    print("   - Projects: Project → All Projects")
    print("   - Tasks: Project → All Tasks")


if __name__ == "__main__":
    main()
