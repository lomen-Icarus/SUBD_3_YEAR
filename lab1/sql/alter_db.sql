-- Лабораторная работа №1. Изменение схемы данных.
-- Запускается после init_db.sql.

-- Счета: статус счёта (внешний ключ к таблице статусов).
ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS id_status INT REFERENCES account_statuses (id);

-- Счета: признак системного счёта больше не нужен.
ALTER TABLE accounts
 DROP COLUMN IF EXISTS is_system;

-- Счета: дата создания.
ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS creation_date DATE;

-- Счета: баланс по умолчанию 0.
ALTER TABLE accounts
ALTER COLUMN balance SET DEFAULT 0;

-- Платежи: дата и время по умолчанию - текущие.
ALTER TABLE payments
ALTER COLUMN dt SET DEFAULT CURRENT_TIMESTAMP;

-- Платежи: дата и время, сумма обязательны.
ALTER TABLE payments
ALTER COLUMN dt SET NOT NULL;

ALTER TABLE payments
ALTER COLUMN amount SET NOT NULL;
