# Use the project database
USE business_operations_analytics;


# Clear old staging data before reloading
TRUNCATE TABLE stg_transactions;


# Load the processed transaction file
LOAD DATA LOCAL INFILE 'data/processed/transactions_clean.csv'
INTO TABLE stg_transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    @customer_id,
    country,
    transaction_type,
    record_status
)

# Convert blank customer IDs into proper SQL NULL values
SET customer_id = NULLIF(@customer_id, '');

SHOW WARNINGS LIMIT 20;


# Confirm the number of loaded rows
SELECT COUNT(*) AS loaded_rows
FROM stg_transactions;


# Check missing customer IDs
SELECT
    SUM(customer_id IS NULL) AS null_customer_ids,
    SUM(customer_id = 0) AS zero_customer_ids
FROM stg_transactions;


# Check a few loaded records
SELECT *
FROM stg_transactions
LIMIT 5;