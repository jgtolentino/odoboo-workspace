import { sbServer } from '@/utils/supabase/server';
import { notFound } from 'next/navigation';
import { CommentList } from '@/components/task/CommentList';
import { CommentForm } from '@/components/task/CommentForm';

interface TaskPageProps {
  params: {
    id: string;
  };
}

export default async function TaskPage({ params }: TaskPageProps) {
  const supabase = await sbServer();

  // Fetch task metadata
  const { data: task, error } = await supabase
    .from('work_queue')
    .select('*')
    .eq('id', params.id)
    .single();

  if (error || !task) {
    notFound();
  }

  // Fetch initial comments
  const { data: comments } = await supabase
    .from('work_queue_comment')
    .select('*')
    .eq('work_queue_id', params.id)
    .order('created_at', { ascending: true });

  return (
    <div className="container mx-auto p-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Pane - Task Metadata */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow p-6">
            <h1 className="text-2xl font-bold mb-4">Task #{task.id}</h1>
            <div className="space-y-4">
              <div>
                <h3 className="font-semibold text-gray-700">Status</h3>
                <p className="text-sm text-gray-600">{task.status}</p>
              </div>
              <div>
                <h3 className="font-semibold text-gray-700">Kind</h3>
                <p className="text-sm text-gray-600">{task.kind}</p>
              </div>
              <div>
                <h3 className="font-semibold text-gray-700">Created</h3>
                <p className="text-sm text-gray-600">
                  {new Date(task.created_at).toLocaleString()}
                </p>
              </div>
              {task.claimed_by && (
                <div>
                  <h3 className="font-semibold text-gray-700">Claimed By</h3>
                  <p className="text-sm text-gray-600">{task.claimed_by}</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Pane - Comments Feed */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow">
            <div className="p-6 border-b">
              <h2 className="text-xl font-semibold">Comments</h2>
            </div>

            {/* Comments List */}
            <div className="p-6">
              <CommentList taskId={params.id} initialComments={comments || []} />
            </div>

            {/* Comment Form */}
            <div className="p-6 border-t">
              <CommentForm taskId={params.id} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
