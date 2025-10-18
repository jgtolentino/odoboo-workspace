# Module Matrix (Parity Plan)

| Enterprise Area | Our Implementation                                 | OCA/Odoo Parallels                  | Notes                                                    |
| --------------- | -------------------------------------------------- | ----------------------------------- | -------------------------------------------------------- |
| Knowledge       | `knowledge_page`, tags, history, realtime comments | OCA document_page\*, Odoo Knowledge | Pages + public access_level; Supabase Storage for files. |
| Projects        | project/task/kanban/timesheet                      | Odoo Project/Timesheets             | Liveblocks presence (optional) for cursors.              |
| Documents       | Supabase Storage buckets + policies                | Odoo Documents                      | Buckets: public, private; signed URLs.                   |
| Expenses        | hr_expense + rate cards + mappings                 | Odoo Expenses                       | Concur-ready export DTO + queue.                         |
| Apps Catalog    | `app_*` tables, grid UI                            | Odoo Apps                           | Install/Open state per user.                             |
| Comms Hub       | `work_queue` + `work_queue_comment`                | Discuss/Activities                  | DB→Vercel webhook → in-app feed.                         |
| Billing         | Stripe Wrapper + plans/seats                       | Odoo Subscriptions                  | Seats enforced via RLS/limits.                           |
