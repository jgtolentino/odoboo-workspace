'use client';

import { useEffect, useState } from 'react';
import { sb } from '@/utils/supabase/client';
import type { Database } from '@/lib/supabase';

type Comment = Database['public']['Tables']['work_queue_comment']['Row'];

interface CommentListProps {
  taskId: string;
  initialComments: Comment[];
}

export function CommentList({ taskId, initialComments }: CommentListProps) {
  const [comments, setComments] = useState<Comment[]>(initialComments);

  useEffect(() => {
    const supabase = sb();

    // Subscribe to real-time updates
    const channel = supabase
      .channel(`work_queue_comment:${taskId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'work_queue_comment',
          filter: `work_queue_id=eq.${taskId}`,
        },
        (payload) => {
          setComments((current) => [...current, payload.new as Comment]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [taskId]);

  if (comments.length === 0) {
    return (
      <div className="text-center text-gray-500 py-8">
        No comments yet. Be the first to comment!
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {comments.map((comment) => (
        <div
          key={comment.id}
          className={`p-4 rounded-lg border ${
            comment.author_kind === 'cline'
              ? 'bg-blue-50 border-blue-200'
              : comment.author_kind === 'system'
                ? 'bg-gray-50 border-gray-200'
                : 'bg-white border-gray-200'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <span
                className={`inline-block px-2 py-1 text-xs rounded-full ${
                  comment.author_kind === 'cline'
                    ? 'bg-blue-100 text-blue-800'
                    : comment.author_kind === 'system'
                      ? 'bg-gray-100 text-gray-800'
                      : 'bg-green-100 text-green-800'
                }`}
              >
                {comment.author_kind}
              </span>
              {comment.author_id && (
                <span className="text-sm text-gray-600">{comment.author_id.slice(0, 8)}...</span>
              )}
            </div>
            <span className="text-xs text-gray-500">
              {new Date(comment.created_at).toLocaleString()}
            </span>
          </div>
          <p className="text-gray-800 whitespace-pre-wrap">{comment.message}</p>
        </div>
      ))}
    </div>
  );
}
