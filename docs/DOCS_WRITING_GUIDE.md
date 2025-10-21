# Docs Writing Guide

## Doc Types

- **Spec** (`docs/specs/<feature>.md`): What & why
- **Runbook** (`docs/runbooks/<op>.md`): How to operate
- **ADR** (`docs/adr/NNN-<decision>.md`): Architecture decisions

## Spec Template

```markdown
# <Feature Name>

## Summary

## User Stories / Roles

## Flows (Mermaid)

## Data Model (tables/fields)

## APIs (Odoo RPC, external)

## Dashboards/Analytics

## Acceptance Criteria

## Source Links (Odoo/OCA/Supabase/DO)
```

## Runbook Template

```markdown
# <Operation>

## Preconditions

## Steps (CLI-first)

## Rollback

## Verification

## SLO/SLA
```

## ADR Template

```markdown
# ADR NNN: <Decision>

## Context

## Decision

## Consequences

## Alternatives

## Links
```

## Style

- CLI-first, copy/paste blocks.
- Link to sources; short quotes only.
- Keep sections skimmable; use tables/lists.
