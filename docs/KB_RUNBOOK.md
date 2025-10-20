# KB Runbook

## Daily

- ✅ Nightly CI `kb-sync.yml` pulls mirrors and rebuilds chunks
- Review CI diff (chunk count & size guard)

## Weekly

- Curate new OCA repos (add to mirrors list)
- Prune old snapshots if size grows >25%

## Commands

```bash
# Pull latest sources
git -C knowledge/sources/odoo pull || true
git -C knowledge/sources/web pull || true
git -C knowledge/sources/server-tools pull || true
git -C knowledge/sources/supabase pull || true

# Rebuild chunks
node scripts/kb-build.mjs

# Publish static snapshot (optional)
rsync -a knowledge/sources/ /opt/fin-workspace/www/docs/
docker compose -f /opt/fin-workspace/docker-compose.yml restart nginx
```

## Triage

- ❌ Build fails → check large HTML/RST; exclude noisy paths
- ❌ Size guard trips → review added repos / limit depth
- ❌ Retrieval weak → enrich with our `docs/specs` pages

## Security

- No credentials in mirrors or chunks.
- Serve static docs read-only.
