# Use the project database
USE business_operations_analytics;


# Create a reusable view for valid sales transactions
CREATE OR REPLACE VIEW vw_valid_sales AS

SELECT
    f.transaction_key,
    f.invoice,
    d.full_date,
    d.month_number,
    d.month_name,
    d.quarter_number,
    d.year_number,
    d.month_label,
    c.customer_id,
    c.customer_status,
    p.stock_code,
    p.description,
    l.country,
    f.quantity,
    f.unit_price,
    f.line_value
FROM fact_transactions f

INNER JOIN dim_date d
    ON f.date_key = d.date_key

INNER JOIN dim_customer c
    ON f.customer_key = c.customer_key

INNER JOIN dim_product p
    ON f.product_key = p.product_key

INNER JOIN dim_location l
    ON f.location_key = l.location_key

WHERE f.transaction_type = 'Sale'
AND f.record_status = 'Valid';


# Create a view for overall business KPIs
CREATE OR REPLACE VIEW vw_overall_kpis AS

SELECT
    SUM(line_value) AS revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(
        SUM(line_value) / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value
FROM vw_valid_sales;


# Create monthly performance metrics
CREATE OR REPLACE VIEW vw_monthly_performance AS

SELECT
    year_number,
    month_number,
    month_name,
    month_label,
    SUM(line_value) AS revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(
        SUM(line_value) / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value
FROM vw_valid_sales

GROUP BY
    year_number,
    month_number,
    month_name,
    month_label;


# Create product performance metrics
CREATE OR REPLACE VIEW vw_product_performance AS

SELECT
    stock_code,
    description,
    SUM(line_value) AS revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoice) AS orders,
    COUNT(DISTINCT customer_id) AS customers
FROM vw_valid_sales

GROUP BY
    stock_code,
    description;


# Create country performance metrics
CREATE OR REPLACE VIEW vw_country_performance AS

SELECT
    country,
    SUM(line_value) AS revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(
        SUM(line_value) / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value
FROM vw_valid_sales

GROUP BY country;


# Create customer performance metrics
CREATE OR REPLACE VIEW vw_customer_performance AS

SELECT
    customer_id,
    SUM(line_value) AS revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_purchased,
    COUNT(DISTINCT stock_code) AS products_purchased,
    MIN(full_date) AS first_purchase_date,
    MAX(full_date) AS latest_purchase_date
FROM vw_valid_sales

WHERE customer_id IS NOT NULL

GROUP BY customer_id;


# Confirm the views were created
SHOW FULL TABLES
WHERE Table_type = 'VIEW';