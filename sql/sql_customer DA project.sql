COPY olist_orders_dataset
FROM 'C:\\olist_data\\olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_customers_dataset
FROM 'C:\\olist_data\\olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_order_items_dataset
FROM 'C:\\olist_data\\olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_order_payments_dataset
FROM 'C:\\olist_data\\olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_order_reviews_dataset
FROM 'C:\\olist_data\\olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_products_dataset
FROM 'C:\\olist_data\\olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_sellers_dataset
FROM 'C:\\olist_data\\olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY olist_geolocation_dataset
FROM 'C:\\olist_data\\olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;
COPY product_category_name_translation
FROM 'C:\\olist_data\\product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;
SELECT COUNT(*) FROM olist_customers_dataset;
SELECT COUNT(*) FROM olist_order_items_dataset;
SELECT COUNT(*) FROM olist_order_payments_dataset;
SELECT COUNT(*) FROM olist_order_reviews_dataset;
SELECT COUNT(*) FROM olist_products_dataset;
SELECT COUNT(*) FROM olist_sellers_dataset;
SELECT COUNT(*) FROM olist_geolocation_dataset;
SELECT COUNT(*) FROM product_category_name_translation;
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp::date AS order_date,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    p.payment_type,
    p.payment_value,
    r.review_score,
    (i.price + i.freight_value) AS order_item_total
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset i ON o.order_id = i.order_id
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id;
CREATE OR REPLACE VIEW v_customer_geo AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    g.geolocation_lat,
    g.geolocation_lng
FROM olist_customers_dataset c
LEFT JOIN olist_geolocation_dataset g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price + freight_value) AS total_revenue,
    COUNT(DISTINCT customer_id) AS total_customers
FROM v_order_summary
WHERE order_status = 'delivered';
SELECT 
    ROUND(SUM(price + freight_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM v_order_summary
WHERE order_status = 'delivered';
SELECT 
    cg.customer_state,
    ROUND(SUM(os.price + os.freight_value), 2) AS total_revenue
FROM v_order_summary os
JOIN v_customer_geo cg ON os.customer_id = cg.customer_id
WHERE os.order_status = 'delivered'
GROUP BY cg.customer_state
ORDER BY total_revenue DESC
LIMIT 10;
SELECT 
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))), 2) AS avg_delay_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM v_order_summary
GROUP BY 1
ORDER BY 1;
SELECT current_database();
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
SELECT * FROM olist_orders_dataset LIMIT 1;
SELECT * FROM olist_order_items_dataset LIMIT 1;
SELECT * FROM olist_order_payments_dataset LIMIT 1;
SELECT price FROM olist_order_items_dataset WHERE price !~ '^[0-9.]+$';
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'olist_order_items_dataset';
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price + freight_value) AS total_revenue,
    COUNT(DISTINCT customer_id) AS total_customers
FROM v_order_summary
WHERE order_status = 'delivered';
CREATE OR REPLACE VIEW v_customer_first_purchase AS
SELECT
    customer_id,
    MIN(DATE_TRUNC('month', order_purchase_timestamp)) AS first_purchase_month
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY customer_id;
CREATE OR REPLACE VIEW v_customer_cohorts AS
SELECT
    c.customer_id,
    f.first_purchase_month,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
FROM olist_orders_dataset o
JOIN v_customer_first_purchase f
    ON o.customer_id = f.customer_id
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';
SELECT
    first_purchase_month,
    order_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM v_customer_cohorts
GROUP BY first_purchase_month, order_month
ORDER BY first_purchase_month, order_month;
WITH cohort_sizes AS (
    SELECT
        first_purchase_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM v_customer_cohorts
    GROUP BY first_purchase_month
),

retention AS (
    SELECT
        c.first_purchase_month,
        c.order_month,
        COUNT(DISTINCT c.customer_id) AS active_customers,
        cs.cohort_size,
        ROUND(100.0 * COUNT(DISTINCT c.customer_id) / cs.cohort_size, 2) AS retention_rate
    FROM v_customer_cohorts c
    JOIN cohort_sizes cs USING (first_purchase_month)
    GROUP BY c.first_purchase_month, c.order_month, cs.cohort_size
)

SELECT *
FROM retention
ORDER BY first_purchase_month, order_month;
CREATE OR REPLACE VIEW v_customer_rfm_base AS
SELECT
    o.customer_id,
    MAX(o.order_purchase_timestamp)::date AS last_order_date,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(i.price + i.freight_value) AS total_spent
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i
    ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.customer_id;
WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp)::date AS max_date
    FROM olist_orders_dataset
)
SELECT
    r.customer_id,
    (ref.max_date - r.last_order_date) AS recency_days,
    r.order_count AS frequency,
    r.total_spent AS monetary
FROM v_customer_rfm_base r, reference_date ref;
CREATE OR REPLACE VIEW v_customer_rfm_scores AS
WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp)::date AS max_date
    FROM olist_orders_dataset
),
rfm_raw AS (
    SELECT
        r.customer_id,
        (ref.max_date - r.last_order_date) AS recency_days,
        r.order_count AS frequency,
        r.total_spent AS monetary
    FROM v_customer_rfm_base r, reference_date ref
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- lower recency = better
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_raw;
CREATE OR REPLACE VIEW v_customer_rfm_segment AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_code,
    (r_score + f_score + m_score) AS rfm_total
FROM v_customer_rfm_scores;
SELECT * FROM v_customer_rfm_segment LIMIT 10;
SELECT
    CASE
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score BETWEEN 3 AND 4 AND f_score BETWEEN 2 AND 3 THEN 'Potential Loyalist'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'At Risk'
        WHEN r_score = 5 THEN 'Lost'
        ELSE 'Regular'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary), 2) AS avg_spent,
    ROUND(AVG(recency_days), 1) AS avg_recency
FROM v_customer_rfm_segment
GROUP BY 1
ORDER BY 2 DESC;

DROP VIEW IF EXISTS v_customer_first_purchase CASCADE;
CREATE OR REPLACE VIEW v_customer_first_purchase AS
SELECT
    customer_id,
    MIN(order_purchase_timestamp)::date AS first_purchase_date,
    DATE_TRUNC('month', MIN(order_purchase_timestamp))::date AS first_purchase_month
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY customer_id;
CREATE OR REPLACE VIEW v_customer_cohorts AS
SELECT
    f.customer_id,
    f.first_purchase_month,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN v_customer_first_purchase f
    ON o.customer_id = f.customer_id
WHERE o.order_status = 'delivered'
GROUP BY f.customer_id, f.first_purchase_month, order_month
ORDER BY f.first_purchase_month, order_month;

SELECT * FROM v_customer_cohorts LIMIT 100;
-- 1️⃣ Drop old views if they exist (to avoid conflicts)
DROP VIEW IF EXISTS v_customer_rfm_segment CASCADE;
DROP VIEW IF EXISTS v_customer_rfm_scores CASCADE;
DROP VIEW IF EXISTS v_customer_rfm_base CASCADE;

-- 2️⃣ Create base table for each customer's order metrics
CREATE OR REPLACE VIEW v_customer_rfm_base AS
SELECT
    o.customer_id,
    MAX(o.order_purchase_timestamp)::date AS last_order_date,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(i.price + i.freight_value) AS total_spent
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i
    ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.customer_id;

-- 3️⃣ Calculate Recency, Frequency, and Monetary scores
CREATE OR REPLACE VIEW v_customer_rfm_scores AS
WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp)::date AS max_date
    FROM olist_orders_dataset
),
rfm_raw AS (
    SELECT
        r.customer_id,
        (ref.max_date - r.last_order_date) AS recency_days,
        r.order_count AS frequency,
        r.total_spent AS monetary
    FROM v_customer_rfm_base r, reference_date ref
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- lower = better
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_raw;

-- 4️⃣ Combine all into RFM segmentation table
CREATE OR REPLACE VIEW v_customer_rfm_segment AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_code,
    (r_score + f_score + m_score) AS rfm_total
FROM v_customer_rfm_scores;

-- 5️⃣ Preview and export to CSV
SELECT * FROM v_customer_rfm_segment LIMIT 100;
-- 1️⃣ Drop old summary view (if any)
DROP VIEW IF EXISTS v_customer_segment_summary CASCADE;

-- 2️⃣ Create segment summary view
CREATE OR REPLACE VIEW v_customer_segment_summary AS
SELECT
    CASE
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score BETWEEN 3 AND 4 AND f_score BETWEEN 2 AND 3 THEN 'Potential Loyalist'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'At Risk'
        WHEN r_score = 5 THEN 'Lost'
        ELSE 'Regular'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary), 2) AS avg_spent,
    ROUND(AVG(recency_days), 1) AS avg_recency
FROM v_customer_rfm_segment
GROUP BY 1
ORDER BY 2 DESC;

-- 3️⃣ Preview and export
SELECT * FROM v_customer_segment_summary;

