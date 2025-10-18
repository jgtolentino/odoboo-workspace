'use client';

import React, { useState } from 'react';
import BlockEditor from '@/components/editor/BlockEditor';

interface Block {
  id: string;
  type:
    | 'text'
    | 'heading'
    | 'list'
    | 'table'
    | 'embed'
    | 'code'
    | 'image'
    | 'file'
    | 'divider'
    | 'quote';
  content: any;
  position: number;
  parent_block_id?: string;
}

export default function NotionDemoPage() {
  const [blocks, setBlocks] = useState<Block[]>([
    {
      id: '1',
      type: 'heading',
      content: { text: 'Welcome to Notion-Style Workspace', level: 1 },
      position: 0,
    },
    {
      id: '2',
      type: 'text',
      content: {
        text: 'This is a demo of the block-based editor that brings Notion-like functionality to your Odoo-style workspace.',
      },
      position: 1,
    },
    {
      id: '3',
      type: 'heading',
      content: { text: 'Key Features', level: 2 },
      position: 2,
    },
    {
      id: '4',
      type: 'list',
      content: {
        items: [
          'Block-based content editing',
          'Multiple content types (text, headings, lists, tables, etc.)',
          'Real-time collaboration',
          'Database-like views',
          'Custom properties and metadata',
        ],
        type: 'bullet',
      },
      position: 3,
    },
    {
      id: '5',
      type: 'divider',
      content: {},
      position: 4,
    },
    {
      id: '6',
      type: 'heading',
      content: { text: 'Try It Out', level: 2 },
      position: 5,
    },
    {
      id: '7',
      type: 'text',
      content: {
        text: 'Click anywhere below to start editing. Add new blocks by clicking the "+" buttons that appear between blocks.',
      },
      position: 6,
    },
  ]);

  const handleBlockChange = (newBlocks: Block[]) => {
    setBlocks(newBlocks);
    console.log('Blocks updated:', newBlocks);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Notion-Style Workspace Demo</h1>
          <p className="text-gray-600">
            Experience the power of block-based editing combined with Odoo Enterprise capabilities
          </p>
        </div>

        {/* Demo Content */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <BlockEditor
            pageId="demo-page"
            initialBlocks={blocks}
            onBlockChange={handleBlockChange}
            readOnly={false}
          />
        </div>

        {/* Features Grid */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-blue-600 text-lg font-semibold mb-2">📝 Block Editor</div>
            <p className="text-gray-600 text-sm">
              Rich text editing with multiple block types including text, headings, lists, tables,
              and more.
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-green-600 text-lg font-semibold mb-2">📊 Database Views</div>
            <p className="text-gray-600 text-sm">
              Switch between table, board, calendar, and gallery views for your content.
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-purple-600 text-lg font-semibold mb-2">🔗 Task Dependencies</div>
            <p className="text-gray-600 text-sm">
              Advanced project management with visual task dependencies and critical path analysis.
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-orange-600 text-lg font-semibold mb-2">⏱️ Time Tracking</div>
            <p className="text-gray-600 text-sm">
              Real-time time tracking with billing integration and productivity analytics.
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-red-600 text-lg font-semibold mb-2">🎯 Custom Properties</div>
            <p className="text-gray-600 text-sm">
              Add custom fields and metadata to any content type for database-like functionality.
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="text-indigo-600 text-lg font-semibold mb-2">📋 Templates</div>
            <p className="text-gray-600 text-sm">
              Pre-built templates for common workflows like meeting notes, project plans, and more.
            </p>
          </div>
        </div>

        {/* Integration Info */}
        <div className="mt-12 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-blue-900 mb-2">OCA Module Integration</h3>
          <p className="text-blue-800 text-sm mb-4">
            This workspace integrates patterns from Odoo Community Association modules:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <strong className="text-blue-900">document_knowledge</strong>
              <p className="text-blue-700">Enhanced document organization and search</p>
            </div>
            <div>
              <strong className="text-blue-900">project_task_dependency</strong>
              <p className="text-blue-700">Advanced task relationship management</p>
            </div>
            <div>
              <strong className="text-blue-900">project_timesheet_time_control</strong>
              <p className="text-blue-700">Professional time tracking capabilities</p>
            </div>
            <div>
              <strong className="text-blue-900">document_page_access_group</strong>
              <p className="text-blue-700">Granular permission controls</p>
            </div>
          </div>
        </div>

        {/* Next Steps */}
        <div className="mt-8 text-center">
          <p className="text-gray-600 text-sm mb-4">
            Ready to implement these features in your workspace?
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors">
              Deploy to Production
            </button>
            <button className="border border-gray-300 text-gray-700 px-6 py-2 rounded-lg hover:bg-gray-50 transition-colors">
              View Documentation
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
