# Use the project database
USE business_operations_analytics;


# Check the total number of staging records
SELECT COUNT(*) AS total_rows
FROM stg_transactions;


# Check for missing values in required fields
SELECT
    SUM(invoice IS NULL OR invoice = '') AS missing_invoice,
    SUM(stock_code IS NULL OR stock_code = '') AS missing_stock_code,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(invoice_date IS NULL) AS missing_invoice_date,
    SUM(unit_price IS NULL) AS missing_unit_price,
    SUM(country IS NULL OR country = '') AS missing_country
FROM stg_transactions;


# Check missing customer IDs separately
SELECT
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(customer_id IS NOT NULL) AS known_customer_ids
FROM stg_transactions;


# Confirm duplicate rows were removed during preprocessing
SELECT
    COUNT(*) AS duplicate_rows
FROM (
    SELECT
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country,
        transaction_type,
        record_status,
        COUNT(*) AS row_count
    FROM stg_transactions
    GROUP BY
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country,
        transaction_type,
        record_status
    HAVING COUNT(*) > 1
) duplicates;


# Check transaction classifications
SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM stg_transactions
GROUP BY transaction_type
ORDER BY row_count DESC;


# Check record status classifications
SELECT
    record_status,
    COUNT(*) AS row_count
FROM stg_transactions
GROUP BY record_status
ORDER BY row_count DESC;


# Check negative quantities against transaction types
SELECT
    transaction_type,
    COUNT(*) AS negative_quantity_rows
FROM stg_transactions
WHERE quantity < 0
GROUP BY transaction_type
ORDER BY negative_quantity_rows DESC;


# Check unusual price values
SELECT
    SUM(unit_price < 0) AS negative_price_rows,
    SUM(unit_price = 0) AS zero_price_rows,
    MIN(unit_price) AS minimum_price,
    MAX(unit_price) AS maximum_price
FROM stg_transactions;


# Check the transaction date range
SELECT
    MIN(invoice_date) AS earliest_transaction,
    MAX(invoice_date) AS latest_transaction
FROM stg_transactions;


# Check overall business coverage
SELECT
    COUNT(DISTINCT invoice) AS unique_invoices,
    COUNT(DISTINCT stock_code) AS unique_products,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT country) AS unique_countries
FROM stg_transactions;