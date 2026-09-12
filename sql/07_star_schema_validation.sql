# Use the project database
USE business_operations_analytics;


# Confirm staging and fact row counts match
SELECT
    (SELECT COUNT(*) FROM stg_transactions) AS staging_rows,
    (SELECT COUNT(*) FROM fact_transactions) AS fact_rows;


# Check that every fact record has matching dimension keys
SELECT
    SUM(d.date_key IS NULL) AS missing_date_keys,
    SUM(c.customer_key IS NULL) AS missing_customer_keys,
    SUM(p.product_key IS NULL) AS missing_product_keys,
    SUM(l.location_key IS NULL) AS missing_location_keys
FROM fact_transactions f

LEFT JOIN dim_date d
    ON f.date_key = d.date_key

LEFT JOIN dim_customer c
    ON f.customer_key = c.customer_key

LEFT JOIN dim_product p
    ON f.product_key = p.product_key

LEFT JOIN dim_location l
    ON f.location_key = l.location_key;


# Check how many fact rows use the unknown customer
SELECT
    COUNT(*) AS unknown_customer_rows
FROM fact_transactions f

INNER JOIN dim_customer c
    ON f.customer_key = c.customer_key

WHERE c.customer_status = 'Unknown';


# Reconcile unknown customers with missing staging customer IDs
SELECT
    (SELECT COUNT(*)
     FROM stg_transactions
     WHERE customer_id IS NULL) AS staging_missing_customers,

    (SELECT COUNT(*)
     FROM fact_transactions f
     INNER JOIN dim_customer c
         ON f.customer_key = c.customer_key
     WHERE c.customer_status = 'Unknown') AS fact_unknown_customers;


# Check transaction type counts after loading the fact table
SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM fact_transactions
GROUP BY transaction_type
ORDER BY row_count DESC;


# Check record status counts after loading the fact table
SELECT
    record_status,
    COUNT(*) AS row_count
FROM fact_transactions
GROUP BY record_status
ORDER BY row_count DESC;


# Check line value calculation
SELECT
    COUNT(*) AS incorrect_line_values
FROM fact_transactions
WHERE line_value <> quantity * unit_price;


# Check fact table value ranges
SELECT
    MIN(quantity) AS minimum_quantity,
    MAX(quantity) AS maximum_quantity,
    MIN(unit_price) AS minimum_price,
    MAX(unit_price) AS maximum_price,
    MIN(line_value) AS minimum_line_value,
    MAX(line_value) AS maximum_line_value
FROM fact_transactions;


# Check date dimension coverage
SELECT
    MIN(full_date) AS earliest_date,
    MAX(full_date) AS latest_date,
    COUNT(*) AS date_rows
FROM dim_date;


# Check dimension uniqueness
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM dim_customer
WHERE customer_id IS NOT NULL;

SELECT
    COUNT(*) AS product_rows,
    COUNT(DISTINCT stock_code) AS distinct_stock_codes
FROM dim_product;

SELECT
    COUNT(*) AS location_rows,
    COUNT(DISTINCT country) AS distinct_countries
FROM dim_location;