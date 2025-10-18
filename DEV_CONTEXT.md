# Stack

Next.js App Router, TS, Tailwind, Supabase client in `lib/supabase.ts`.

# Data

Tables: app_category(id,name,slug), app(id,name,summary,icon,category_id,install_path), app_install(app_id,user_id,status,user_id=auth.uid()).

# Routes

/apps – catalog grid
/api/install – upsert into app_install
/auth – Supabase Auth (email OTP)

# UI Rules

- Do not fetch with service role on client.
- Use server components for data lists. Client components only for interactivity.
- Card: icon, title, summary, Install/Open button.

# Commands

pnpm dev | pnpm build | pnpm test
