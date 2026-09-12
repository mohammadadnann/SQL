# Use the project database
USE business_operations_analytics;


# Analyse monthly revenue and month on month growth
WITH monthly_growth AS (
    SELECT
        month_label,
        revenue,
        orders,
        units_sold,
        customers,
        average_order_value,
        LAG(revenue) OVER (
            ORDER BY year_number, month_number
        ) AS previous_month_revenue
    FROM vw_monthly_performance
)

SELECT
    month_label,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_sold,
    customers,
    average_order_value,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS monthly_growth_percent
FROM monthly_growth
ORDER BY month_label;


# Analyse year on year monthly revenue growth
WITH yearly_comparison AS (
    SELECT
        year_number,
        month_number,
        month_name,
        month_label,
        revenue,
        LAG(revenue, 12) OVER (
            ORDER BY year_number, month_number
        ) AS previous_year_revenue
    FROM vw_monthly_performance
)

SELECT
    year_number,
    month_name,
    month_label,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_year_revenue, 2) AS previous_year_revenue,
    ROUND(
        (revenue - previous_year_revenue)
        / previous_year_revenue * 100,
        2
    ) AS yearly_growth_percent
FROM yearly_comparison
WHERE previous_year_revenue IS NOT NULL
ORDER BY year_number, month_number;


# Calculate a three month rolling revenue average
SELECT
    month_label,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY year_number, month_number
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_three_month_revenue
FROM vw_monthly_performance
ORDER BY year_number, month_number;


# Rank products by revenue
WITH product_rankings AS (
    SELECT
        stock_code,
        description,
        revenue,
        units_sold,
        orders,
        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM vw_product_performance
)

SELECT
    revenue_rank,
    stock_code,
    description,
    ROUND(revenue, 2) AS revenue,
    units_sold,
    orders
FROM product_rankings
WHERE revenue_rank <= 20
ORDER BY revenue_rank, stock_code;


# Rank countries by revenue
WITH country_rankings AS (
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
    revenue_rank,
    country,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_sold,
    customers,
    average_order_value
FROM country_rankings
ORDER BY revenue_rank;


# Segment customers using revenue and purchase frequency
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
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(AVG(revenue), 2) AS average_customer_revenue,
    ROUND(AVG(orders), 2) AS average_orders
FROM customer_segments
GROUP BY customer_segment
ORDER BY revenue DESC;


# Find the highest value customers
WITH ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        orders,
        units_purchased,
        products_purchased,
        RANK() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank
    FROM vw_customer_performance
)

SELECT
    customer_rank,
    customer_id,
    ROUND(revenue, 2) AS revenue,
    orders,
    units_purchased,
    products_purchased
FROM ranked_customers
WHERE customer_rank <= 20
ORDER BY customer_rank;


# Compare each country's revenue with total business revenue
WITH country_share AS (
    SELECT
        country,
        revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM vw_country_performance
)

SELECT
    country,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue / total_revenue * 100,
        2
    ) AS revenue_share_percent
FROM country_share
ORDER BY revenue DESC;