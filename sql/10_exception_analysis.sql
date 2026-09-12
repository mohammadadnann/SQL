# Use the project database
USE business_operations_analytics;


# Analyse cancellation activity
WITH cancellation_summary AS (
    SELECT
        COUNT(*) AS cancellation_rows,
        COUNT(DISTINCT invoice) AS cancelled_invoices,
        ABS(SUM(line_value)) AS cancelled_value
    FROM fact_transactions
    WHERE transaction_type = 'Cancellation'
),

sales_summary AS (
    SELECT
        COUNT(DISTINCT invoice) AS sales_invoices,
        SUM(line_value) AS sales_value
    FROM fact_transactions
    WHERE transaction_type = 'Sale'
    AND record_status = 'Valid'
)

SELECT
    cancellation_rows,
    cancelled_invoices,
    ROUND(cancelled_value, 2) AS cancelled_value,
    sales_invoices,
    ROUND(
        cancelled_invoices
        / (sales_invoices + cancelled_invoices) * 100,
        2
    ) AS cancellation_rate_percent,
    ROUND(
        cancelled_value / sales_value * 100,
        2
    ) AS cancelled_value_percent
FROM cancellation_summary
CROSS JOIN sales_summary;


# Analyse monthly cancellation trends
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
        COUNT(DISTINCT f.invoice) AS sales_invoices,
        SUM(f.line_value) AS sales_value
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
    AND s.month_number = c.month_number

ORDER BY
    s.year_number,
    s.month_number;


# Analyse stock adjustment activity
SELECT
    COUNT(*) AS adjustment_rows,
    COUNT(DISTINCT invoice) AS adjustment_invoices,
    SUM(quantity) AS net_quantity_adjustment,
    ROUND(SUM(line_value), 2) AS adjustment_value
FROM fact_transactions
WHERE transaction_type = 'Stock Adjustment';


# Find products with the largest stock adjustments
WITH product_adjustments AS (
    SELECT
        p.stock_code,
        p.description,
        COUNT(*) AS adjustment_rows,
        SUM(f.quantity) AS net_quantity_adjustment,
        SUM(ABS(f.quantity)) AS absolute_quantity_adjustment
    FROM fact_transactions f

    INNER JOIN dim_product p
        ON f.product_key = p.product_key

    WHERE f.transaction_type = 'Stock Adjustment'

    GROUP BY
        p.stock_code,
        p.description
),

ranked_adjustments AS (
    SELECT
        stock_code,
        description,
        adjustment_rows,
        net_quantity_adjustment,
        absolute_quantity_adjustment,
        RANK() OVER (
            ORDER BY absolute_quantity_adjustment DESC
        ) AS adjustment_rank
    FROM product_adjustments
)

SELECT
    adjustment_rank,
    stock_code,
    description,
    adjustment_rows,
    net_quantity_adjustment,
    absolute_quantity_adjustment
FROM ranked_adjustments
WHERE adjustment_rank <= 20
ORDER BY adjustment_rank;


# Analyse zero price records
SELECT
    COUNT(*) AS zero_price_rows,
    COUNT(DISTINCT invoice) AS affected_invoices,
    COUNT(DISTINCT product_key) AS affected_products,
    SUM(ABS(quantity)) AS affected_units
FROM fact_transactions
WHERE record_status = 'Zero Price';


# Review accounting adjustment records
SELECT
    f.invoice,
    d.full_date,
    p.stock_code,
    p.description,
    l.country,
    f.quantity,
    f.unit_price,
    f.line_value
FROM fact_transactions f

INNER JOIN dim_date d
    ON f.date_key = d.date_key

INNER JOIN dim_product p
    ON f.product_key = p.product_key

INNER JOIN dim_location l
    ON f.location_key = l.location_key

WHERE f.record_status = 'Accounting Adjustment'

ORDER BY ABS(f.line_value) DESC;


# Find unusually large valid sales transactions
WITH transaction_distribution AS (
    SELECT
        AVG(line_value) AS average_line_value,
        STDDEV_POP(line_value) AS line_value_stddev
    FROM fact_transactions
    WHERE transaction_type = 'Sale'
    AND record_status = 'Valid'
)

SELECT
    f.transaction_key,
    f.invoice,
    d.full_date,
    p.stock_code,
    p.description,
    l.country,
    f.quantity,
    f.unit_price,
    f.line_value
FROM fact_transactions f

INNER JOIN dim_date d
    ON f.date_key = d.date_key

INNER JOIN dim_product p
    ON f.product_key = p.product_key

INNER JOIN dim_location l
    ON f.location_key = l.location_key

CROSS JOIN transaction_distribution t

WHERE f.transaction_type = 'Sale'
AND f.record_status = 'Valid'
AND f.line_value
    > t.average_line_value + 5 * t.line_value_stddev

ORDER BY f.line_value DESC
LIMIT 50;


# Find products with high cancellation activity
WITH product_activity AS (
    SELECT
        p.stock_code,
        p.description,
        SUM(
            CASE
                WHEN f.transaction_type = 'Sale'
                THEN 1
                ELSE 0
            END
        ) AS sale_rows,
        SUM(
            CASE
                WHEN f.transaction_type = 'Cancellation'
                THEN 1
                ELSE 0
            END
        ) AS cancellation_rows
    FROM fact_transactions f

    INNER JOIN dim_product p
        ON f.product_key = p.product_key

    WHERE f.transaction_type IN (
        'Sale',
        'Cancellation'
    )

    GROUP BY
        p.stock_code,
        p.description
)

SELECT
    stock_code,
    description,
    sale_rows,
    cancellation_rows,
    ROUND(
        cancellation_rows
        / (sale_rows + cancellation_rows) * 100,
        2
    ) AS cancellation_rate_percent
FROM product_activity

WHERE cancellation_rows >= 10

ORDER BY
    cancellation_rate_percent DESC,
    cancellation_rows DESC

LIMIT 30;