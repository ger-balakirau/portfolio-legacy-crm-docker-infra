# Portfolio Legacy CRM Docker Infra

Обезличенный пример инфраструктурного репозитория для legacy PHP CRM.

Код CRM хранится в отдельном репозитории и подключается в контейнер через `APP_CODE_PATH`. Этот репозиторий содержит только окружение: Dockerfile, Docker Compose, runtime-конфиги, настройки Apache/PHP/MySQL, Makefile и вспомогательные скрипты.

## Стек

- PHP 7.0 + Apache для совместимости со старым CRM-кодом.
- MySQL 5.7.
- Runtime-конфиги CRM из `configs/crm/`.
- Управление через `make`.
- Импорт/экспорт БД через Docker Compose.
- Опциональный deploy/sync скрипт на базе `rsync + ssh`.

## Структура

```text
legacy-crm-docker-infra/
  Dockerfile
  docker-compose.yml
  configs/crm/       # обезличенные runtime config templates
  prod.conf/         # Apache, PHP и MySQL tuning
  scripts/           # dev/deploy helper scripts
  docs/              # документация по запуску и командам
```

Ожидаемый путь к коду приложения:

```text
./html/example-crm.local/crm
```

Путь можно переопределить в `.env`:

```bash
APP_CODE_PATH=/path/to/app/root
```

## Быстрый старт

```bash
cp env.example .env
git clone <PRIVATE_APP_REPO> html/example-crm.local/crm
make up-build
make db-import FILE=dump/example.sql.gz
make crm-init
make ps
```

## Основные команды

```bash
make up
make down
make restart
make logs
make logs SERVICE=mysql
make sh-apache
make db-dump
make db-import FILE=dump/example.sql.gz
make crm-init
```

## Что демонстрирует проект

- Изоляцию legacy-приложения в воспроизводимом Docker-окружении.
- Отделение infra-репозитория от кода приложения.
- Подключение runtime-конфигов поверх CRM-кода через bind mounts.
- Makefile как единый интерфейс для Docker, БД и сервисных задач.
- Безопасные defaults: реальные `.env`, дампы, SSH-ключи и runtime-данные не входят в репозиторий.

## Примечание

Это портфолио-версия. Реальные домены, credentials, дампы, SSH-настройки и код CRM не включены.
