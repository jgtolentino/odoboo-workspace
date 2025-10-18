# frontend:tasks-thread

## GOAL

Build /tasks/[id] page as comms hub bound to work_queue and work_queue_comment.

## ACCEPTANCE

- Two-pane layout: left task meta/status; right realtime comments feed
- Subscribe to work_queue_comment by work_queue_id; new messages appear within 1s
- Post comment from UI (authenticated) without page reload
- No client service-role usage; zero console warnings

## FILES

app/tasks/[id]/page.tsx
components/task/CommentList.tsx
components/task/CommentForm.tsx
lib/realtime.ts
app/api/tasks/[id]/route.ts

## GUARDS

Client uses anon key only
Server route /api/tasks/[id] may use service role to fetch task meta
Do not edit DB or RLS

## VERIFY

Open two browsers on /tasks/1; comments stream bidirectionally
pnpm build clean
