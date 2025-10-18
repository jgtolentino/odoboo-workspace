# frontend:worker-hooks

## GOAL

Add client APIs for Cline worker: POST /api/wq/comment and /api/wq/complete that proxy to the Supabase Edge Function.

## ACCEPTANCE

- /api/wq/comment forwards {work_queue_id, author_kind, message}
- /api/wq/complete forwards {id, status, result}
- Environment uses service role only on server

## FILES

app/api/wq/comment/route.ts
app/api/wq/complete/route.ts

## GUARDS

No DB writes from client for these endpoints
Read Edge Function base URL from env SUPABASE_PROJECT_REF

## VERIFY

curl hits return 200
