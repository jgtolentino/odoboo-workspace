# Contributing

* Branch: `git checkout -b feat/<topic>`
* Lint/Test (adapt as needed): `pnpm i && pnpm lint && pnpm test`
* DB: migrations in git are **source of truth**. Staging runs on branch pushes; Prod runs on tags (`v*.*.*`).
* PRs: small, focused, with screenshots/logs for deploy changes.
