-- Лабораторная работа №2. Создание процедур.
-- Запускается на базе из лабораторной работы №1
-- (init_db.sql, alter_db.sql, fill_db.sql).

-- Таблица страниц с иерархией: id_parent ссылается на родителя.
CREATE TABLE IF NOT EXISTS pages (
    id        SERIAL PRIMARY KEY,
    label     TEXT NOT NULL,
    id_parent INT REFERENCES pages (id)
);

-- 1. Создание записи в таблице payments.
CREATE OR REPLACE PROCEDURE proc_create_payment(
    IN p_dt              TIMESTAMP,
    IN p_amount          NUMERIC,
    IN p_id_account_from INT,
    IN p_id_account_to   INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO payments (dt, amount, id_account_from, id_account_to)
    VALUES (p_dt, p_amount, p_id_account_from, p_id_account_to);
END;
$$;

-- 2. Создание платежа с изменением балансов: сумма списывается
--    со счёта плательщика и зачисляется на счёт получателя.
--    В p_new_id возвращается id нового платежа.
CREATE OR REPLACE PROCEDURE proc_transfer(
    IN  p_amount          NUMERIC,
    IN  p_id_account_from INT,
    IN  p_id_account_to   INT,
    OUT p_new_id          INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Сумма платежа должна быть положительной';
    END IF;

    INSERT INTO payments (amount, id_account_from, id_account_to)
    VALUES (p_amount, p_id_account_from, p_id_account_to)
    RETURNING id
      INTO p_new_id;

    UPDATE accounts
       SET balance = balance - p_amount
     WHERE id = p_id_account_from;

    UPDATE accounts
       SET balance = balance + p_amount
     WHERE id = p_id_account_to;
END;
$$;

-- 3. То же с заданной датой платежа. Если платёж старше сегодняшнего
--    дня более чем на две недели, такая же запись создаётся
--    и в таблице archive_payments.
CREATE OR REPLACE PROCEDURE proc_transfer_dated(
    IN  p_amount          NUMERIC,
    IN  p_id_account_from INT,
    IN  p_id_account_to   INT,
    IN  p_dt              TIMESTAMP,
    OUT p_new_id          INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Сумма платежа должна быть положительной';
    END IF;

    INSERT INTO payments (dt, amount, id_account_from, id_account_to)
    VALUES (p_dt, p_amount, p_id_account_from, p_id_account_to)
    RETURNING id
      INTO p_new_id;

    UPDATE accounts
       SET balance = balance - p_amount
     WHERE id = p_id_account_from;

    UPDATE accounts
       SET balance = balance + p_amount
     WHERE id = p_id_account_to;

    IF p_dt < CURRENT_DATE - INTERVAL '2 weeks' THEN
        INSERT INTO archive_payments (dt, amount, id_account_from,
                                      id_account_to)
        VALUES (p_dt, p_amount, p_id_account_from, p_id_account_to);
    END IF;
END;
$$;

-- 4. Создание n платежей с заданной датой; счета и сумма случайные.
--    Счета выбираются из таблицы accounts, поэтому ссылки корректны.
CREATE OR REPLACE PROCEDURE proc_generate_payments(
    IN p_dt TIMESTAMP,
    IN p_n  INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_account_from INT;
    v_id_account_to   INT;
BEGIN
    IF p_n < 0 THEN
        RAISE EXCEPTION 'Количество платежей не может быть отрицательным';
    END IF;

    IF (SELECT COUNT(*) FROM accounts) < 2 THEN
        RAISE EXCEPTION 'Для платежа нужно минимум два счёта';
    END IF;

    FOR i IN 1..p_n LOOP
        SELECT a.id
          INTO v_id_account_from
          FROM accounts AS a
         ORDER BY random()
         LIMIT 1;

        SELECT a.id
          INTO v_id_account_to
          FROM accounts AS a
         WHERE a.id <> v_id_account_from
         ORDER BY random()
         LIMIT 1;

        INSERT INTO payments (dt, amount, id_account_from, id_account_to)
        VALUES (p_dt,
                ROUND((random() * 49900 + 100)::NUMERIC, 2),
                v_id_account_from,
                v_id_account_to);
    END LOOP;
END;
$$;

-- 5. Проверка балансов клиента. Расчётный баланс счёта - это сумма
--    входящих платежей минус сумма исходящих (по таблице payments).
--    p_is_correct - TRUE, если у всех счетов клиента баланс совпадает
--    с расчётным; p_delta - суммарная разница (хранимый минус расчётный).
CREATE OR REPLACE PROCEDURE proc_check_client_balance(
    IN  p_id_client  INT,
    OUT p_is_correct BOOLEAN,
    OUT p_delta      NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(BOOL_AND(b.balance = b.calculated), TRUE),
           COALESCE(SUM(b.balance - b.calculated), 0)
      INTO p_is_correct,
           p_delta
      FROM (SELECT COALESCE(a.balance, 0) AS balance,
                   (SELECT COALESCE(SUM(p.amount), 0)
                      FROM payments AS p
                     WHERE p.id_account_to = a.id)
                   - (SELECT COALESCE(SUM(p.amount), 0)
                        FROM payments AS p
                       WHERE p.id_account_from = a.id) AS calculated
              FROM accounts AS a
             WHERE a.id_client = p_id_client) AS b;
END;
$$;

-- 6. Создание записи в таблице pages. Если p_id_parent равен NULL,
--    создаётся страница верхнего уровня.
--    В p_new_id возвращается id новой записи.
CREATE OR REPLACE PROCEDURE proc_create_page(
    IN  p_label     TEXT,
    IN  p_id_parent INT,
    OUT p_new_id    INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO pages (label, id_parent)
    VALUES (p_label, p_id_parent)
    RETURNING id
      INTO p_new_id;
END;
$$;

-- 7. Поиск самого верхнего уровня иерархии для страницы с заданным
--    названием. Если страница не найдена, p_root_id равен NULL.
CREATE OR REPLACE PROCEDURE proc_get_root_page(
    IN  p_label   TEXT,
    OUT p_root_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    WITH RECURSIVE page_path AS (
        SELECT pg.id,
               pg.id_parent
          FROM pages AS pg
         WHERE pg.label = p_label
         UNION ALL
        SELECT parent.id,
               parent.id_parent
          FROM pages AS parent
               INNER JOIN page_path AS child
               ON child.id_parent = parent.id
    )
    SELECT pp.id
      INTO p_root_id
      FROM page_path AS pp
     WHERE pp.id_parent IS NULL
     LIMIT 1;
END;
$$;
