#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, resolve } from 'path';

// Project root detection
const findProjectRoot = (): string => {
  const cwd = process.cwd();
  // Look for FEATURES.md, spec/ directory, or .git directory
  if (existsSync(join(cwd, 'FEATURES.md'))) return cwd;
  if (existsSync(join(cwd, '..', 'FEATURES.md'))) return resolve(cwd, '..');
  if (existsSync(join(cwd, '../..', 'FEATURES.md'))) return resolve(cwd, '../..');
  return cwd; // fallback
};

const PROJECT_ROOT = findProjectRoot();
const FEATURES_PATH = join(PROJECT_ROOT, 'FEATURES.md');
const SPEC_DIR = join(PROJECT_ROOT, 'spec');
const PLAN_DIR = join(PROJECT_ROOT, 'plan');
const DOCS_DIR = join(PROJECT_ROOT, 'docs');

// Types
interface FeatureSection {
  category: string;
  status: '✅' | '🔄' | '📋' | '⏸️' | '❌';
  features: string[];
}

interface SpecFile {
  path: string;
  name: string;
  content: string;
  category: 'spec' | 'plan' | 'doc';
}

// Helper functions
function parseFeatures(content: string): FeatureSection[] {
  const sections: FeatureSection[] = [];
  const lines = content.split('\n');

  let currentCategory = '';
  let currentStatus: FeatureSection['status'] = '📋';
  let currentFeatures: string[] = [];

  for (const line of lines) {
    // Match section headers like "## Core Infrastructure (✅ Implemented)"
    const headerMatch = line.match(/^##\s+(.+?)\s+\((✅|🔄|📋|⏸️|❌)\s+.+\)/);
    if (headerMatch) {
      // Save previous section
      if (currentCategory && currentFeatures.length > 0) {
        sections.push({
          category: currentCategory,
          status: currentStatus,
          features: [...currentFeatures],
        });
      }

      // Start new section
      currentCategory = headerMatch[1];
      currentStatus = headerMatch[2] as FeatureSection['status'];
      currentFeatures = [];
      continue;
    }

    // Match feature items (bullet points with emoji status)
    const featureMatch = line.match(/^[-*]\s+(✅|🔄|📋|⏸️|❌)\s+(.+)/);
    if (featureMatch) {
      currentFeatures.push(featureMatch[2].trim());
    }
  }

  // Save last section
  if (currentCategory && currentFeatures.length > 0) {
    sections.push({
      category: currentCategory,
      status: currentStatus,
      features: currentFeatures,
    });
  }

  return sections;
}

function listSpecFiles(directory: string, category: SpecFile['category']): SpecFile[] {
  if (!existsSync(directory)) return [];

  try {
    const files = readdirSync(directory);
    return files
      .filter((f) => f.endsWith('.md'))
      .map((f) => ({
        path: join(directory, f),
        name: f,
        content: readFileSync(join(directory, f), 'utf-8'),
        category,
      }));
  } catch (error) {
    return [];
  }
}

function searchInFiles(files: SpecFile[], query: string): SpecFile[] {
  const lowerQuery = query.toLowerCase();
  return files.filter(
    (file) =>
      file.name.toLowerCase().includes(lowerQuery) ||
      file.content.toLowerCase().includes(lowerQuery)
  );
}

function filterByStatus(sections: FeatureSection[], status: string): FeatureSection[] {
  const statusEmoji =
    status === 'implemented'
      ? '✅'
      : status === 'in_progress'
        ? '🔄'
        : status === 'planned'
          ? '📋'
          : status === 'on_hold'
            ? '⏸️'
            : status === 'deprecated'
              ? '❌'
              : null;

  if (!statusEmoji) return sections;
  return sections.filter((s) => s.status === statusEmoji);
}

// MCP Server
const server = new Server(
  {
    name: 'spec-inventory',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define tools
const tools: Tool[] = [
  {
    name: 'list_features',
    description:
      'List all features from FEATURES.md, optionally filtered by status (implemented, in_progress, planned, on_hold, deprecated)',
    inputSchema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: ['implemented', 'in_progress', 'planned', 'on_hold', 'deprecated', 'all'],
          description: 'Filter features by implementation status',
        },
        category: {
          type: 'string',
          description: 'Filter features by category name (partial match)',
        },
      },
    },
  },
  {
    name: 'search_specs',
    description: 'Search across all specification files (spec/, plan/, docs/) for a given query',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Search query (case-insensitive, searches filenames and content)',
        },
        category: {
          type: 'string',
          enum: ['spec', 'plan', 'doc', 'all'],
          description: 'Limit search to specific directory',
        },
      },
      required: ['query'],
    },
  },
  {
    name: 'read_spec',
    description: 'Read the full contents of a specific specification file',
    inputSchema: {
      type: 'object',
      properties: {
        filename: {
          type: 'string',
          description: "Filename (e.g., '01-ocr-expense-processing.md') or full path",
        },
      },
      required: ['filename'],
    },
  },
  {
    name: 'get_feature_stats',
    description: 'Get statistics about feature implementation across the project',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
];

// Tool handlers
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'list_features': {
        if (!existsSync(FEATURES_PATH)) {
          return {
            content: [
              {
                type: 'text',
                text: `FEATURES.md not found at ${FEATURES_PATH}`,
              },
            ],
          };
        }

        const content = readFileSync(FEATURES_PATH, 'utf-8');
        let sections = parseFeatures(content);

        // Filter by status
        if (args?.status && args.status !== 'all') {
          sections = filterByStatus(sections, args.status as string);
        }

        // Filter by category
        if (args?.category) {
          const categoryLower = (args.category as string).toLowerCase();
          sections = sections.filter((s) => s.category.toLowerCase().includes(categoryLower));
        }

        // Format output
        const output = sections
          .map((s) => {
            const featureList = s.features.map((f) => `  - ${f}`).join('\n');
            return `## ${s.category} (${s.status})\n${featureList}`;
          })
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: output || 'No features found matching criteria',
            },
          ],
        };
      }

      case 'search_specs': {
        const query = (args?.query as string) || '';
        const category = (args?.category as string) || 'all';

        const allFiles: SpecFile[] = [];

        if (category === 'all' || category === 'spec') {
          allFiles.push(...listSpecFiles(SPEC_DIR, 'spec'));
        }
        if (category === 'all' || category === 'plan') {
          allFiles.push(...listSpecFiles(PLAN_DIR, 'plan'));
        }
        if (category === 'all' || category === 'doc') {
          allFiles.push(...listSpecFiles(DOCS_DIR, 'doc'));
        }

        const results = searchInFiles(allFiles, query);

        if (results.length === 0) {
          return {
            content: [
              {
                type: 'text',
                text: `No specifications found matching "${query}"`,
              },
            ],
          };
        }

        const output = results
          .map((r) => {
            // Extract first 200 chars with query context
            const queryIndex = r.content.toLowerCase().indexOf(query.toLowerCase());
            const contextStart = Math.max(0, queryIndex - 100);
            const contextEnd = Math.min(r.content.length, queryIndex + 100);
            const snippet = r.content
              .substring(contextStart, contextEnd)
              .replace(/\n+/g, ' ')
              .trim();

            return `**${r.name}** (${r.category})\n${snippet}...\nPath: ${r.path}`;
          })
          .join('\n\n---\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `Found ${results.length} results:\n\n${output}`,
            },
          ],
        };
      }

      case 'read_spec': {
        const filename = (args?.filename as string) || '';

        // Try to find file in spec/, plan/, or docs/
        const possiblePaths = [
          join(SPEC_DIR, filename),
          join(PLAN_DIR, filename),
          join(DOCS_DIR, filename),
          filename, // If full path provided
        ];

        let content = '';
        let foundPath = '';

        for (const path of possiblePaths) {
          if (existsSync(path)) {
            content = readFileSync(path, 'utf-8');
            foundPath = path;
            break;
          }
        }

        if (!content) {
          return {
            content: [
              {
                type: 'text',
                text: `Specification file "${filename}" not found in spec/, plan/, or docs/ directories`,
              },
            ],
          };
        }

        return {
          content: [
            {
              type: 'text',
              text: `# ${filename}\n\nPath: ${foundPath}\n\n---\n\n${content}`,
            },
          ],
        };
      }

      case 'get_feature_stats': {
        if (!existsSync(FEATURES_PATH)) {
          return {
            content: [
              {
                type: 'text',
                text: `FEATURES.md not found at ${FEATURES_PATH}`,
              },
            ],
          };
        }

        const content = readFileSync(FEATURES_PATH, 'utf-8');
        const sections = parseFeatures(content);

        // Count by status
        const stats = {
          implemented: 0,
          in_progress: 0,
          planned: 0,
          on_hold: 0,
          deprecated: 0,
          total_categories: sections.length,
          total_features: 0,
        };

        for (const section of sections) {
          stats.total_features += section.features.length;

          switch (section.status) {
            case '✅':
              stats.implemented += section.features.length;
              break;
            case '🔄':
              stats.in_progress += section.features.length;
              break;
            case '📋':
              stats.planned += section.features.length;
              break;
            case '⏸️':
              stats.on_hold += section.features.length;
              break;
            case '❌':
              stats.deprecated += section.features.length;
              break;
          }
        }

        // Calculate percentages
        const implPercent = ((stats.implemented / stats.total_features) * 100).toFixed(1);
        const progressPercent = ((stats.in_progress / stats.total_features) * 100).toFixed(1);

        const output = `# Feature Implementation Statistics

**Total Categories**: ${stats.total_categories}
**Total Features**: ${stats.total_features}

**Status Breakdown**:
- ✅ Implemented: ${stats.implemented} (${implPercent}%)
- 🔄 In Progress: ${stats.in_progress} (${progressPercent}%)
- 📋 Planned: ${stats.planned}
- ⏸️ On Hold: ${stats.on_hold}
- ❌ Deprecated: ${stats.deprecated}

**Completion Rate**: ${implPercent}%
`;

        return {
          content: [
            {
              type: 'text',
              text: output,
            },
          ],
        };
      }

      default:
        return {
          content: [
            {
              type: 'text',
              text: `Unknown tool: ${name}`,
            },
          ],
          isError: true,
        };
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error instanceof Error ? error.message : String(error)}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error('MCP Spec Inventory Server running on stdio');
  console.error(`Project root: ${PROJECT_ROOT}`);
  console.error(`Features file: ${FEATURES_PATH}`);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
