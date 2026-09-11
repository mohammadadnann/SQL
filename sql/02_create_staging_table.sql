# Use the project database
USE business_operations_analytics;


# Remove the staging table if it already exists
DROP TABLE IF EXISTS stg_transactions;


# Create a staging table matching the processed CSV
CREATE TABLE stg_transactions (
    invoice VARCHAR(20) NOT NULL,
    stock_code VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    quantity INT NOT NULL,
    invoice_date DATETIME NOT NULL,
    unit_price DECIMAL(12, 4) NOT NULL,
    customer_id INT,
    country VARCHAR(100) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    record_status VARCHAR(30) NOT NULL
);


# Confirm the table structure
DESCRIBE stg_transactions;