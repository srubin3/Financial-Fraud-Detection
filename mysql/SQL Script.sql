USE finance_alpha;

CREATE TABLE transactions (
	`index` INT,
    trans_datetime DATETIME,
    cc_num VARCHAR(20),
    merchant VARCHAR(75),
    category VARCHAR(50),
    amt DECIMAL(10, 2),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    street VARCHAR(100),
    city VARCHAR(100),
    state CHAR(2),
    zip INT,
    lat DECIMAL (9, 6),
    `long` DECIMAL (9, 6), 
    city_pop INT,
    job VARCHAR(100),
    dob DATE,
    trans_num VARCHAR(50),
    unix_time INT,
    merch_lat DECIMAL(9, 6),
    merch_long DECIMAL(9, 6),
    is_fraud INT,
    PRIMARY KEY (`index`)
);

SET GLOBAL max_allowed_packet = 1073741824;
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

SELECT COUNT(*)
FROM transactions;

DESCRIBE transactions;

SELECT *
FROM transactions;

CREATE TABLE locations (
	cc_num BIGINT PRIMARY KEY,
    lat DECIMAL (9, 6),
    `long` DECIMAL (9,6)
);

DESCRIBE transactions;

SELECT COUNT(*) AS total_transactions
FROM transactions;

SELECT merchant, COUNT(*) AS transaction_count
FROM transactions
GROUP BY merchant
ORDER BY transaction_count DESC
LIMIT 10;

SELECT category, AVG(amt) AS average_transaction_amount
FROM transactions
GROUP BY category
ORDER BY AVG(amt) DESC;

SELECT 
	SUM(is_fraud) AS fraudulent_transactions,
    COUNT(*) AS total_transactions,
    (SUM(is_fraud) * 100 / COUNT(*)) AS fraud_percentage
FROM transactions;

SELECT city, MAX(city_pop) AS population
FROM transactions
GROUP BY city
ORDER BY population DESC
LIMIT 1;

SELECT MIN(trans_datetime) AS earliest_date, MAX(trans_datetime) AS latest_date
FROM transactions;

SELECT SUM(amt) as total_amount_spent
FROM transactions;

SELECT gender, AVG(amt) AS avg_transaction_amount
FROM transactions
GROUP BY gender;

SELECT 
	DAYOFWEEK(trans_datetime) AS day_of_week,
    DAYNAME(trans_datetime) AS day_name,
    AVG(amt) AS avg_transaction_amount
FROM transactions
GROUP BY DAYOFWEEK(trans_datetime), DAYNAME(trans_datetime)
ORDER BY avg_transaction_amount DESC
LIMIT 1;