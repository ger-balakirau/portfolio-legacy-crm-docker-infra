# Dev-Инфраструктура Legacy CRM

Техническое описание инфраструктуры для legacy CRM.

Стек: `PHP 7.0`, `Debian Stretch`, `MySQL 5.7`.

## Назначение

- локальная разработка и отладка legacy CRM;
- воспроизводимое окружение через Docker Compose;
- управляемый deploy через `scripts/deploy/push-crm.sh`.

## Состав репозитория

- `docker-compose.yml` — сервисы `apache` и `mysql`;
- `Dockerfile` — образ приложения (`apache` + PHP 7);
- `prod.conf/` — конфиги Apache/MySQL/PHP;
- `configs/crm/` — runtime-конфиги CRM, монтируемые в контейнер;
- `scripts/deploy/push-crm.sh` — синхронизация CRM (`local -> server` и `server -> local`) через `rsync + ssh`;
- `Makefile` — единая точка входа для локальных команд.

## Runtime-конфиги CRM

В `configs/crm/` хранятся файлы, которые монтируются в CRM поверх кода:

- `config.inc.php`
- `config.csrf-secret.php`
- `config_override.php`
- `.legacy-crm` (по умолчанию используется `.legacy-crm.example`)

Это позволяет хранить критичные runtime-настройки в infra-репозитории отдельно от кода CRM.

## Навигация по документации

- Полный запуск с нуля: `docs/getting-started.md`
- Справочник всех команд: `docs/commands.md`
- Git workflow: `docs/git.md`
