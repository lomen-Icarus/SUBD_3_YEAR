-- Лабораторная работа №2. Удаление функций.

DROP FUNCTION IF EXISTS fn_generate_payments(TIMESTAMP, INT);

DROP FUNCTION IF EXISTS fn_transfer(NUMERIC, INT, INT);

DROP FUNCTION IF EXISTS fn_create_payment(TIMESTAMP, NUMERIC, INT, INT);

DROP FUNCTION IF EXISTS fn_payments_count_between(INT, INT);

DROP FUNCTION IF EXISTS fn_client_outgoing_payments(INT, DATE, DATE);

DROP FUNCTION IF EXISTS fn_reverse_payment(INT);

DROP FUNCTION IF EXISTS fn_payments_total();

DROP FUNCTION IF EXISTS fn_day_after_tomorrow();

DROP FUNCTION IF EXISTS fn_add_numbers(NUMERIC, NUMERIC);
