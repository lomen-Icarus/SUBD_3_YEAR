-- Лабораторная работа №1. Запросы на выборку.

-- 1. Клиенты, являющиеся плательщиками хотя бы по одному платежу.
SELECT DISTINCT c.label AS payer
  FROM payments AS p
       INNER JOIN accounts AS a
       ON a.id = p.id_account_from
       INNER JOIN clients AS c
       ON c.id = a.id_client
 ORDER BY payer;

-- 2. Клиенты, являющиеся получателями хотя бы по одному платежу.
SELECT DISTINCT c.label AS payee
  FROM payments AS p
       INNER JOIN accounts AS a
       ON a.id = p.id_account_to
       INNER JOIN clients AS c
       ON c.id = a.id_client
 ORDER BY payee;

-- 3. id платежа с самой большой суммой.
SELECT p.id
  FROM payments AS p
 WHERE p.amount = (SELECT MAX(amount)
                     FROM payments);

-- 4. id трёх последних по дате платежей.
SELECT p.id
  FROM payments AS p
 ORDER BY p.dt DESC,
          p.id DESC
 LIMIT 3;

-- 5. Общая сумма всех проведённых платежей.
SELECT SUM(p.amount) AS total_amount
  FROM payments AS p;

-- 6. Количество исходящих платежей по каждому счёту.
SELECT a.id AS id_account,
       COUNT(p.id) AS outgoing_count
  FROM accounts AS a
       LEFT JOIN payments AS p
       ON p.id_account_from = a.id
 GROUP BY a.id
 ORDER BY a.id;

-- 7. Количество входящих платежей по каждому счёту.
SELECT a.id AS id_account,
       COUNT(p.id) AS incoming_count
  FROM accounts AS a
       LEFT JOIN payments AS p
       ON p.id_account_to = a.id
 GROUP BY a.id
 ORDER BY a.id;

-- 8. Все платежи: дата, сумма, счёт и клиент получателя,
--    счёт и клиент плательщика; по убыванию даты.
SELECT p.dt,
       p.amount,
       p.id_account_to,
       c_to.label AS payee,
       p.id_account_from,
       c_from.label AS payer
  FROM payments AS p
       INNER JOIN accounts AS a_to
       ON a_to.id = p.id_account_to
       INNER JOIN clients AS c_to
       ON c_to.id = a_to.id_client
       INNER JOIN accounts AS a_from
       ON a_from.id = p.id_account_from
       INNER JOIN clients AS c_from
       ON c_from.id = a_from.id_client
 ORDER BY p.dt DESC,
          p.id DESC;
