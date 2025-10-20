#!/usr/bin/env python3
"""
Bulk Import Data for Notion-Style Workspace
Imports Tasks, Calendar Events, Evidence Documents, and Knowledge Pages from CSV

Usage:
    # Copy CSVs to container first
    docker cp data/templates/*.csv odoo18:/tmp/

    # Then run import
    docker exec -i odoo18 odoo shell -d odoo_production < bulk-import-data.py
"""

import csv
import io
import base64
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

print("=" * 70)
print("  Bulk Import Data for Notion-Style Workspace")
print("=" * 70)
print()

def find_by_email(env, model, email):
    """Helper: Find record by email"""
    if not email or not email.strip():
        return False
    record = env[model].search([('email', '=', email.strip())], limit=1)
    return record.id if record else False

def find_by_name(env, model, name, domain=None):
    """Helper: Find record by name"""
    if not name or not name.strip():
        return False
    search_domain = [('name', '=', name.strip())]
    if domain:
        search_domain.extend(domain)
    record = env[model].search(search_domain, limit=1)
    return record.id if record else False

def parse_tags(env, tag_names):
    """Helper: Parse comma-separated tags and return [(6, 0, [ids])]"""
    if not tag_names:
        return []

    tag_ids = []
    for name in tag_names.split(','):
        name = name.strip()
        if not name:
            continue

        tag = env['project.tags'].search([('name', '=', name)], limit=1)
        if not tag:
            tag = env['project.tags'].create({'name': name})
            print(f"    Created tag: {name}")
        tag_ids.append(tag.id)

    return [(6, 0, tag_ids)] if tag_ids else []

def import_tasks(env, csv_path='/tmp/01_tasks_import_template.csv'):
    """Import tasks from CSV"""
    print("▶ Importing tasks...")

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                # Skip header row if present
                if row.get('name') == 'name':
                    continue

                # Find project
                project_id = find_by_name(env, 'project.project', row.get('project_id/name'))
                if not project_id:
                    print(f"  ⚠️  Project not found: {row.get('project_id/name')}, skipping task")
                    continue

                # Find user
                user_id = find_by_email(env, 'res.users', row.get('user_id/email'))

                # Find stage
                stage_id = find_by_name(env, 'project.task.type', row.get('stage_id/name'))

                # Parse tags
                tag_ids = parse_tags(env, row.get('tag_ids/name'))

                # Find knowledge page (if linked)
                knowledge_page_id = False
                if row.get('x_knowledge_page_id/name'):
                    knowledge_page_id = find_by_name(env, 'document.page', row.get('x_knowledge_page_id/name'))

                # Create task
                task_vals = {
                    'name': row.get('name'),
                    'project_id': project_id,
                    'user_id': user_id or False,
                    'date_deadline': row.get('date_deadline') or False,
                    'priority': row.get('priority', '0'),
                    'tag_ids': tag_ids,
                    'stage_id': stage_id or False,
                    'description': row.get('description') or '',
                    'planned_hours': float(row.get('planned_hours', 0)) if row.get('planned_hours') else 0,
                }

                # Add custom fields if they exist
                if row.get('x_area'):
                    task_vals['x_area'] = row.get('x_area')
                if row.get('x_evidence_url'):
                    task_vals['x_evidence_url'] = row.get('x_evidence_url')
                if knowledge_page_id:
                    task_vals['x_knowledge_page_id'] = knowledge_page_id

                task = env['project.task'].create(task_vals)
                count += 1
                print(f"  ✓ Created task: {task.name} (ID: {task.id})")

            env.cr.commit()
            print(f"✓ Imported {count} tasks\n")

    except FileNotFoundError:
        print(f"  ⚠️  File not found: {csv_path}")
        print(f"     Copy CSV files to container: docker cp data/templates/*.csv odoo18:/tmp/\n")
    except Exception as e:
        print(f"  ✗ Error importing tasks: {str(e)}\n")

def import_calendar_events(env, csv_path='/tmp/02_calendar_events_template.csv'):
    """Import calendar events from CSV"""
    print("▶ Importing calendar events...")

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                # Skip header row
                if row.get('name') == 'name':
                    continue

                # Parse attendees
                partner_ids = []
                if row.get('partner_ids/email'):
                    for email in row.get('partner_ids/email', '').split(','):
                        email = email.strip()
                        if email:
                            partner_id = find_by_email(env, 'res.partner', email)
                            if partner_id:
                                partner_ids.append(partner_id)

                # Parse event type
                categ_ids = []
                if row.get('categ_ids/name'):
                    for categ_name in row.get('categ_ids/name', '').split(','):
                        categ_name = categ_name.strip()
                        if categ_name:
                            categ_id = find_by_name(env, 'calendar.event.type', categ_name)
                            if categ_id:
                                categ_ids.append(categ_id)

                # Parse alarms
                alarm_ids = []
                if row.get('alarm_ids/name'):
                    for alarm_name in row.get('alarm_ids/name', '').split(','):
                        alarm_name = alarm_name.strip()
                        if alarm_name:
                            alarm_id = find_by_name(env, 'calendar.alarm', alarm_name)
                            if alarm_id:
                                alarm_ids.append(alarm_id)

                # Create event
                event_vals = {
                    'name': row.get('name'),
                    'start': row.get('start'),
                    'stop': row.get('stop'),
                    'allday': str(row.get('allday', '')).upper() in ('TRUE', '1', 'YES'),
                    'location': row.get('location', ''),
                    'description': row.get('description', ''),
                    'partner_ids': [(6, 0, partner_ids)] if partner_ids else [],
                    'categ_ids': [(6, 0, categ_ids)] if categ_ids else [],
                    'alarm_ids': [(6, 0, alarm_ids)] if alarm_ids else [],
                }

                event = env['calendar.event'].create(event_vals)
                count += 1
                print(f"  ✓ Created event: {event.name} on {row.get('start')}")

            env.cr.commit()
            print(f"✓ Imported {count} calendar events\n")

    except FileNotFoundError:
        print(f"  ⚠️  File not found: {csv_path}\n")
    except Exception as e:
        print(f"  ✗ Error importing calendar events: {str(e)}\n")

def import_evidence_documents(env, csv_path='/tmp/03_evidence_repository_template.csv'):
    """Import evidence documents from CSV"""
    print("▶ Importing evidence documents...")

    # Check if DMS is installed
    if not env['ir.module.module'].search([('name', '=', 'dms'), ('state', '=', 'installed')]):
        print("  ⚠️  DMS module not installed, skipping evidence import\n")
        return

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                # Skip header row
                if row.get('name') == 'name':
                    continue

                # Find directory
                directory_id = find_by_name(env, 'dms.directory', row.get('directory_id/name'))
                if not directory_id:
                    print(f"  ⚠️  Directory not found: {row.get('directory_id/name')}, skipping document")
                    continue

                # Find owner
                owner_id = find_by_email(env, 'res.users', row.get('owner_id/email'))

                # Parse tags
                tag_ids = []
                if row.get('tag_ids/name'):
                    for tag_name in row.get('tag_ids/name', '').split(','):
                        tag_name = tag_name.strip()
                        if tag_name:
                            # DMS uses different tag model
                            tag = env['dms.tag'].search([('name', '=', tag_name)], limit=1)
                            if not tag:
                                tag = env['dms.tag'].create({'name': tag_name})
                            tag_ids.append(tag.id)

                # Create document
                doc_vals = {
                    'name': row.get('name'),
                    'directory_id': directory_id,
                    'owner_id': owner_id or False,
                    'description': row.get('description', ''),
                    'tag_ids': [(6, 0, tag_ids)] if tag_ids else [],
                }

                # Add URL if provided
                if row.get('url'):
                    doc_vals['url'] = row.get('url')

                if row.get('mimetype'):
                    doc_vals['mimetype'] = row.get('mimetype')

                # Add custom fields if they exist
                if row.get('x_task_id/name'):
                    task_id = find_by_name(env, 'project.task', row.get('x_task_id/name'))
                    if task_id:
                        doc_vals['x_task_id'] = task_id

                if row.get('x_compliance_area'):
                    doc_vals['x_compliance_area'] = row.get('x_compliance_area')

                doc = env['dms.document'].create(doc_vals)
                count += 1
                print(f"  ✓ Created document: {doc.name}")

            env.cr.commit()
            print(f"✓ Imported {count} evidence documents\n")

    except FileNotFoundError:
        print(f"  ⚠️  File not found: {csv_path}\n")
    except Exception as e:
        print(f"  ✗ Error importing evidence documents: {str(e)}\n")

def import_knowledge_pages(env, csv_path='/tmp/04_knowledge_pages_template.csv'):
    """Import knowledge pages from CSV"""
    print("▶ Importing knowledge pages...")

    # Check if document_page is installed
    if not env['ir.module.module'].search([('name', '=', 'document_page'), ('state', '=', 'installed')]):
        print("  ⚠️  document_page module not installed, skipping knowledge import\n")
        return

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                # Skip header row
                if row.get('name') == 'name':
                    continue

                # Find parent page
                parent_id = False
                if row.get('parent_id/name'):
                    parent_id = find_by_name(env, 'document.page', row.get('parent_id/name'))

                # Find owner
                owner_id = find_by_email(env, 'res.users', row.get('owner_id/email'))

                # Parse tags
                tag_ids = []
                if row.get('tag_ids/name'):
                    for tag_name in row.get('tag_ids/name', '').split(','):
                        tag_name = tag_name.strip()
                        if tag_name:
                            # Create tag if doesn't exist
                            tag = env['document.page.tag'].search([('name', '=', tag_name)], limit=1)
                            if not tag:
                                tag = env['document.page.tag'].create({'name': tag_name})
                            tag_ids.append(tag.id)

                # Create page
                page_vals = {
                    'name': row.get('name'),
                    'parent_id': parent_id or False,
                    'content': row.get('content', ''),
                    'type': 'content',
                    'tag_ids': [(6, 0, tag_ids)] if tag_ids else [],
                }

                if owner_id:
                    page_vals['owner_id'] = owner_id

                if row.get('summary'):
                    page_vals['summary'] = row.get('summary')

                page = env['document.page'].create(page_vals)
                count += 1
                print(f"  ✓ Created page: {page.name}")

            env.cr.commit()
            print(f"✓ Imported {count} knowledge pages\n")

    except FileNotFoundError:
        print(f"  ⚠️  File not found: {csv_path}\n")
    except Exception as e:
        print(f"  ✗ Error importing knowledge pages: {str(e)}\n")

# Main execution
if __name__ != '__main__':
    # Running inside odoo shell
    import_tasks(env)
    import_calendar_events(env)
    import_evidence_documents(env)
    import_knowledge_pages(env)

    print("=" * 70)
    print("  ✓ Bulk Import Complete!")
    print("=" * 70)
    print("\nNext steps:")
    print("  1. Run setup-workflows.py to configure email alerts")
    print("  2. Access Odoo at https://insightpulseai.net:8069")
    print("  3. Navigate to Project → Compliance & Month-End to see tasks")
    print()
