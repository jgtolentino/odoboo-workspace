import fs from 'node:fs/promises';
import path from 'path';

const SUPABASE_PROJECT_REF = 'spdtwktxdalcfigzeqrz';
const EDGE_FUNCTION_URL = `https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/work-queue`;
const WORKER_ID = 'cline';

async function claim() {
  const response = await fetch(`${EDGE_FUNCTION_URL}/claim`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ worker: WORKER_ID }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Claim failed: ${error}`);
  }

  return await response.json();
}

async function postComment(taskId, message) {
  const response = await fetch(`${EDGE_FUNCTION_URL}/comment`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      work_queue_id: taskId,
      author_kind: 'cline',
      message,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('Failed to post comment:', error);
  }
}

async function completeTask(taskId, result) {
  const response = await fetch(`${EDGE_FUNCTION_URL}/complete`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      id: taskId,
      status: 'DONE',
      result,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('Failed to complete task:', error);
  }
}

async function runOnce() {
  const task = await claim();
  if (!task || !task.id) return;
  
  const dir = path.join('.cline', 'tasks'); 
  await fs.mkdir(dir, { recursive: true });
  const file = path.join(dir, `task-${task.id}.md`);
  const p = task.prompt_json;
  
  const md = `# ${task.kind}\n\n## GOAL\n${p.goal}\n\n## ACCEPTANCE\n${p.acceptance?.map(x=>`- ${x}`).join('\n')}\n\n## FILES\n${p.files?.join('\n')}\n\n## GUARDS\n${p.guards?.join('\n')}\n\n## VERIFY\n${p.verify?.join('\n')}\n`;
  await fs.writeFile(file, md, 'utf8');
  
  // Post initial progress comment
  await postComment(task.id, `Task claimed and task file created: ${file}`);
  
  console.log('Wrote', file, 'Open it and run Cline task.');
  console.log('Progress comment posted to task thread.');
}

runOnce().catch(e => { console.error(e); process.exit(1); });
