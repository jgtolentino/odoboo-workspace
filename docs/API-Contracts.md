# API Contracts

## Edge Function `work-queue`

- POST `/enqueue` → { id }
- POST `/claim` { worker } → { task|null }
- POST `/comment` { work_queue_id, author_kind, message } → { ok }
- POST `/complete` { id, status, result } → { ok }

## Next.js API proxies (server-only SRK)

- POST `/api/wq/comment` → forwards to Edge.
- POST `/api/wq/complete` → forwards to Edge.

## Webhook (DB → Vercel)

- Path: `/api/hooks/task-comment`
- Header: `x-webhook-secret`
- Body: `{ id, work_queue_id, author_kind, message, created_at }`
