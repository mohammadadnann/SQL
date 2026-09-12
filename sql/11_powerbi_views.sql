# Use the project database
USE business_operations_analytics;


# Create executive KPI view
CREATE OR REPLACE VIEW vw_powerbi_executive_kpis AS

SELECT
    ROUND(SUM(line_value), 2) AS revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(
        SUM(line_value) / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value
FROM vw_valid_sales;


# Create monthly performance view
CREATE OR REPLACE VIEW vw_powerbi_monthly_performance AS

WITH monthly_metrics AS (
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
        month_label
),

monthly_growth AS (
    SELECT
        *,
        LAG(revenue) OVER (
            ORDER BY year_number, month_number
        ) AS previous_month_revenue
    FROM monthly_metrics
)

SELECT
    year_number,
    month_number,
    month_name,
    month_label,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_sold,
    customers,
    average_order_value,
    ROUND(
        (revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS monthly_growth_percent
FROM monthly_growth;


# Create customer segment view
CREATE OR REPLACE VIEW vw_powerbi_customer_segments AS

WITH customer_metrics AS (
    SELECT
        customer_id,
        revenue,
        orders,
        units_purchased,
        products_purchased,
        first_purchase_date,
        latest_purchase_date,
        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS revenue_group,
        NTILE(4) OVER (
            ORDER BY orders DESC
        ) AS frequency_group
    FROM vw_customer_performance
),

customer_segments AS (
    SELECT
        customer_id,
        revenue,
        orders,
        units_purchased,
        products_purchased,
        first_purchase_date,
        latest_purchase_date,
        CASE
            WHEN revenue_group = 1
                AND frequency_group = 1
                THEN 'High Value'

            WHEN frequency_group = 1
                THEN 'Frequent'

            WHEN revenue_group = 1
                THEN 'High Spend'

            WHEN orders = 1
                THEN 'One Time'

            ELSE 'Regular'
        END AS customer_segment
    FROM customer_metrics
)

SELECT
    customer_id,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_purchased,
    products_purchased,
    first_purchase_date,
    latest_purchase_date,
    customer_segment
FROM customer_segments;


# Create product performance view
CREATE OR REPLACE VIEW vw_powerbi_product_performance AS

WITH ranked_products AS (
    SELECT
        stock_code,
        description,
        revenue,
        units_sold,
        orders,
        customers,
        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM vw_product_performance
)

SELECT
    stock_code,
    description,
    ROUND(revenue, 2) AS revenue,
    units_sold,
    orders,
    customers,
    revenue_rank
FROM ranked_products;


# Create country performance view
CREATE OR REPLACE VIEW vw_powerbi_country_performance AS

WITH ranked_countries AS (
    SELECT
        country,
        revenue,
        orders,
        units_sold,
        customers,
        average_order_value,
        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM vw_country_performance
)

SELECT
    country,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_sold,
    customers,
    average_order_value,
    revenue_rank
FROM ranked_countries;


# Create monthly cancellation view
CREATE OR REPLACE VIEW vw_powerbi_cancellation_trends AS

WITH monthly_cancellations AS (
    SELECT
        d.year_number,
        d.month_number,
        d.month_label,
        COUNT(DISTINCT f.invoice) AS cancelled_invoices,
        ABS(SUM(f.line_value)) AS cancelled_value
    FROM fact_transactions f

    INNER JOIN dim_date d
        ON f.date_key = d.date_key

    WHERE f.transaction_type = 'Cancellation'

    GROUP BY
        d.year_number,
        d.month_number,
        d.month_label
),

monthly_sales AS (
    SELECT
        d.year_number,
        d.month_number,
        d.month_label,
        COUNT(DISTINCT f.invoice) AS sales_invoices
    FROM fact_transactions f

    INNER JOIN dim_date d
        ON f.date_key = d.date_key

    WHERE f.transaction_type = 'Sale'
    AND f.record_status = 'Valid'

    GROUP BY
        d.year_number,
        d.month_number,
        d.month_label
)

SELECT
    s.year_number,
    s.month_number,
    s.month_label,
    s.sales_invoices,
    COALESCE(c.cancelled_invoices, 0) AS cancelled_invoices,
    ROUND(
        COALESCE(c.cancelled_invoices, 0)
        / (
            s.sales_invoices
            + COALESCE(c.cancelled_invoices, 0)
        ) * 100,
        2
    ) AS cancellation_rate_percent,
    ROUND(
        COALESCE(c.cancelled_value, 0),
        2
    ) AS cancelled_value
FROM monthly_sales s

LEFT JOIN monthly_cancellations c
    ON s.year_number = c.year_number
    AND s.month_number = c.month_number;


# Create operational exception view
CREATE OR REPLACE VIEW vw_powerbi_exceptions AS

SELECT
    f.transaction_key,
    f.invoice,
    d.full_date,
    p.stock_code,
    p.description,
    l.country,
    f.quantity,
    f.unit_price,
    f.line_value,
    f.transaction_type,
    f.record_status
FROM fact_transactions f

INNER JOIN dim_date d
    ON f.date_key = d.date_key

INNER JOIN dim_product p
    ON f.product_key = p.product_key

INNER JOIN dim_location l
    ON f.location_key = l.location_key

WHERE f.transaction_type IN (
    'Cancellation',
    'Stock Adjustment'
)
OR f.record_status IN (
    'Zero Price',
    'Accounting Adjustment'
);


# Confirm Power BI views were created
SHOW FULL TABLES
WHERE Table_type = 'VIEW'
AND Tables_in_business_operations_analytics LIKE 'vw_powerbi%';