# Use the project database
USE business_operations_analytics;


# Remove existing analytics tables before rebuilding
DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_location;


# Create the date dimension
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number INT NOT NULL,
    month_number INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_number INT NOT NULL,
    year_number INT NOT NULL,
    month_label VARCHAR(7) NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);


# Create the customer dimension
CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNIQUE,
    customer_status VARCHAR(20) NOT NULL
);


# Create the product dimension
CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    stock_code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(255)
);


# Create the location dimension
CREATE TABLE dim_location (
    location_key INT AUTO_INCREMENT PRIMARY KEY,
    country VARCHAR(100) NOT NULL UNIQUE
);


# Create the transaction fact table
CREATE TABLE fact_transactions (
    transaction_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice VARCHAR(20) NOT NULL,
    date_key INT NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    location_key INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12, 4) NOT NULL,
    line_value DECIMAL(16, 4) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    record_status VARCHAR(30) NOT NULL,

    FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key),

    FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key),

    FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key),

    FOREIGN KEY (location_key)
        REFERENCES dim_location(location_key)
);


# Add indexes for common analysis fields
CREATE INDEX idx_fact_date
ON fact_transactions(date_key);

CREATE INDEX idx_fact_customer
ON fact_transactions(customer_key);

CREATE INDEX idx_fact_product
ON fact_transactions(product_key);

CREATE INDEX idx_fact_location
ON fact_transactions(location_key);

CREATE INDEX idx_fact_invoice
ON fact_transactions(invoice);


# Confirm the tables were created
SHOW TABLES;