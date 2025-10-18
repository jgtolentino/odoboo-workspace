import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

console.log('Testing Supabase connection...');
console.log('URL:', process.env.SUPABASE_URL);
console.log('Service Role Key exists:', !!process.env.SUPABASE_SERVICE_ROLE_KEY);
console.log('Anon Key exists:', !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

// Test with a simple query
async function test() {
  try {
    const { data, error } = await sb.from('work_queue').select('*').limit(1);
    if (error) {
      console.error('Query error:', error);
    } else {
      console.log('Query successful:', data);
    }
  } catch (err) {
    console.error('Exception:', err);
  }
}

test();
