-- Лабораторная работа №2. Создание функций.
-- Запускается на базе из лабораторной работы №1
-- (init_db.sql, alter_db.sql, fill_db.sql).

-- 1. Сумма двух чисел.
CREATE OR REPLACE FUNCTION fn_add_numbers(p_a NUMERIC, p_b NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN p_a + p_b;
END;
$$;

-- 2. Дата, которая будет послезавтра.
CREATE OR REPLACE FUNCTION fn_day_after_tomorrow()
RETURNS DATE
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN CURRENT_DATE + 2;
END;
$$;

-- 3. Сумма всех проведённых платежей.
CREATE OR REPLACE FUNCTION fn_payments_total()
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(p.amount), 0)
      INTO v_total
      FROM payments AS p;

    RETURN v_total;
END;
$$;

-- 4. Создание «противоположного» платежа: та же сумма,
--    плательщик и получатель меняются местами.
--    Возвращает id нового платежа.
CREATE OR REPLACE FUNCTION fn_reverse_payment(p_id_payment INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INT;
BEGIN
    INSERT INTO payments (amount, id_account_from, id_account_to)
    SELECT p.amount,
           p.id_account_to,
           p.id_account_from
      FROM payments AS p
     WHERE p.id = p_id_payment
    RETURNING id
      INTO v_new_id;

    IF v_new_id IS NULL THEN
        RAISE EXCEPTION 'Платёж с id = % не найден', p_id_payment;
    END IF;

    RETURN v_new_id;
END;
$$;

-- 5. Все исходящие платежи клиента (дата, сумма, кому)
--    между двумя датами включительно.
CREATE OR REPLACE FUNCTION fn_client_outgoing_payments(
    p_id_client INT,
    p_date_from DATE,
    p_date_to   DATE
)
RETURNS TABLE (
    dt     TIMESTAMP,
    amount NUMERIC(20, 2),
    payee  TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT p.dt,
           p.amount,
           c_to.label
      FROM payments AS p
           INNER JOIN accounts AS a_from
           ON a_from.id = p.id_account_from
           INNER JOIN accounts AS a_to
           ON a_to.id = p.id_account_to
           INNER JOIN clients AS c_to
           ON c_to.id = a_to.id_client
     WHERE a_from.id_client = p_id_client
       AND p.dt >= p_date_from
       AND p.dt < p_date_to + 1
     ORDER BY p.dt,
              p.id;
END;
$$;

-- 6. Количество платежей между двумя клиентами (в обе стороны).
CREATE OR REPLACE FUNCTION fn_payments_count_between(
    p_id_client_1 INT,
    p_id_client_2 INT
)
RETURNS BIGINT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_count BIGINT;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM payments AS p
           INNER JOIN accounts AS a_from
           ON a_from.id = p.id_account_from
           INNER JOIN accounts AS a_to
           ON a_to.id = p.id_account_to
     WHERE (a_from.id_client = p_id_client_1
            AND a_to.id_client = p_id_client_2)
        OR (a_from.id_client = p_id_client_2
            AND a_to.id_client = p_id_client_1);

    RETURN v_count;
END;
$$;

-- 7. Создание записи в таблице payments.
--    Возвращает id нового платежа.
CREATE OR REPLACE FUNCTION fn_create_payment(
    p_dt              TIMESTAMP,
    p_amount          NUMERIC,
    p_id_account_from INT,
    p_id_account_to   INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INT;
BEGIN
    INSERT INTO payments (dt, amount, id_account_from, id_account_to)
    VALUES (p_dt, p_amount, p_id_account_from, p_id_account_to)
    RETURNING id
      INTO v_new_id;

    RETURN v_new_id;
END;
$$;

-- 8. Создание платежа с изменением балансов: сумма списывается
--    со счёта плательщика и зачисляется на счёт получателя.
--    Возвращает id нового платежа.
CREATE OR REPLACE FUNCTION fn_transfer(
    p_amount          NUMERIC,
    p_id_account_from INT,
    p_id_account_to   INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INT;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Сумма платежа должна быть положительной';
    END IF;

    INSERT INTO payments (amount, id_account_from, id_account_to)
    VALUES (p_amount, p_id_account_from, p_id_account_to)
    RETURNING id
      INTO v_new_id;

    UPDATE accounts
       SET balance = balance - p_amount
     WHERE id = p_id_account_from;

    UPDATE accounts
       SET balance = balance + p_amount
     WHERE id = p_id_account_to;

    RETURN v_new_id;
END;
$$;

-- 9. Создание n платежей с заданной датой; счета и сумма случайные.
--    Счета выбираются из таблицы accounts, поэтому ссылки корректны.
--    Возвращает количество созданных записей.
CREATE OR REPLACE FUNCTION fn_generate_payments(p_dt TIMESTAMP, p_n INT)
RETURNS INT
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

    RETURN p_n;
END;
$$;
