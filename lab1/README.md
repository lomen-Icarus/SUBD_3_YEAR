# Лабораторная работа №1 — Реляционная СУБД PostgreSQL

## Состав

| Путь | Что это |
|---|---|
| `docker-compose.yml` | PostgreSQL 16 в Docker, база `test_db` |
| `sql/test_db.sql` | проверка подключения (`SELECT 1`) |
| `sql/init_db.sql` | создание таблиц |
| `sql/alter_db.sql` | изменение схемы (п. 6–7 задания) |
| `sql/fill_db.sql` | заполнение данными |
| `sql/select_from_db.sql` | 8 запросов на выборку |
| `sql/drop_db.sql` | удаление таблиц |
| `diagrams/lab1_er.drawio` | диаграммы для draw.io (2 страницы: до и после изменений) |
| `diagrams/er_before.png`, `diagrams/er_after.png` | те же диаграммы картинками |
| `../lab2` | лабораторная работа №2 (подключена в контейнер как `/lab2`) |
| `report/lab1_report.docx` | отчёт (титульный лист с заглушками в квадратных скобках) |

## Запуск

Нужен установленный и запущенный Docker Desktop. Команды выполняются из папки `lab1`.

```bash
docker compose up -d
```

Полный цикл: создание → изменение → заполнение → выборка → удаление.

```bash
docker compose exec db psql -U postgres -d test_db -f /sql/init_db.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /sql/alter_db.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /sql/fill_db.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /sql/select_from_db.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /sql/drop_db.sql
```

Подключение из DBeaver / pgAdmin: хост `localhost`, порт `5432`, база `test_db`,
пользователь `postgres`, пароль `postgres`.

## Code style

За основу взято руководство sqlstyle.guide (Simon Holywell).

Лексические правила (как именовать):

- имена таблиц и столбцов — латиница, нижний регистр, `snake_case`;
- таблицы — существительное во множественном числе (`clients`, `payments`);
- первичный ключ — `id`, внешний ключ — `id_<сущность>` (`id_client`, `id_account_from`);
  это осознанное отступление от руководства: так названы поля в образце к работе;
- псевдонимы таблиц — короткие, через `AS` (`payments AS p`); псевдонимы столбцов — осмысленные (`payer`, `total_amount`);
- ключевые слова, типы данных и функции — ВЕРХНИМ регистром.

Синтаксические правила (как располагать):

- ключевые слова запроса выравниваются по правому краю, образуя «реку» (`SELECT` / `FROM` / `WHERE` / `ORDER BY`);
- каждый столбец в `SELECT`, каждое условие и каждый `JOIN` — на отдельной строке;
- `JOIN` пишется с отступом под `FROM`, условие `ON` — на следующей строке;
- подзапросы — в скобках, с собственной «рекой»;
- пробелы вокруг `=`, после запятых; отступ — 4 пробела в `CREATE TABLE`;
- в `CREATE TABLE` один столбец на строку, типы выровнены в колонку;
- каждая команда заканчивается `;`, между командами пустая строка;
- перед каждой логической частью скрипта — комментарий `--`.
