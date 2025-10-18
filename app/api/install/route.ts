import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(req: Request) {
  const body = await req.formData();
  const app_id = Number(body.get('app_id'));

  // TODO: get the user id from your auth (e.g., supabase-auth-helpers)
  // For now, we'll use a placeholder user_id in UUID format
  const user_id = '00000000-0000-0000-0000-000000000000'; // Replace with actual auth user ID

  if (!user_id) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const { error } = await supabase.from('app_install').upsert({
    app_id,
    user_id,
    installed_at: new Date().toISOString(),
  });

  if (error) {
    console.error('Install error:', error);
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.redirect(new URL('/apps', req.url));
}
