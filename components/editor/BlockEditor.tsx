'use client';

import React, { useState, useCallback, useRef } from 'react';

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

interface BlockEditorProps {
  pageId: string;
  initialBlocks?: Block[];
  readOnly?: boolean;
  onBlockChange?: (blocks: Block[]) => void;
}

export const BlockEditor: React.FC<BlockEditorProps> = ({
  pageId,
  initialBlocks = [],
  readOnly = false,
  onBlockChange,
}) => {
  const [blocks, setBlocks] = useState<Block[]>(initialBlocks);
  const [isLoading, setIsLoading] = useState(false);
  const [focusedBlockId, setFocusedBlockId] = useState<string | null>(null);
  const blockRefs = useRef<{ [key: string]: HTMLDivElement | null }>({});

  // Add new block
  const addBlock = useCallback(
    (type: Block['type'], position: number) => {
      const newBlock: Block = {
        id: `block-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        type,
        content: getDefaultContent(type),
        position,
      };

      const newBlocks = [...blocks];
      newBlocks.splice(position, 0, newBlock);
      setBlocks(newBlocks);
      onBlockChange?.(newBlocks);
      setFocusedBlockId(newBlock.id);
    },
    [blocks, onBlockChange]
  );

  // Update block content
  const updateBlock = useCallback(
    (blockId: string, updates: Partial<Block>) => {
      const blockIndex = blocks.findIndex((b) => b.id === blockId);
      if (blockIndex === -1) return;

      const updatedBlock = { ...blocks[blockIndex], ...updates };
      const newBlocks = [...blocks];
      newBlocks[blockIndex] = updatedBlock;
      setBlocks(newBlocks);
      onBlockChange?.(newBlocks);
    },
    [blocks, onBlockChange]
  );

  // Delete block
  const deleteBlock = useCallback(
    (blockId: string) => {
      const newBlocks = blocks.filter((b) => b.id !== blockId);
      setBlocks(newBlocks);
      onBlockChange?.(newBlocks);
    },
    [blocks, onBlockChange]
  );

  // Move block position
  const moveBlock = useCallback(
    (blockId: string, newPosition: number) => {
      const blockIndex = blocks.findIndex((b) => b.id === blockId);
      if (blockIndex === -1 || blockIndex === newPosition) return;

      const newBlocks = [...blocks];
      const [movedBlock] = newBlocks.splice(blockIndex, 1);
      newBlocks.splice(newPosition, 0, movedBlock);

      // Update positions
      const updatedBlocks = newBlocks.map((block, index) => ({
        ...block,
        position: index,
      }));

      setBlocks(updatedBlocks);
      onBlockChange?.(updatedBlocks);
    },
    [blocks, onBlockChange]
  );

  // Render individual block based on type
  const renderBlock = (block: Block) => {
    const commonProps = {
      block,
      readOnly,
      onUpdate: (updates: Partial<Block>) => updateBlock(block.id, updates),
      onDelete: () => deleteBlock(block.id),
      onAddBlock: (type: Block['type']) =>
        addBlock(type, blocks.findIndex((b) => b.id === block.id) + 1),
      isFocused: focusedBlockId === block.id,
      onFocus: () => setFocusedBlockId(block.id),
      onBlur: () => setFocusedBlockId(null),
      ref: (el: HTMLDivElement | null) => {
        blockRefs.current[block.id] = el;
      },
    };

    switch (block.type) {
      case 'text':
        return <TextBlock {...commonProps} />;
      case 'heading':
        return <HeadingBlock {...commonProps} />;
      case 'list':
        return <ListBlock {...commonProps} />;
      case 'table':
        return <TableBlock {...commonProps} />;
      case 'code':
        return <CodeBlock {...commonProps} />;
      case 'image':
        return <ImageBlock {...commonProps} />;
      case 'divider':
        return <DividerBlock {...commonProps} />;
      case 'quote':
        return <QuoteBlock {...commonProps} />;
      default:
        return <TextBlock {...commonProps} />;
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {blocks.map((block, index) => (
        <div key={block.id} className="group relative">
          {renderBlock(block)}

          {/* Add block button between blocks */}
          {!readOnly && index < blocks.length - 1 && (
            <div className="absolute left-0 right-0 -bottom-3 flex justify-center opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                onClick={() => addBlock('text', index + 1)}
                className="bg-white border border-gray-300 rounded-full p-1 shadow-sm hover:shadow-md transition-shadow"
                title="Add block"
              >
                <span className="w-4 h-4 text-gray-500">+</span>
              </button>
            </div>
          )}
        </div>
      ))}

      {/* Add first block if empty */}
      {!readOnly && blocks.length === 0 && (
        <div className="text-center py-8">
          <button
            onClick={() => addBlock('text', 0)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Start writing...
          </button>
        </div>
      )}
    </div>
  );
};

// Helper function to get default content for block types
function getDefaultContent(type: Block['type']): any {
  switch (type) {
    case 'text':
      return { text: '' };
    case 'heading':
      return { text: '', level: 1 };
    case 'list':
      return { items: [''], type: 'bullet' };
    case 'table':
      return { headers: ['Column 1'], rows: [] };
    case 'code':
      return { code: '', language: 'javascript' };
    case 'image':
      return { url: '', caption: '' };
    case 'divider':
      return {};
    case 'quote':
      return { text: '', author: '' };
    default:
      return { text: '' };
  }
}

// Individual block components
interface BlockComponentProps {
  block: Block;
  readOnly: boolean;
  onUpdate: (updates: Partial<Block>) => void;
  onDelete: () => void;
  onAddBlock: (type: Block['type']) => void;
  isFocused: boolean;
  onFocus: () => void;
  onBlur: () => void;
  ref: (el: HTMLDivElement | null) => void;
}

const TextBlock: React.FC<BlockComponentProps> = ({
  block,
  readOnly,
  onUpdate,
  isFocused,
  onFocus,
  onBlur,
  ref,
}) => {
  const [text, setText] = useState(block.content.text || '');

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newText = e.target.value;
    setText(newText);
    onUpdate({ content: { ...block.content, text: newText } });
  };

  return (
    <div
      ref={ref}
      className={`p-2 rounded-lg transition-colors ${
        isFocused ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50'
      }`}
    >
      <textarea
        value={text}
        onChange={handleChange}
        onFocus={onFocus}
        onBlur={onBlur}
        readOnly={readOnly}
        placeholder="Start typing..."
        className="w-full resize-none border-none bg-transparent focus:outline-none text-gray-900"
        rows={Math.max(1, text.split('\n').length)}
      />
    </div>
  );
};

const HeadingBlock: React.FC<BlockComponentProps> = ({
  block,
  readOnly,
  onUpdate,
  isFocused,
  onFocus,
  onBlur,
  ref,
}) => {
  const [text, setText] = useState(block.content.text || '');
  const level = block.content.level || 1;

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newText = e.target.value;
    setText(newText);
    onUpdate({ content: { ...block.content, text: newText } });
  };

  const getHeadingStyle = () => {
    switch (level) {
      case 1:
        return 'text-2xl font-bold';
      case 2:
        return 'text-xl font-semibold';
      case 3:
        return 'text-lg font-semibold';
      default:
        return 'text-base font-medium';
    }
  };

  return (
    <div
      ref={ref}
      className={`p-2 rounded-lg transition-colors ${
        isFocused ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50'
      }`}
    >
      <div className={`text-gray-900 mb-1 ${getHeadingStyle()}`}>
        {level === 1 ? 'Heading 1' : level === 2 ? 'Heading 2' : 'Heading 3'}
      </div>
      <textarea
        value={text}
        onChange={handleChange}
        onFocus={onFocus}
        onBlur={onBlur}
        readOnly={readOnly}
        placeholder="Heading..."
        className="w-full resize-none border-none bg-transparent focus:outline-none text-gray-900 font-semibold"
        style={{ fontSize: level === 1 ? '1.5rem' : level === 2 ? '1.25rem' : '1.125rem' }}
        rows={1}
      />
    </div>
  );
};

const ListBlock: React.FC<BlockComponentProps> = ({
  block,
  readOnly,
  onUpdate,
  isFocused,
  onFocus,
  onBlur,
  ref,
}) => {
  const [items, setItems] = useState<string[]>(block.content.items || ['']);

  const handleItemChange = (index: number, value: string) => {
    const newItems = [...items];
    newItems[index] = value;
    setItems(newItems);
    onUpdate({ content: { ...block.content, items: newItems } });
  };

  const addItem = () => {
    const newItems = [...items, ''];
    setItems(newItems);
    onUpdate({ content: { ...block.content, items: newItems } });
  };

  const removeItem = (index: number) => {
    if (items.length <= 1) return;
    const newItems = items.filter((_, i) => i !== index);
    setItems(newItems);
    onUpdate({ content: { ...block.content, items: newItems } });
  };

  return (
    <div
      ref={ref}
      className={`p-2 rounded-lg transition-colors ${
        isFocused ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50'
      }`}
    >
      {items.map((item, index) => (
        <div key={index} className="flex items-start space-x-2 mb-1">
          <span className="mt-1 text-gray-500">
            {block.content.type === 'bullet' ? '•' : `${index + 1}.`}
          </span>
          <input
            type="text"
            value={item}
            onChange={(e) => handleItemChange(index, e.target.value)}
            onFocus={onFocus}
            onBlur={onBlur}
            readOnly={readOnly}
            placeholder="List item..."
            className="flex-1 border-none bg-transparent focus:outline-none text-gray-900"
          />
          {!readOnly && items.length > 1 && (
            <button onClick={() => removeItem(index)} className="text-red-500 hover:text-red-700">
              ×
            </button>
          )}
        </div>
      ))}
      {!readOnly && (
        <button onClick={addItem} className="text-blue-600 hover:text-blue-800 text-sm mt-1">
          + Add item
        </button>
      )}
    </div>
  );
};

// Simplified versions of other block components
const TableBlock: React.FC<BlockComponentProps> = ({ block, isFocused, onFocus, onBlur, ref }) => (
  <div
    ref={ref}
    className={`p-4 border rounded-lg transition-colors ${
      isFocused ? 'bg-blue-50 border-blue-200' : 'border-gray-200 hover:bg-gray-50'
    }`}
    onFocus={onFocus}
    onBlur={onBlur}
    tabIndex={0}
  >
    <div className="text-gray-500 text-sm">Table Block</div>
    <div className="text-gray-400 text-xs mt-1">Double-click to edit table</div>
  </div>
);

const CodeBlock: React.FC<BlockComponentProps> = ({ block, isFocused, onFocus, onBlur, ref }) => (
  <div
    ref={ref}
    className={`p-4 bg-gray-100 rounded-lg transition-colors ${
      isFocused ? 'border border-blue-200' : ''
    }`}
    onFocus={onFocus}
    onBlur={onBlur}
    tabIndex={0}
  >
    <div className="text-gray-500 text-sm">Code Block</div>
    <div className="text-gray-400 text-xs mt-1">Double-click to edit code</div>
  </div>
);

const ImageBlock: React.FC<BlockComponentProps> = ({ block, isFocused, onFocus, onBlur, ref }) => (
  <div
    ref={ref}
    className={`p-4 border rounded-lg transition-colors ${
      isFocused ? 'bg-blue-50 border-blue-200' : 'border-gray-200 hover:bg-gray-50'
    }`}
    onFocus={onFocus}
    onBlur={onBlur}
    tabIndex={0}
  >
    <div className="text-gray-500 text-sm">Image Block</div>
    <div className="text-gray-400 text-xs mt-1">Click to upload or edit image</div>
  </div>
);

const DividerBlock: React.FC<BlockComponentProps> = ({ isFocused, onFocus, onBlur, ref }) => (
  <div
    ref={ref}
    className={`py-4 transition-colors ${isFocused ? 'bg-blue-50' : ''}`}
    onFocus={onFocus}
    onBlur={onBlur}
    tabIndex={0}
  >
    <hr className="border-gray-300" />
  </div>
);

const QuoteBlock: React.FC<BlockComponentProps> = ({ block, isFocused, onFocus, onBlur, ref }) => (
  <div
    ref={ref}
    className={`p-4 border-l-4 border-gray-400 bg-gray-50 rounded-r-lg transition-colors ${
      isFocused ? 'bg-blue-50' : ''
    }`}
    onFocus={onFocus}
    onBlur={onBlur}
    tabIndex={0}
  >
    <div className="text-gray-500 text-sm">Quote Block</div>
    <div className="text-gray-400 text-xs mt-1">Double-click to edit quote</div>
  </div>
);

export default BlockEditor;
