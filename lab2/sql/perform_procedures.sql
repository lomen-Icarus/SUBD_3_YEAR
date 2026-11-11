-- Лабораторная работа №2. Демонстрация работы процедур.
-- Запускается после create_procedures.sql.
-- Все изменения выполняются в транзакции и в конце откатываются,
-- поэтому скрипт можно запускать повторно на тех же данных.
-- Чтобы сохранить изменения, замените ROLLBACK на COMMIT.

BEGIN;

-- 1. Создание платежа с заданной датой.
CALL proc_create_payment('2026-11-11 12:00:00', 1500.00, 1, 3);

SELECT p.id,
       p.dt,
       p.amount,
       p.id_account_from,
       p.id_account_to
  FROM payments AS p
 WHERE p.id = (SELECT MAX(id) FROM payments);

-- 2. Платёж с изменением балансов: балансы счетов 1 и 2 до и после.
SELECT a.id,
       a.balance AS balance_before
  FROM accounts AS a
 WHERE a.id IN (1, 2)
 ORDER BY a.id;

CALL proc_transfer(1000.00, 1, 2, NULL);

SELECT a.id,
       a.balance AS balance_after
  FROM accounts AS a
 WHERE a.id IN (1, 2)
 ORDER BY a.id;

-- 3. Платёж с датой. Вчерашний платёж в архив не попадает,
--    платёж месячной давности - попадает.
CALL proc_transfer_dated(200.00, 3, 4,
                         (CURRENT_DATE - 1)::TIMESTAMP, NULL);

SELECT COUNT(*) AS archive_count_after_recent
  FROM archive_payments;

CALL proc_transfer_dated(300.00, 3, 4,
                         (CURRENT_DATE - 30)::TIMESTAMP, NULL);

SELECT ap.id,
       ap.dt,
       ap.amount,
       ap.id_account_from,
       ap.id_account_to
  FROM archive_payments AS ap;

-- 4. Пять случайных платежей с датой 12 ноября 2026 года.
CALL proc_generate_payments('2026-11-12 09:00:00', 5);

SELECT p.id,
       p.dt,
       p.amount,
       p.id_account_from,
       p.id_account_to
  FROM payments AS p
 WHERE p.dt = '2026-11-12 09:00:00'
 ORDER BY p.id;

-- 5. Проверка балансов клиента 4. Начальные балансы заданы произвольно,
--    поэтому сначала ожидается FALSE и ненулевая разница.
CALL proc_check_client_balance(4, NULL, NULL);

--    Приводим балансы счетов клиента 4 к расчётным значениям:
--    теперь ожидается TRUE и разница 0.
UPDATE accounts AS a
   SET balance = (SELECT COALESCE(SUM(p.amount), 0)
                    FROM payments AS p
                   WHERE p.id_account_to = a.id)
                 - (SELECT COALESCE(SUM(p.amount), 0)
                      FROM payments AS p
                     WHERE p.id_account_from = a.id)
 WHERE a.id_client = 4;

CALL proc_check_client_balance(4, NULL, NULL);

-- 6. Заполнение таблицы pages в соответствии с иерархией.
--    Процедура вызывается из PL/pgSQL, id родителя берётся
--    из выходного параметра предыдущего вызова.
DO $$
DECLARE
    v_main_id     INT;
    v_payments_id INT;
    v_accounts_id INT;
    v_offices_id  INT;
    v_new_id      INT;
BEGIN
    CALL proc_create_page('Главная', NULL, v_main_id);
    CALL proc_create_page('Платежи', v_main_id, v_payments_id);
    CALL proc_create_page('Счета', v_main_id, v_accounts_id);
    CALL proc_create_page('Исходящие платежи', v_payments_id, v_new_id);
    CALL proc_create_page('Входящие платежи', v_payments_id, v_new_id);
    CALL proc_create_page('Архивные счета', v_accounts_id, v_new_id);
    CALL proc_create_page('Офисы', NULL, v_offices_id);
    CALL proc_create_page('Клиенты', v_offices_id, v_new_id);
END;
$$;

SELECT pg.id,
       pg.label,
       pg.id_parent,
       parent.label AS parent_label
  FROM pages AS pg
       LEFT JOIN pages AS parent
       ON parent.id = pg.id_parent
 ORDER BY pg.id;

-- 7. Верхний уровень иерархии. Ожидается: для «Исходящие платежи»
--    и «Счета» - id страницы «Главная», для «Клиенты» и «Офисы» -
--    id страницы «Офисы», для несуществующей страницы - NULL.
CALL proc_get_root_page('Исходящие платежи', NULL);

CALL proc_get_root_page('Счета', NULL);

CALL proc_get_root_page('Клиенты', NULL);

CALL proc_get_root_page('Офисы', NULL);

CALL proc_get_root_page('Несуществующая страница', NULL);

ROLLBACK;
