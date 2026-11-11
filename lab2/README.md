# Лабораторная работа №2 — Серверное программирование: процедуры и функции

Работа выполняется на базе из лабораторной работы №1 (таблицы созданы, изменены и заполнены
скриптами `init_db.sql`, `alter_db.sql`, `fill_db.sql`).

## Состав

| Путь | Что это |
|---|---|
| `sql/create_functions.sql` | 9 функций |
| `sql/perform_functions.sql` | демонстрация работы функций |
| `sql/drop_functions.sql` | удаление функций |
| `sql/create_procedures.sql` | таблица `pages` и 7 процедур |
| `sql/perform_procedures.sql` | демонстрация работы процедур |
| `sql/drop_procedures.sql` | удаление процедур и таблицы `pages` |
| `report/lab2_report.docx` | отчёт (титульный лист с заглушками в квадратных скобках) |

## Запуск

Контейнер тот же, что в лабораторной работе №1; папка `lab2/sql` подключена в него как `/lab2`.
Команды выполняются из папки `lab1`. После обновления `docker-compose.yml` контейнер нужно
пересоздать (данные сохраняются):

```bash
docker compose up -d
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/create_functions.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/perform_functions.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/drop_functions.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/create_procedures.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/perform_procedures.sql
```

```bash
docker compose exec db psql -U postgres -d test_db -f /lab2/drop_procedures.sql
```

Скрипты `perform_*` выполняются в транзакции и заканчиваются `ROLLBACK`, поэтому данные
лабораторной работы №1 не меняются и скрипты можно запускать повторно.

## Соглашения

Code style тот же, что в лабораторной работе №1. Дополнительно:

- функции называются с префиксом `fn_`, процедуры — с префиксом `proc_`;
- параметры — с префиксом `p_`, локальные переменные — с префиксом `v_`
  (так они не путаются с именами столбцов);
- тело подпрограммы — в долларовых кавычках `$$`, отступ внутри `BEGIN … END` — 4 пробела;
- «id плательщика» и «id получателя» в подпрограммах создания платежей — это id счетов
  (как в таблице `payments`); в функциях про клиентов — id клиентов.
