-- Лабораторная работа №1. Создание таблиц.

CREATE TABLE IF NOT EXISTS clients (
    id    SERIAL PRIMARY KEY,
    label TEXT
);

CREATE TABLE IF NOT EXISTS account_statuses (
    id    SERIAL PRIMARY KEY,
    label TEXT
);

CREATE TABLE IF NOT EXISTS accounts (
    id        SERIAL PRIMARY KEY,
    balance   NUMERIC(20, 2),
    is_system INT,
    id_client INT REFERENCES clients (id)
);

CREATE TABLE IF NOT EXISTS payments (
    id              SERIAL PRIMARY KEY,
    dt              TIMESTAMP,
    amount          NUMERIC(20, 2),
    id_account_from INT REFERENCES accounts (id),
    id_account_to   INT REFERENCES accounts (id)
);

CREATE TABLE IF NOT EXISTS archive_payments (
    id              SERIAL PRIMARY KEY,
    dt              TIMESTAMP,
    amount          NUMERIC(20, 2),
    id_account_from INT REFERENCES accounts (id),
    id_account_to   INT REFERENCES accounts (id)
);
