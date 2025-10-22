.PHONY: help up down logs restart build backup restore set-base-url health bootstrap update

help:
	@echo "Odoo 18 Production Deployment - Make Commands"
	@echo ""
	@echo "  make up              - Start all services"
	@echo "  make down            - Stop all services"
	@echo "  make logs            - Follow Odoo logs"
	@echo "  make restart         - Restart Odoo service"
	@echo "  make build           - Rebuild Odoo image"
	@echo "  make backup          - Backup database and filestore"
	@echo "  make restore         - Restore from backup (requires DB_DUMP and FILESTORE_TAR)"
	@echo "  make set-base-url    - Set and lock base URL (requires URL)"
	@echo "  make health          - Run health checks"
	@echo "  make bootstrap       - Initial deployment setup"
	@echo "  make update          - Update deployment (pull + rebuild + restart)"
	@echo ""

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f odoo

restart:
	docker compose restart odoo

build:
	docker compose build odoo

backup:
	./scripts/backup.sh

restore:
	@if [ -z "$(DB_DUMP)" ] || [ -z "$(FILESTORE_TAR)" ]; then \
		echo "Error: Requires DB_DUMP and FILESTORE_TAR"; \
		echo "Usage: make restore DB_DUMP=backups/db.dump FILESTORE_TAR=backups/filestore.tar.gz"; \
		exit 1; \
	fi
	./scripts/restore.sh $(DB_DUMP) $(FILESTORE_TAR)

set-base-url:
	@if [ -z "$(URL)" ]; then \
		echo "Error: Requires URL"; \
		echo "Usage: make set-base-url URL=https://insightpulseai.net"; \
		exit 1; \
	fi
	./scripts/set_base_url.sh $(URL)

health:
	./scripts/health_check.sh

bootstrap:
	./scripts/bootstrap.sh

update:
	./scripts/update.sh
