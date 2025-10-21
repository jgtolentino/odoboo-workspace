# Knowledge Base Overview (odoobo-expert)

## Purpose

Single source of truth for Odoo/OCA/Supabase/DigitalOcean docs, mirrored locally and indexed for retrieval by the odoobo-expert agent.

## Directional Sync (One-Way)

upstream repos/sites → read-only mirrors → chunk index → agent retrieval
❌ Never edit mirrors. ✅ Add/maintain our docs in `docs/`.

## Sources

- Odoo core: `knowledge/sources/odoo/doc/**`
- OCA: selected repos (web, server-tools, etc.)
- Supabase: `knowledge/sources/supabase/**`
- DigitalOcean docs: curated static snapshot

## Build & Index

```bash
node scripts/kb-build.mjs   # emits JSON chunks to knowledge/chunks
```

## Publishing (optional)

- Static browse: `/docs/` via Nginx `alias /opt/fin-workspace/www/docs/`
- Agent lookup: `doc-lookup` skill searches `knowledge/chunks`

## Guardrails

- Link back to original sources.
- Keep allow-list of domains.
- No secrets in docs or chunks.
- Nightly CI refresh with size/diff budget.

## Where to Write Our Content

- Product specs: `docs/specs/**`
- Runbooks/Playbooks: `docs/runbooks/**`
- ADRs: `docs/adr/**`
