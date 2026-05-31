SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

COMPOSE ?= docker compose
APACHE_SERVICE ?= apache
MYSQL_SERVICE ?= mysql
DUMP_DIR ?= dump
SERVICE ?= $(APACHE_SERVICE)

.PHONY: help \
	up up-build rebuild down restart ps logs sh-apache compose-exec \
	tracking vtiger-cron crm-init \
	db-dump db-dump-pv db-import db-import-pv mysql-show-mode mysql-legacy-mode \
	deploy deploy-dry deploy-full-perms deploy-reload deploy-pull deploy-pull-data deploy-pull-dry-run

help:
	@echo "Основное (docker compose через make):"
	@echo "  make up             # docker compose up -d"
	@echo "  make up-build       # docker compose up -d --build"
	@echo "  make rebuild        # docker compose build --no-cache"
	@echo "  make down           # docker compose down"
	@echo "  make restart        # docker compose restart"
	@echo "  make ps             # docker compose ps"
	@echo "  make logs           # docker compose logs -f $(APACHE_SERVICE)"
	@echo "  make logs SERVICE=mysql"
	@echo "  make sh-apache      # shell внутри apache container"
	@echo "  make compose-exec CMD='php -v' [SERVICE=apache]"
	@echo ""
	@echo "CRM:"
	@echo "  make tracking       # php Tracking.php внутри apache container"
	@echo "  make vtiger-cron    # php vtigercron.php внутри apache container"
	@echo "  make crm-init       # создать недостающие runtime-файлы CRM и privileges"
	@echo ""
	@echo "База данных:"
	@echo "  make db-dump        # дамп БД в $(DUMP_DIR)/<db>_<date>.sql.gz"
	@echo "  make db-dump-pv     # то же, что db-dump, но с progress через pv"
	@echo "  make db-import FILE=$(DUMP_DIR)/backup.sql.gz"
	@echo "  make db-import-pv FILE=$(DUMP_DIR)/backup.sql.gz"
	@echo "  make mysql-show-mode   # показать текущий MySQL GLOBAL sql_mode"
	@echo "  make mysql-legacy-mode # только dev: убрать ONLY_FULL_GROUP_BY в runtime"
	@echo ""
	@echo "Deploy:"
	@echo "  make deploy"
	@echo "  make deploy-dry"
	@echo "  make deploy-full-perms"
	@echo "  make deploy-reload   # deploy + apache2 reload (обновление mod_php OPCache)"
	@echo "  make deploy-pull     # sync server -> local (только код, безопасные defaults)"
	@echo "  make deploy-pull-data # sync server -> local вместе с runtime-данными"
	@echo "  make deploy-pull-dry-run # preview server -> local sync без записи"
	@echo ""
	@echo "Deploy-переменные:"
	@echo "  HOST=<ip-or-host>  переопределить remote host из .env.deploy"
	@echo "  ARGS='...'         дополнительные args для scripts/deploy/push-crm.sh"

up:
	$(COMPOSE) up -d

up-build:
	$(COMPOSE) up -d --build

rebuild:
	$(COMPOSE) build --no-cache

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	@set -o pipefail; \
	status=0; \
	$(COMPOSE) logs -f $(SERVICE) || status=$$?; \
	if [[ $$status -eq 0 || $$status -eq 130 ]]; then \
		exit 0; \
	fi; \
	exit $$status

sh-apache:
	$(COMPOSE) exec $(APACHE_SERVICE) bash

compose-exec:
	@if [[ -z "$(CMD)" ]]; then \
		echo "Ошибка: CMD обязателен. Пример: make compose-exec CMD='php -v'"; \
		exit 1; \
	fi
	$(COMPOSE) exec $(SERVICE) sh -lc "$(CMD)"

tracking:
	$(COMPOSE) exec -T $(APACHE_SERVICE) php Tracking.php

vtiger-cron:
	$(COMPOSE) exec -T $(APACHE_SERVICE) php vtigercron.php

crm-init:
	@COMPOSE="$(COMPOSE)" APACHE_SERVICE="$(APACHE_SERVICE)" ./scripts/dev/crm-init.sh

db-dump:
	@mkdir -p "$(DUMP_DIR)"
	@db_name="$$(awk -F= '/^MYSQL_DATABASE=/{print $$2; exit}' .env)"; \
	if [[ -z "$$db_name" ]]; then \
		echo "Ошибка: MYSQL_DATABASE не задан в .env"; \
		exit 1; \
	fi; \
	file="$(DUMP_DIR)/$${db_name}_$$(date +%F_%H-%M).sql.gz"; \
	echo "Создаю дамп БД в $$file"; \
	$(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc 'mysqldump -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' \
		| gzip > "$$file"; \
	echo "Сохранено: $$file"

db-dump-pv:
	@if ! command -v pv >/dev/null 2>&1; then \
		echo "Error: pv is not installed. Install it or use: make db-dump"; \
		exit 1; \
	fi
	@mkdir -p "$(DUMP_DIR)"
	@db_name="$$(awk -F= '/^MYSQL_DATABASE=/{print $$2; exit}' .env)"; \
	if [[ -z "$$db_name" ]]; then \
		echo "Ошибка: MYSQL_DATABASE не задан в .env"; \
		exit 1; \
	fi; \
	file="$(DUMP_DIR)/$${db_name}_$$(date +%F_%H-%M).sql.gz"; \
	echo "Создаю дамп БД в $$file (с pv)"; \
	$(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc 'mysqldump -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' \
		| pv | gzip > "$$file"; \
	echo "Сохранено: $$file"

db-import:
	@if [[ -z "$(FILE)" ]]; then \
		echo "Ошибка: FILE обязателен. Пример: make db-import FILE=$(DUMP_DIR)/backup.sql.gz"; \
		exit 1; \
	fi
	@if [[ ! -f "$(FILE)" ]]; then \
		echo "Ошибка: dump-файл не найден: $(FILE)"; \
		exit 1; \
	fi
	@echo "Импортирую $(FILE) ..."
	@gunzip -c "$(FILE)" \
		| $(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'
	@echo "Импорт завершен"

db-import-pv:
	@if [[ -z "$(FILE)" ]]; then \
		echo "Ошибка: FILE обязателен. Пример: make db-import-pv FILE=$(DUMP_DIR)/backup.sql.gz"; \
		exit 1; \
	fi
	@if [[ ! -f "$(FILE)" ]]; then \
		echo "Ошибка: dump-файл не найден: $(FILE)"; \
		exit 1; \
	fi
	@if ! command -v pv >/dev/null 2>&1; then \
		echo "Ошибка: pv не установлен. Установите его или используйте: make db-import FILE=..."; \
		exit 1; \
	fi
	@echo "Импортирую $(FILE) с progress ..."
	@pv "$(FILE)" \
		| gunzip \
		| $(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'
	@echo "Импорт завершен"

mysql-show-mode:
	@$(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc "mysql -u\"$$MYSQL_USER\" -p\"$$MYSQL_PASSWORD\" -Nse \"SELECT @@GLOBAL.sql_mode;\" \"$$MYSQL_DATABASE\""

mysql-legacy-mode:
	@echo "Применяю dev-only workaround для sql_mode (убираю ONLY_FULL_GROUP_BY)..."
	@$(COMPOSE) exec -T $(MYSQL_SERVICE) sh -lc "mysql -u\"$$MYSQL_USER\" -p\"$$MYSQL_PASSWORD\" -Nse \"SET GLOBAL sql_mode=(SELECT REPLACE(@@GLOBAL.sql_mode, 'ONLY_FULL_GROUP_BY', '')); SELECT @@GLOBAL.sql_mode;\" \"$$MYSQL_DATABASE\""
	@echo "Применено. Важно: это runtime-only настройка, она сбросится после рестарта mysql container."

deploy:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) $(ARGS)

deploy-dry:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --dry-run $(ARGS)

deploy-full-perms:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --full-perms $(ARGS)

deploy-reload:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --opcache-reload $(ARGS)

deploy-pull:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --pull $(ARGS)

deploy-pull-data:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --pull --with-runtime-data $(ARGS)

deploy-pull-dry-run:
	./scripts/deploy/push-crm.sh $(if $(HOST),--host $(HOST),) --pull --dry-run $(ARGS)
