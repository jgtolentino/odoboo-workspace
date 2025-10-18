'use client';

import { useState } from 'react';
import { sb } from '@/utils/supabase/client';

interface CommentFormProps {
  taskId: string;
}

export function CommentForm({ taskId }: CommentFormProps) {
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim() || isSubmitting) return;

    setIsSubmitting(true);

    try {
      const supabase = sb();

      // Get current user (for now, we'll use a placeholder)
      // In a real app, you'd get this from Supabase Auth
      const {
        data: { user },
      } = await supabase.auth.getUser();

      const { error } = await supabase.from('work_queue_comment').insert({
        work_queue_id: taskId,
        author_kind: 'user',
        author_id: user?.id || '00000000-0000-0000-0000-000000000000',
        message: message.trim(),
      });

      if (error) {
        console.error('Error posting comment:', error);
        alert('Failed to post comment');
      } else {
        setMessage('');
      }
    } catch (error) {
      console.error('Error posting comment:', error);
      alert('Failed to post comment');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="comment" className="block text-sm font-medium text-gray-700 mb-2">
          Add a comment
        </label>
        <textarea
          id="comment"
          name="comment"
          rows={3}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          placeholder="Type your comment here..."
          disabled={isSubmitting}
        />
      </div>
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={!message.trim() || isSubmitting}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Posting...' : 'Post Comment'}
        </button>
      </div>
    </form>
  );
}
