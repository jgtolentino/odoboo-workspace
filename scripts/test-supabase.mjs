import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testConnection() {
  try {
    console.log('Testing Supabase connection...');
    
    // Test basic query to verify connection
    const { data, error } = await sb.from('work_queue').select('count').limit(1);
    
    if (error) {
      console.error('Error querying work_queue:', error);
      return;
    }
    
    console.log('✅ Successfully connected to Supabase');
    console.log('work_queue query result:', data);
    
  } catch (error) {
    console.error('Connection failed:', error);
  }
}

testConnection();
