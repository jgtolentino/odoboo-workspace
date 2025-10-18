import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    switch (path) {
      case 'enqueue':
        return await handleEnqueue(req, supabase);
      case 'claim':
        return await handleClaim(req, supabase);
      case 'comment':
        return await handleComment(req, supabase);
      case 'complete':
        return await handleComplete(req, supabase);
      default:
        return new Response(JSON.stringify({ error: 'Not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
  } catch (error) {
    console.error('Edge Function error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

async function handleEnqueue(req: Request, supabase: any) {
  const { kind, prompt } = await req.json();

  const { data, error } = await supabase
    .from('work_queue')
    .insert({
      kind,
      prompt_json: prompt,
      status: 'PENDING',
    })
    .select()
    .single();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ id: data.id }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function handleClaim(req: Request, supabase: any) {
  const { worker } = await req.json();

  // Claim the next PENDING task
  const { data, error } = await supabase.rpc('claim_task', { p_worker: worker });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function handleComment(req: Request, supabase: any) {
  const { work_queue_id, author_kind, message, author_id } = await req.json();

  const { error } = await supabase.from('work_queue_comment').insert({
    work_queue_id,
    author_kind,
    author_id: author_id || null,
    message,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function handleComplete(req: Request, supabase: any) {
  const { id, status, result } = await req.json();

  const { error } = await supabase
    .from('work_queue')
    .update({
      status,
      result_json: result,
      completed_at: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
