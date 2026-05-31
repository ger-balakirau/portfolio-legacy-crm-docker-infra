# Команды Legacy CRM

Основной интерфейс для локальной работы: `make`.
Установка проекта с нуля: `docs/getting-started.md`.

Быстрая справка по всем командам:

```bash
make help
```

## Жизненный Цикл (Docker Compose)

| Команда | Что делает | Когда использовать |
|---|---|---|
| `make up` | `docker compose up -d` | Обычный старт/поднятие без пересборки |
| `make up-build` | `docker compose up -d --build` | Первый запуск или после изменений в `Dockerfile`/build context |
| `make rebuild` | `docker compose build --no-cache` | Полная пересборка образов без cache |
| `make down` | `docker compose down` | Остановить и удалить контейнеры/сеть проекта |
| `make restart` | `docker compose restart` | Быстрый рестарт сервисов |
| `make ps` | `docker compose ps` | Проверить состояние контейнеров |
| `make logs` | `docker compose logs -f apache` | Смотреть live-логи `apache` по умолчанию |
| `make logs SERVICE=mysql` | `docker compose logs -f mysql` | Смотреть логи конкретного сервиса |
| `make sh-apache` | `docker compose exec apache bash` | Зайти в shell `apache` контейнера |
| `make compose-exec CMD='php -v'` | Выполнить команду внутри сервиса | Универсальный запуск команд внутри контейнера |

## Задачи CRM

| Команда | Что делает |
|---|---|
| `make tracking` | Запуск `Tracking.php` в `apache` контейнере (ручной трекинг отправлений) |
| `make vtiger-cron` | Запуск `vtigercron.php` в `apache` контейнере (штатные cron-задачи CRM) |
| `make crm-init` | Подготовка runtime-файлов CRM (`includes/runtime/cache`, `user_privileges`) и пересборка `user_privileges_*` из БД |

## База Данных

> **ВАЖНО:** <u>для нормальной работы CRM нужен импорт рабочего дампа БД.</u>

| Команда | Что делает | Требования |
|---|---|---|
| `make db-dump` | Дамп БД в `dump/<db>_<date>.sql.gz` | `docker compose` |
| `make db-dump-pv` | То же, но с прогрессом | Утилита `pv` |
| `make db-import FILE=dump/file.sql.gz` | Импорт дампа в БД | `FILE` обязателен |
| `make db-import-pv FILE=dump/file.sql.gz` | Импорт с прогрессом | `FILE` + `pv` |
| `make mysql-show-mode` | Показать текущий `@@GLOBAL.sql_mode` | Для диагностики SQL-режима |
| `make mysql-legacy-mode` | Dev-only: убрать `ONLY_FULL_GROUP_BY` runtime-командой | Сбрасывается после рестарта mysql |

## Deploy

Подготовка:

```bash
cp .env.deploy.example .env.deploy
```

Основные команды:

| Команда | Что делает |
|---|---|
| `make deploy` | Реальный деплой CRM на сервер |
| `make deploy-dry` | Проверка деплоя без изменений |
| `make deploy-full-perms` | Деплой + полный медленный `chmod/chown` прогон |
| `make deploy-reload` | Деплой + явный `apache2 reload` после синхронизации |
| `make deploy-pull` | Синхронизация `server -> local` (без runtime-данных) |
| `make deploy-pull-data` | Синхронизация `server -> local`, включая runtime-данные |
| `make deploy-pull-dry-run` | Preview `server -> local` без записи в локальные файлы |

Что синхронизируется по умолчанию:

- Синхронизируется код CRM.
- Не синхронизируются runtime/generated данные: `storage/`, `OperatorWayBill/`, `cache/`, `user_privileges/`, `kcfinder/upload/`, `cron/output.txt` (включаются только флагом `--with-runtime-data`).
- Не синхронизируются локальные секреты: `.legacy-crm`, `config.csrf-secret.php`, `config_override.php`, `config.inc.php` (для `config.inc.php` нужен явный `--with-config-inc`).
- `apache2 reload` по умолчанию выключен (включается только `--opcache-reload` или `make deploy-reload`).

Поведение `--dry-run`:

- В `--dry-run` скрипт ничего не записывает (ни на сервер, ни локально).
- В push-режиме `--dry-run` проверяет наличие обязательной runtime-структуры на сервере и завершится ошибкой, если чего-то не хватает.
- Для "пустого" сервера сначала выполните обычный `make deploy` (без `--dry-run`) для bootstrap директорий/файлов.

Полезные варианты:

```bash
make deploy HOST=203.0.113.10
ARGS="--with-config-inc" make deploy
ARGS="--with-runtime-data" make deploy
make deploy-reload HOST=203.0.113.10
make deploy-pull HOST=203.0.113.10
make deploy-pull-data HOST=203.0.113.10
make deploy-pull-dry-run HOST=203.0.113.10
```

Опасные флаги `scripts/deploy/push-crm.sh`:

- `--delete` — удаляет в каталоге назначения файлы, которых нет в источнике синхронизации.
- `--full-perms` — полный рекурсивный прогон прав (медленно).
- `--source <path>` — при ошибке пути можно отправить на сервер не тот каталог.
- `--with-runtime-data` — может перезаписать runtime-данные (`storage`, `cache`, uploads и т.д.).
- `--with-config-inc` — включает синхронизацию `config.inc.php` (по умолчанию выключена).

## Переменные

| Переменная | Где используется | Значение по умолчанию |
|---|---|---|
| `SERVICE` | `logs`, `compose-exec` | `apache` |
| `CMD` | `compose-exec` | обязателен |
| `FILE` | `db-import`, `db-import-pv` | обязателен |
| `HOST` | `deploy*` | из `.env.deploy` или параметров скрипта |
| `ARGS` | `deploy*` | пусто |
| `COMPOSE` | все compose-команды | `docker compose` |
| `APACHE_SERVICE` | `sh-apache`, `tracking`, `vtiger-cron` | `apache` |
| `MYSQL_SERVICE` | db/mysql команды | `mysql` |
| `DUMP_DIR` | `db-dump*`, `db-import*` | `dump` |
