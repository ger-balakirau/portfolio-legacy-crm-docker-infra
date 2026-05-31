# Git Шпаргалка

Главный принцип: **перед любой работой сначала подтяни изменения из удалённой ветки**.

## 0) Перед началом работы (обязательно)

```bash
# в корне репозитория
git switch main
git pull --ff-only origin main
```

Если работаешь не в `main`, сначала обнови базу и только потом переключайся в рабочую ветку:

```bash
git switch main
git pull --ff-only origin main
git switch <your-branch>
```

## 1) Проверить где ты и что изменено

```bash
git branch --show-current
git status --short
git branch -a
```

## 2) Переключиться в ветку

```bash
git switch <branch>
```

Если ветки нет локально, но есть на origin:

```bash
git fetch origin
git switch <branch>
```

## 3) Создать новую ветку

```bash
git switch -c feature/<task-name>
```

## 4) Сделать коммит (основное)

```bash
git status --short
git add <file>
# или сразу всё:
# git add -A

git commit -m "type: short description"
```

Примеры:

- `fix: handle empty env var`
- `docs: update git cheatsheet`
- `chore: rename project to legacy-crm`

## 5) Сделать push

Для текущей ветки:

```bash
git push
```

Первый push новой ветки:

```bash
git push -u origin <branch>
```

## 6) Сделать pull

Только fast-forward (без лишних merge-коммитов):

```bash
git pull --ff-only
```

Явно из нужной ветки:

```bash
git pull --ff-only origin main
```

## 7) Быстрый ежедневный сценарий

```bash
# 1) синхронизация
git switch main
git pull --ff-only origin main

# 2) работа
git switch -c feature/<task-name>
# ...редактирование файлов...
git add -A
git commit -m "feat: ..."

# 3) публикация
git push -u origin feature/<task-name>
```

## 8) Полезно при ошибках

Push отклонён (`non-fast-forward`):

```bash
git pull --ff-only
# если не получилось, проверить расхождение:
git status
git log --oneline --decorate --graph -20
```

Убрать файл из staged:

```bash
git restore --staged <file>
```

Откатить незафиксированные изменения файла:

```bash
git restore <file>
```

## 9) Откат к старым коммитам

Посмотреть историю:

```bash
git log --oneline --decorate -20
```

Безопасный откат уже запушенного коммита (создаёт новый обратный коммит):

```bash
git revert <commit>
git push
```

Откат нескольких последних коммитов безопасно:

```bash
git revert --no-edit HEAD~2..HEAD
git push
```

Временно перейти на старый коммит (режим detached HEAD):

```bash
git switch --detach <commit>
# вернуться обратно:
git switch <branch>
```

Жёсткий локальный откат ветки на старый коммит (переписывает историю, осторожно):

```bash
git reset --hard <commit>
# если коммиты уже были на remote:
git push --force-with-lease
```

## 10) Мини-чеклист перед push

- `git branch --show-current` -> ты в правильной ветке
- `git pull --ff-only` выполнен до начала работы
- `git status` чистый после коммита
- сообщение коммита понятное и короткое

## Источники (официальные)

- Git `git pull`: https://git-scm.com/docs/git-pull
- Git `git switch`: https://git-scm.com/docs/git-switch
- Git `git branch`: https://git-scm.com/docs/git-branch
- Git `git commit`: https://git-scm.com/docs/git-commit
- Git `git push`: https://git-scm.com/docs/git-push
- Git `git revert`: https://git-scm.com/docs/git-revert
- Git `git reset`: https://git-scm.com/docs/git-reset
- GitHub Docs (push): https://docs.github.com/en/enterprise-server%403.17/get-started/using-git/pushing-commits-to-a-remote-repository
