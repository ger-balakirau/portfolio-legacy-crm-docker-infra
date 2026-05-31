# Запуск С Нуля

Пошаговая инструкция для нового ПК: как скачать репозитории, создать папки, запустить окружение и проверить, что CRM работает.

Стек проекта: `PHP 7.0 + Debian Stretch + MySQL 5.7` (legacy).

## 1) Что должно быть установлено

Проверьте инструменты:

```bash
git --version
docker --version
docker compose version
make --version
```

Если какой-то команды нет, установите ее в системе и повторите проверку.

## 2) Скачайте infra-репозиторий

Создайте рабочую папку и клонируйте проект:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/example/legacy-crm-docker-infra.git legacy-crm
```

## 3) Подготовьте папки с кодом CRM

По умолчанию инфраструктура ожидает код CRM в `./html/example-crm.local/crm`.

```bash
cd ~/projects/legacy-crm
git clone <PRIVATE_CRM_REPO> html/example-crm.local/crm
```

Если хотите хранить CRM-код в другом месте, задайте `APP_CODE_PATH` в `.env`.

## 4) Создайте локальный `.env`

```bash
cp env.example .env
```

Проверьте минимум:

- `APP_CODE_PATH` указывает на папку, где лежит `crm`
- `CRM_CONFIG_PATH=./configs/crm` (обычно оставляем как есть)
- параметры MySQL заполнены

## 5) Проверка `.legacy-crm` для защищенных endpoint'ов

По умолчанию `docker-compose` монтирует `configs/crm/.legacy-crm.example` как `crm/.legacy-crm`.

В репозитории уже лежит валидный dev-вариант:

- login: `dev`
- password: `dev`

Этого достаточно для локальной разработки после `git clone` без дополнительных ручных шагов.

## 6) Первый запуск (сборка образов)

```bash
make up-build
make ps
```

> **ВАЖНО:** <u>без импорта рабочего дампа базы данных CRM не будет работать.</u>  
> Интерфейс может открываться, но данные, бизнес-процессы и cron-задачи не будут работать.
> После первого запуска контейнеров выполняйте шаги строго по порядку: импорт дампа, затем `crm-init`.  
> Иначе система будет в "пустом" состоянии или с некорректными правами/процессами.
>
> ```bash
> make db-import FILE=dump/<YOUR_FILE>.sql.gz
> make crm-init
> ```

`make crm-init` безопасно запускать повторно. Команда:

- подготавливает runtime-каталоги/файлы, которые обычно не лежат в git (`includes/runtime/cache`, `user_privileges`);
- пересоздает `user_privileges_*.php` и `sharing_privileges_*.php` из текущей БД.

Проверка:

- CRM: `http://localhost:8081`
- MySQL: `127.0.0.1:33063`

Логи:

```bash
make logs
```

Остановить окружение:

```bash
make down
```

## 7) Ежедневная работа

Обычно достаточно:

```bash
make up
make ps
```

Если менялся `Dockerfile` или build context:

```bash
make up-build
```

Если нужен полностью чистый rebuild образов:

```bash
make rebuild
make up
```

## 8) Базовые команды CRM

```bash
make tracking
make vtiger-cron
```

## 9) Бэкап и импорт БД

Создать дамп:

```bash
make db-dump
```

Импорт:

```bash
make db-import FILE=dump/<YOUR_FILE>.sql.gz
```

## 10) Deploy (опционально)

Создать deploy-конфиг:

```bash
cp .env.deploy.example .env.deploy
```

Проверка без изменений:

```bash
make deploy-dry
```

`make deploy-dry` не создает директории/файлы на сервере: только проверяет.

Реальный деплой:

```bash
make deploy
```

Если нужен принудительный сброс OPCache в `apache2` (`mod_php`):

```bash
make deploy-reload
```

Синхронизация данных/кода с сервера в локальную CRM-директорию:

```bash
make deploy-pull
make deploy-pull-data
make deploy-pull-dry-run
```

## 11) Если что-то не работает

1. Проверить статусы: `make ps`
2. Посмотреть логи: `make logs` и `make logs SERVICE=mysql`
3. Проверить переменные в `.env` (`APP_CODE_PATH`, MySQL параметры)
4. Проверить, что директория `APP_CODE_PATH` содержит `crm`
