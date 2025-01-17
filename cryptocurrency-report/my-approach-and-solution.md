# PostgreSQL Solution to Daily Cryptocurrency Price Report

I will use PostgreSQL to solve this question. Note that PostgreSQL supports PL/pgSQL, which is a specific SQL dialect. Other database management systems may not support this dialect, and different platforms often have their own SQL dialects with distinct operators and syntax, so the approach may vary depending on the database platform used. Also, I will use snake_case for the naming convention of columns and tables in the coding solution.

To solve this question, I would use a bottom-up approach, which means breaking the problem into smaller, manageable steps, solving each step independently, and then combining the results to produce the final output. Here's how the bottom-up approach applies to this question:
1. Combine the tables. Merge data from `btc_prices` and `eth_prices` into a single dataset while adding a column to differentiate the cryptocurrency (BTC or ETH).
2. Extract daily last price. For each day, identify the price at the latest recorded time.
3. Calculate previous day's price and price change. Determine the last price of the previous day and the difference between the price of the current day and the previous day's last price for each cryptocurrency.
4. Handle null values. Replace the null value with 'N/A' when there is no previous day's price (for instance, on the first day of the dataset).

## 1. Combine the Tables

The question provides 2 separate tables, `btc_prices` and `eth_prices`. Since the report requires combining the data from both tables, I will use the `UNION` operator in PostgreSQL to merge them into a single table. To distinguish which rows come from which table, I will add an extra column that specifies the currency as 'BTC' or 'ETH' in the `SELECT` statement.

```sql
WITH merge_prices AS (
    SELECT 'BTC' AS currency, dt, price
    FROM btc_prices
    UNION
    SELECT 'ETH' AS currency, dt, price
    FROM eth_prices
)
