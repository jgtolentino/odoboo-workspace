# frontend:apps-catalog

## GOAL

Finish Odoo-like catalog with counts and Install/Open.

## ACCEPTANCE

- /apps renders category counts from view
- Install posts to /api/install and redirects back
- no console warnings; pnpm build passes

## FILES

app/apps/page.tsx
components/AppCard.tsx
app/api/install/route.ts

## GUARDS

do not touch /supabase/**
do not edit /migrations/**
no env leakage; client never uses service role

## VERIFY

visit /apps?cat=productivity shows counts and correct buttons
install toggles to Open for current user
