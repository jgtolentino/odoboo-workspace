// ChatGPT Plugin Server as Supabase Edge Function
// Handles GitHub operations via Personal Access Token

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { Octokit } from "https://esm.sh/@octokit/rest@20.0.0"

const GITHUB_TOKEN = Deno.env.get('GITHUB_TOKEN')
const PLUGIN_BEARER_TOKEN = Deno.env.get('PLUGIN_BEARER_TOKEN')

// CORS headers for ChatGPT
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

// Auth middleware
function requireAuth(req: Request): Response | null {
  if (!PLUGIN_BEARER_TOKEN) {
    console.warn('No PLUGIN_BEARER_TOKEN set')
    return null
  }

  const authHeader = req.headers.get('Authorization') || ''
  const expectedAuth = `Bearer ${PLUGIN_BEARER_TOKEN}`

  if (authHeader !== expectedAuth) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  return null
}

// Get Octokit instance with personal access token
function getOctokit(): Octokit {
  return new Octokit({ auth: GITHUB_TOKEN })
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  const path = url.pathname

  console.log('Request path:', path)

  try {
    // Health check (no auth required)
    if (path === '/health' || path.endsWith('/health')) {
      return new Response(
        JSON.stringify({
          status: 'ok',
          timestamp: new Date().toISOString(),
          github_token: GITHUB_TOKEN ? 'configured' : 'missing',
          auth_configured: !!PLUGIN_BEARER_TOKEN
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Plugin manifest (no auth required)
    if (path === '/.well-known/ai-plugin.json' || path.endsWith('/ai-plugin.json')) {
      const manifest = {
        schema_version: 'v1',
        name_for_human: 'GitHub & Infrastructure Manager',
        name_for_model: 'github_infra',
        description_for_human: 'Manage GitHub repos, Supabase, and infrastructure.',
        description_for_model: 'Plugin for managing GitHub repositories (files, PRs, issues, branches) and infrastructure (Supabase). Use this for code management and deployments.',
        auth: {
          type: 'service_http',
          authorization_type: 'bearer',
        },
        api: {
          type: 'openapi',
          url: `${url.origin}/.well-known/openapi.yaml`,
        },
        logo_url: `${url.origin}/logo.png`,
        contact_email: 'jgtolentino.rn@gmail.com',
      }
      return new Response(
        JSON.stringify(manifest),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // OpenAPI spec (no auth required)
    if (path === '/.well-known/openapi.yaml' || path.endsWith('/openapi.yaml')) {
      const openapi = `
openapi: 3.0.1
info:
  title: GitHub & Infrastructure Manager
  version: "1.0.0"
servers:
  - url: ${url.origin}
paths:
  /repos/{owner}/{repo}/contents/{path}:
    get:
      operationId: getFileContents
      summary: Read file contents
      parameters:
        - name: owner
          in: path
          required: true
          schema:
            type: string
        - name: repo
          in: path
          required: true
          schema:
            type: string
        - name: path
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: File contents
    put:
      operationId: updateFile
      summary: Create or update file
      parameters:
        - name: owner
          in: path
          required: true
          schema:
            type: string
        - name: repo
          in: path
          required: true
          schema:
            type: string
        - name: path
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                message:
                  type: string
                content:
                  type: string
                branch:
                  type: string
                sha:
                  type: string
      responses:
        '200':
          description: File updated
`
      return new Response(openapi, {
        headers: { ...corsHeaders, 'Content-Type': 'application/x-yaml' }
      })
    }

    // Auth required for GitHub operations
    const authError = requireAuth(req)
    if (authError) return authError

    // GitHub file operations
    const match = path.match(/^\/repos\/([^\/]+)\/([^\/]+)\/contents\/(.+)$/)
    if (match) {
      const [_, owner, repo, filePath] = match

      if (req.method === 'GET') {
        const octokit = getOctokit()
        const response = await octokit.rest.repos.getContent({
          owner,
          repo,
          path: filePath,
        })

        if (Array.isArray(response.data)) {
          return new Response(
            JSON.stringify({
              type: 'directory',
              contents: response.data.map(item => ({
                name: item.name,
                path: item.path,
                type: item.type,
                sha: item.sha
              }))
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        const content = response.data.encoding === 'base64'
          ? atob(response.data.content.replace(/\n/g, ''))
          : response.data.content

        return new Response(
          JSON.stringify({
            type: 'file',
            path: response.data.path,
            sha: response.data.sha,
            size: response.data.size,
            content
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (req.method === 'PUT') {
        const body = await req.json()
        const { message, content, branch, sha } = body

        const octokit = getOctokit()
        const contentB64 = btoa(content)

        const params: any = {
          owner,
          repo,
          path: filePath,
          message,
          content: contentB64,
        }
        if (branch) params.branch = branch
        if (sha) params.sha = sha

        const result = await octokit.rest.repos.createOrUpdateFileContents(params)

        return new Response(
          JSON.stringify({
            success: true,
            commit: result.data.commit,
            content: result.data.content
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    return new Response(
      JSON.stringify({ error: 'Not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
