-- Лабораторная работа №2. Демонстрация работы функций.
-- Запускается после create_functions.sql.
-- Все изменения выполняются в транзакции и в конце откатываются,
-- поэтому скрипт можно запускать повторно на тех же данных.
-- Чтобы сохранить изменения, замените ROLLBACK на COMMIT.

BEGIN;

-- 1. Сумма двух чисел: ожидается 42.5.
SELECT fn_add_numbers(40, 2.5) AS sum_result;

-- 2. Послезавтра: рядом показана сегодняшняя дата.
SELECT CURRENT_DATE AS today,
       fn_day_after_tomorrow() AS day_after_tomorrow;

-- 3. Сумма всех платежей: совпадает с прямым запросом SUM.
SELECT fn_payments_total() AS total_by_function,
       (SELECT SUM(amount) FROM payments) AS total_by_query;

-- 4. «Противоположный» платёж для платежа 1 (счёт 9 -> счёт 2).
SELECT fn_reverse_payment(1) AS reversed_payment_id;

SELECT p.id,
       p.dt,
       p.amount,
       p.id_account_from,
       p.id_account_to
  FROM payments AS p
 WHERE p.id = 1
    OR p.id = (SELECT MAX(id) FROM payments)
 ORDER BY p.id;

-- 5. Исходящие платежи клиента 2 с 1 по 5 ноября 2026 года.
SELECT *
  FROM fn_client_outgoing_payments(2, '2026-11-01', '2026-11-05');

-- 6. Количество платежей между клиентами 1 и 2;
--    порядок аргументов на результат не влияет.
SELECT fn_payments_count_between(1, 2) AS count_1_2,
       fn_payments_count_between(2, 1) AS count_2_1;

-- 7. Создание платежа с заданной датой.
SELECT fn_create_payment('2026-11-11 12:00:00', 1500.00, 1, 3)
       AS created_payment_id;

SELECT p.id,
       p.dt,
       p.amount,
       p.id_account_from,
       p.id_account_to
  FROM payments AS p
 WHERE p.id = (SELECT MAX(id) FROM payments);

-- 8. Платёж с изменением балансов: балансы счетов 1 и 2 до и после.
SELECT a.id,
       a.balance AS balance_before
  FROM accounts AS a
 WHERE a.id IN (1, 2)
 ORDER BY a.id;

SELECT fn_transfer(1000.00, 1, 2) AS transfer_payment_id;

SELECT a.id,
       a.balance AS balance_after
  FROM accounts AS a
 WHERE a.id IN (1, 2)
 ORDER BY a.id;

-- 9. Пять случайных платежей с датой 12 ноября 2026 года.
SELECT fn_generate_payments('2026-11-12 09:00:00', 5) AS generated_count;

SELECT p.id,
       p.dt,
       p.amount,
       p.id_account_from,
       p.id_account_to
  FROM payments AS p
 WHERE p.dt = '2026-11-12 09:00:00'
 ORDER BY p.id;

ROLLBACK;
