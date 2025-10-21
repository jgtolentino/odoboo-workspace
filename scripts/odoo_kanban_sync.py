#!/usr/bin/env python3
"""
Sync CI/CD events to Odoo Kanban + Discuss
Your Own Slack = Odoo Discuss + Kanban

Usage:
    python scripts/odoo_kanban_sync.py pr_opened < payload.json
    python scripts/odoo_kanban_sync.py ci_pass < payload.json
    python scripts/odoo_kanban_sync.py deploy_staging < payload.json
"""
import os
import sys
import json
import xmlrpc.client
from datetime import datetime

# Configuration from environment
ODOO_URL = os.getenv("ODOO_URL", "https://insightpulseai.net")
ODOO_DB = os.getenv("ODOO_DATABASE", "odoboo_prod")
ODOO_USER = os.getenv("ODOO_USER", "admin@insightpulseai.net")
ODOO_API_KEY = os.getenv("ODOO_API_KEY")

if not ODOO_API_KEY:
    print("❌ ODOO_API_KEY not set", file=sys.stderr)
    sys.exit(1)

# Authenticate
common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_API_KEY, {})

if not uid:
    print("❌ Odoo authentication failed", file=sys.stderr)
    sys.exit(1)

models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")


def execute(model, method, *args, **kwargs):
    """Execute Odoo RPC call"""
    return models.execute_kw(ODOO_DB, uid, ODOO_API_KEY, model, method, args, kwargs)


def get_or_create_project(name):
    """Get or create CI/CD project"""
    project_ids = execute('project.project', 'search', [('name', '=', name)])

    if project_ids:
        return project_ids[0]

    # Create project
    project_id = execute('project.project', 'create', {
        'name': name,
        'description': 'Automated CI/CD pipeline tracking',
        'privacy_visibility': 'portal',  # Visible to clients
    })

    # Create stages
    stages = [
        'Backlog',
        'Spec Review',
        'In PR',
        'CI Green',
        'Staging ✅',
        'Ready for Prod',
        'Deployed',
        'Blocked',
    ]

    for sequence, stage_name in enumerate(stages):
        execute('project.task.type', 'create', {
            'name': stage_name,
            'project_ids': [(6, 0, [project_id])],
            'sequence': sequence,
            'fold': stage_name in ['Deployed', 'Blocked'],
        })

    return project_id


def get_stage_id(project_id, stage_name):
    """Get stage ID by name"""
    stage_ids = execute('project.task.type', 'search', [
        ('name', '=', stage_name),
        ('project_ids', 'in', [project_id])
    ])

    return stage_ids[0] if stage_ids else None


def get_or_create_task(pr_number, repo, project_id):
    """Get or create Kanban task for PR"""
    # Search for existing task
    task_ids = execute('project.task', 'search', [
        ('x_pr_number', '=', pr_number),
        ('x_repo', '=', repo),
    ])

    if task_ids:
        return task_ids[0]

    # Create new task
    task_id = execute('project.task', 'create', {
        'name': f'PR #{pr_number}',
        'x_pr_number': pr_number,
        'x_pr_url': f'https://github.com/{repo}/pull/{pr_number}',
        'x_repo': repo,
        'project_id': project_id,
        'stage_id': get_stage_id(project_id, 'In PR'),
    })

    return task_id


def update_task_stage(task_id, stage_name, build_status=None, env=None):
    """Move task to new stage"""
    project_id = execute('project.task', 'read', [task_id], ['project_id'])[0]['project_id'][0]

    vals = {'stage_id': get_stage_id(project_id, stage_name)}

    if build_status:
        vals['x_build_status'] = build_status

    if env:
        vals['x_env'] = env

    execute('project.task', 'write', [task_id], vals)


def post_to_discuss(channel_name, message):
    """Post message to Odoo Discuss channel"""
    # Get or create channel (Odoo 18 uses discuss.channel, not mail.channel)
    channel_ids = execute('discuss.channel', 'search', [('name', '=', channel_name)])

    if not channel_ids:
        channel_id = execute('discuss.channel', 'create', {
            'name': channel_name,
            'channel_type': 'channel',
            'public': 'public',
            'description': 'CI/CD pipeline updates (Your Own Slack)',
        })
    else:
        channel_id = channel_ids[0]

    # Post message
    execute('discuss.channel', 'message_post', channel_id, {
        'body': message,
        'message_type': 'comment',
        'subtype_xmlid': 'mail.mt_comment',
    })


def format_message(event, payload):
    """Format message for Discuss"""
    pr = payload.get('pr_number', '?')
    repo = payload.get('repo', 'unknown')
    author = payload.get('author', 'unknown')

    messages = {
        'pr_opened': f'🔵 <b>PR #{pr}</b> opened by {author}',
        'pr_sync': f'🔄 <b>PR #{pr}</b> updated',
        'ci_pass': f'✅ <b>CI passed</b> for PR #{pr}',
        'ci_fail': f'❌ <b>CI failed</b> for PR #{pr}<br/>{payload.get("error", "")}',
        'deploy_staging': f'🚀 <b>Deployed to staging</b>: <a href="{payload.get("url", "")}">{payload.get("url", "")}</a>',
        'deploy_prod': f'🎉 <b>Deployed to production</b> (tag {payload.get("tag", "?")})',
        'blocked': f'🚫 <b>Blocked</b>: PR #{pr} - {payload.get("reason", "Unknown")}',
    }

    return messages.get(event, f'ℹ️ Event: {event}')


def main():
    if len(sys.argv) < 2:
        print("Usage: odoo_kanban_sync.py <event> < payload.json", file=sys.stderr)
        sys.exit(1)

    event = sys.argv[1]
    payload = json.load(sys.stdin)

    pr_number = payload.get('pr_number')
    repo = payload.get('repo', os.getenv('GITHUB_REPOSITORY', 'unknown'))

    # Get or create project
    project_id = get_or_create_project('CI/CD Pipeline')

    # Get or create task
    if pr_number:
        task_id = get_or_create_task(pr_number, repo, project_id)
    else:
        task_id = None

    # Handle events
    if event == 'pr_opened':
        if task_id:
            update_task_stage(task_id, 'In PR', build_status='queued')

    elif event == 'pr_sync':
        if task_id:
            update_task_stage(task_id, 'In PR', build_status='queued')

    elif event == 'ci_pass':
        if task_id:
            update_task_stage(task_id, 'CI Green', build_status='passed')

    elif event == 'ci_fail':
        if task_id:
            update_task_stage(task_id, 'Blocked', build_status='failed')

    elif event == 'deploy_staging':
        if task_id:
            update_task_stage(task_id, 'Staging ✅', env='staging')

    elif event == 'deploy_prod':
        if task_id:
            update_task_stage(task_id, 'Deployed', env='production')

    elif event == 'blocked':
        if task_id:
            update_task_stage(task_id, 'Blocked')

    # Post to Discuss channel (Your Own Slack)
    message = format_message(event, payload)
    post_to_discuss('#ci-updates', message)

    print(f"✅ Updated Odoo: task {task_id} → {event}")
    print(f"✅ Posted to #ci-updates")


if __name__ == '__main__':
    main()
