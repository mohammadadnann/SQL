# Use the project database
USE business_operations_analytics;


# Populate the date dimension
INSERT INTO dim_date (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    month_label,
    day_name,
    is_weekend
)

WITH RECURSIVE date_series AS (
    SELECT DATE(MIN(invoice_date)) AS full_date
    FROM stg_transactions

    UNION ALL

    SELECT DATE_ADD(full_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE full_date < (
        SELECT DATE(MAX(invoice_date))
        FROM stg_transactions
    )
)

SELECT
    CAST(DATE_FORMAT(full_date, '%Y%m%d') AS UNSIGNED),
    full_date,
    DAY(full_date),
    MONTH(full_date),
    MONTHNAME(full_date),
    QUARTER(full_date),
    YEAR(full_date),
    DATE_FORMAT(full_date, '%Y-%m'),
    DAYNAME(full_date),
    DAYOFWEEK(full_date) IN (1, 7)
FROM date_series;


# Add an unknown customer member
INSERT INTO dim_customer (
    customer_id,
    customer_status
)
VALUES (
    NULL,
    'Unknown'
);


# Populate known customers
INSERT INTO dim_customer (
    customer_id,
    customer_status
)
SELECT DISTINCT
    customer_id,
    'Known'
FROM stg_transactions
WHERE customer_id IS NOT NULL
ORDER BY customer_id;


# Populate products using the latest known description
INSERT INTO dim_product (
    stock_code,
    description
)

WITH ranked_products AS (
    SELECT
        stock_code,
        description,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY
                description IS NULL,
                invoice_date DESC
        ) AS rn
    FROM stg_transactions
)

SELECT
    stock_code,
    description
FROM ranked_products
WHERE rn = 1;


# Populate locations
INSERT INTO dim_location (
    country
)
SELECT DISTINCT
    country
FROM stg_transactions
ORDER BY country;


# Populate the transaction fact table
INSERT INTO fact_transactions (
    invoice,
    date_key,
    customer_key,
    product_key,
    location_key,
    quantity,
    unit_price,
    line_value,
    transaction_type,
    record_status
)

SELECT
    s.invoice,
    CAST(DATE_FORMAT(s.invoice_date, '%Y%m%d') AS UNSIGNED),
    COALESCE(c.customer_key, unknown_customer.customer_key),
    p.product_key,
    l.location_key,
    s.quantity,
    s.unit_price,
    s.quantity * s.unit_price,
    s.transaction_type,
    s.record_status
FROM stg_transactions s

LEFT JOIN dim_customer c
    ON s.customer_id = c.customer_id

CROSS JOIN (
    SELECT customer_key
    FROM dim_customer
    WHERE customer_status = 'Unknown'
    LIMIT 1
) unknown_customer

INNER JOIN dim_product p
    ON s.stock_code = p.stock_code

INNER JOIN dim_location l
    ON s.country = l.country;


# Confirm dimension and fact counts
SELECT COUNT(*) AS date_rows
FROM dim_date;

SELECT COUNT(*) AS customer_rows
FROM dim_customer;

SELECT COUNT(*) AS product_rows
FROM dim_product;

SELECT COUNT(*) AS location_rows
FROM dim_location;

SELECT COUNT(*) AS fact_rows
FROM fact_transactions;