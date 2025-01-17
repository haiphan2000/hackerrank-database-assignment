WITH 
merge_prices AS (
    SELECT 'BTC' AS currency, dt, price
    FROM btc_prices
    UNION
    SELECT 'ETH' AS currency, dt, price
    FROM eth_prices
),
new_prices AS (
    SELECT
        currency,
        dt::timestamp::date AS dt_date,
        dt::timestamp::time AS dt_time,
        price
    FROM merge_prices
),
last_prices AS (
    SELECT DISTINCT
        currency,
        dt_date,
        FIRST_VALUE(price) OVER (
            PARTITION BY currency, dt_date
            ORDER BY dt_time DESC
        ) AS last_price
    FROM new_prices
),
previous_day_prices AS (
    SELECT
        currency,
        dt_date,
        last_price,
        LAG(last_price) OVER (
            PARTITION BY currency 
            ORDER BY dt_date
        ) AS previous_day_last_price,
        last_price - LAG(last_price) OVER (
            PARTITION BY currency
            ORDER BY dt_date
        ) AS price_change
    FROM last_prices
),
crypto_report AS (
    SELECT
        currency,
        dt_date,
        last_price,
        COALESCE(CAST(previous_day_last_price AS TEXT), 'N/A') AS previous_day_last_price,
        COALESCE(CAST(price_change AS TEXT), 'N/A') AS price_change
    FROM previous_day_prices
)

SELECT * 
FROM crypto_report;
