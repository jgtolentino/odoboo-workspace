# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- VS Code extension with Odoo workspace tools (deployment monitoring, RPC console, schema guard, QA snapshot)
- Comprehensive VS Code extension implementation guide with Docker management, deployment commands, and queue monitoring
- Task tracking integration with CHANGELOG.md, FEATURES.md, and VS Code extension commands
- Interactive feature logging wizard (`odoo.logFeature` command) with automatic documentation updates
- Project task TreeView provider showing P0/P1/P2 milestone progress
- Status bar quick access buttons for Tasks and Changelog
- `.vscode/extensions.json` with 27 recommended extensions for Odoo development
- Implementation guide for Docker commands (stop, restart, update module)
- Implementation guide for deployment commands (buildx AMD64, push to DOCR, verify image)
- Implementation guide for queue monitor TreeView with Supabase integration
- Implementation guide for task tracking TreeView with automatic file watching
- Implementation guide for `mail_kanban_mentions` Odoo module with @mention support
- Complete OCR service deployment guide with Nginx + TLS configuration
- Topology decision tree for same-host vs remote OCR service deployment
- Production-ready Nginx configuration with Let's Encrypt TLS automation
- Firewall configuration guide with security best practices
- Odoo integration guide with three configuration methods (UI, Shell, server_environment)
- Queue job configuration with dedicated OCR channel
- Comprehensive verification and smoke testing procedures
- Operations & maintenance runbook with snapshot automation
- Performance tuning guide for high-volume OCR processing

### Changed
- VS Code extension activationEvents changed from command-specific to "onStartupFinished"

### Fixed
- VS Code extension now activates immediately on workspace open

## [0.2.0] - 2025-10-20

### Added
- OCR expense processing specification with user journeys and success metrics
- FastAPI OCR service deployment guide for DigitalOcean
- Complete GitHub Spec-Kit documentation transformation (Specify → Plan → Tasks)
- Repository hygiene with CI/CD workflows, templates, and security policies
- Database sync check script for migration verification

### Changed
- Migrated from Azure infrastructure to DigitalOcean + Supabase stack (87% cost reduction)
- Updated OCR service to use PaddleOCR-VL-900M with OpenAI gpt-4o-mini enhancement
- Consolidated deployment to DigitalOcean App Platform (no local Docker for prod)

### Removed
- All Azure service dependencies (ACR, ACI, Document Intelligence, Azure OpenAI)
- Bruno executor (deprecated)
- Cloudflare dependencies (not in stack)

## [0.1.0] - 2025-10-14

### Added
- Initial Odoo 18 workspace setup with local Docker Compose
- OCA module integration (web_timeline, auditlog, queue_job)
- Custom Odoo modules: `hr_expense_ocr_audit`, `web_dashboard_advanced`
- Task bus integration with Supabase (`task_queue` table)
- Visual regression testing infrastructure (Playwright + SSIM)
- Complete deployment automation scripts for DigitalOcean droplets

### Changed
- Database from local PostgreSQL to Supabase (spdtwktxdalcfigzeqrz)
- OCR processing from Azure Document Intelligence to PaddleOCR-VL
- Deployment target from Azure to DigitalOcean

### Security
- Implemented Row Level Security (RLS) on all Supabase tables
- Migrated secrets from Azure Key Vault to environment variables

## [0.0.1] - 2025-10-01

### Added
- Project initialization with Spec-Kit documentation structure
- Constitution with 10 non-negotiable project principles
- Technology stack selection (Next.js, Supabase, Expo, PaddleOCR)
- Architecture documentation (medallion: Bronze → Silver → Gold → Platinum)

---

## Versioning Convention

- **Major (X.0.0)**: Breaking changes, major feature releases, architecture changes
- **Minor (0.X.0)**: New features, non-breaking enhancements, significant improvements
- **Patch (0.0.X)**: Bug fixes, documentation updates, minor improvements

## Categories

- **Added**: New features or functionality
- **Changed**: Changes to existing functionality
- **Deprecated**: Features marked for removal in future versions
- **Removed**: Features removed in this version
- **Fixed**: Bug fixes
- **Security**: Security-related changes or fixes
