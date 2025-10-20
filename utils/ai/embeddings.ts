/**
 * OpenAI Embeddings Service
 * Generates vector embeddings for semantic search
 */

import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export interface EmbeddingResult {
  embedding: number[];
  model: string;
  tokens: number;
}

/**
 * Generate embedding for single text input
 * Uses OpenAI text-embedding-ada-002 (1536 dimensions)
 */
export async function generateEmbedding(
  text: string,
  model: string = 'text-embedding-ada-002'
): Promise<EmbeddingResult> {
  if (!text || text.trim().length === 0) {
    throw new Error('Text input cannot be empty');
  }

  const response = await openai.embeddings.create({
    model,
    input: text.trim(),
  });

  return {
    embedding: response.data[0].embedding,
    model: response.model,
    tokens: response.usage.total_tokens,
  };
}

/**
 * Generate embeddings for multiple texts in batch
 * Automatically chunks if input exceeds batch limit
 */
export async function generateEmbeddingsBatch(
  texts: string[],
  model: string = 'text-embedding-ada-002'
): Promise<EmbeddingResult[]> {
  const BATCH_SIZE = 100; // OpenAI limit
  const results: EmbeddingResult[] = [];

  // Process in batches
  for (let i = 0; i < texts.length; i += BATCH_SIZE) {
    const batch = texts.slice(i, i + BATCH_SIZE).map((t) => t.trim());

    const response = await openai.embeddings.create({
      model,
      input: batch,
    });

    const batchResults = response.data.map((item) => ({
      embedding: item.embedding,
      model: response.model,
      tokens: response.usage.total_tokens / batch.length, // Approximate tokens per text
    }));

    results.push(...batchResults);
  }

  return results;
}

/**
 * Create searchable text from structured data
 * Combines multiple fields into semantic search text
 */
export function createSearchableText(data: {
  name?: string;
  title?: string;
  description?: string;
  content?: string;
  metadata?: Record<string, any>;
}): string {
  const parts: string[] = [];

  if (data.name) parts.push(`Name: ${data.name}`);
  if (data.title) parts.push(`Title: ${data.title}`);
  if (data.description) parts.push(`Description: ${data.description}`);
  if (data.content) parts.push(`Content: ${data.content}`);

  if (data.metadata) {
    const metaText = Object.entries(data.metadata)
      .map(([key, value]) => `${key}: ${JSON.stringify(value)}`)
      .join(' | ');
    if (metaText) parts.push(metaText);
  }

  return parts.join('\n\n').slice(0, 8000); // Limit to ~8K tokens
}

/**
 * Calculate cosine similarity between two embeddings
 * Returns value between -1 (opposite) and 1 (identical)
 */
export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) {
    throw new Error('Embeddings must have same dimensionality');
  }

  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

/**
 * Estimate token count for text
 * Rough approximation: 1 token ~= 4 characters
 */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}
