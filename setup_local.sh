#!/usr/bin/env bash
# Simple local Odoo setup - NO SSH, NO CI/CD bullshit
# Just run: ./setup_local.sh

docker exec -i odoo18 odoo -d insightpulse_prod \
  -i base,web,project,mail,hr,hr_expense,crm,sale,sale_management,purchase,stock,account,calendar,contacts,website,knowledge,documents \
  --without-demo=all \
  --stop-after-init

docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PYEOF'
env = env.sudo()
user = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')],limit=1)
if not user:
    user = env['res.users'].create({'name':'Admin','login':'jgtolentino_rn@yahoo.com','password':'admin123','groups_id':[(6,0,[env.ref('base.group_system').id])]})
else:
    user.password='admin123'
    user.groups_id=[(4,env.ref('base.group_system').id)]

proj = env['project.project'].search([('name','=','CI/CD Pipeline')],limit=1)
if not proj:
    proj = env['project.project'].create({'name':'CI/CD Pipeline','privacy_visibility':'followers'})

stages = ['Backlog','Spec Review','In PR','CI Green','Staging ✅','Ready for Prod','Deployed','Blocked']
for s in stages:
    if not env['project.task.type'].search([('name','=',s),('project_ids','in',proj.id)],limit=1):
        env['project.task.type'].create({'name':s,'project_ids':[(4,proj.id)]})

IrModelFields = env['ir.model.fields']
task_model_id = env['ir.model']._get_id('project.task')
def add_field(n,d,t,**k):
    if not IrModelFields.search([('model','=','project.task'),('name','=',n)],limit=1):
        v={'name':n,'model_id':task_model_id,'field_description':d,'ttype':t,'store':True}
        v.update(k)
        IrModelFields.create(v)

add_field('x_pr_number','PR Number','integer')
add_field('x_pr_url','PR URL','char',size=512)
add_field('x_repo','Repository','char',size=256)
add_field('x_build_status','Build Status','selection',selection="[('queued','Queued'),('running','Running'),('passed','Passed'),('failed','Failed')]")
add_field('x_env','Environment','selection',selection="[('preview','Preview'),('staging','Staging'),('prod','Production')]")

ch = env['discuss.channel'].search([('name','=','ci-updates')],limit=1)
if not ch:
    ch = env['discuss.channel'].create({'name':'ci-updates','channel_type':'channel','description':'CI/CD notifications'})
    ch.message_post(body='<p>🤖 SuperClaude Ready</p>',message_type='comment')

env.cr.commit()
print("\n✅ DONE - Login at http://localhost:8069")
print("Email: jgtolentino_rn@yahoo.com")
print("Password: admin123\n")
PYEOF
