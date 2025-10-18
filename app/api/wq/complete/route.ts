import { NextResponse } from 'next/server';

const SUPABASE_PROJECT_REF = 'spdtwktxdalcfigzeqrz';
const EDGE_FUNCTION_URL = `https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/work-queue`;

export async function POST(req: Request) {
  try {
    const body = await req.json();

    // Forward to Supabase Edge Function
    const response = await fetch(`${EDGE_FUNCTION_URL}/complete`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: 'Edge Function error' }, { status: response.status });
    }

    const result = await response.json();
    return NextResponse.json(result);
  } catch (error) {
    console.error('Error forwarding to Edge Function:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
