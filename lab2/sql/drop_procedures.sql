-- Лабораторная работа №2. Удаление процедур и таблицы pages.

DROP PROCEDURE IF EXISTS proc_get_root_page(TEXT);

DROP PROCEDURE IF EXISTS proc_create_page(TEXT, INT);

DROP PROCEDURE IF EXISTS proc_check_client_balance(INT);

DROP PROCEDURE IF EXISTS proc_generate_payments(TIMESTAMP, INT);

DROP PROCEDURE IF EXISTS proc_transfer_dated(NUMERIC, INT, INT, TIMESTAMP);

DROP PROCEDURE IF EXISTS proc_transfer(NUMERIC, INT, INT);

DROP PROCEDURE IF EXISTS proc_create_payment(TIMESTAMP, NUMERIC, INT, INT);

DROP TABLE IF EXISTS pages;
