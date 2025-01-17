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
```

## 2. Extract Daily Last Price

First, the `merge_prices` table contains a column `dt`, which stores both the date and time as a timestamp. To handle queries related to dates in the next steps, I will separate the `dt` column into 2 distinct columns: `dt_date` (for the date) and `dt_time` (for the time). This separation will allow me to easily work with the date part for daily processing, and the time part for sorting or filtering based on specific time values.

```sql
WITH new_prices AS (
    SELECT
    currency,
    dt::timestamp::date AS dt_date,
    dt::timestamp::time AS dt_time,
    price
    FROM merge_prices
)

To get the price at the end of the day, I have 2 approaches:

### Approach 2.1. Using self-join

The idea is to use a self-join to compare the times and find the price at the end of the day. In problems where I need to find the minimum or maximum values, the problem can be formulated as: "There exists value X, such that X is never larger/smaller than all values in the table."
Similarly, the problem of finding the price at the end of the day can be expressed as: "There exists a price whose time is never later than all the times for that day."
To solve this, I will use a self-join with the NOT EXISTS operator. Specifically, I will create a sub-table nbp2 that is identical to the original table nbp1 (new_prices). Then, I will filter the prices from the nbp1 table where its time is never greater than the times in the nbp2 table (for the same currency and date).

```sql
WITH last_prices AS (
	SELECT currency, dt_date, price AS last_price
	FROM new_prices AS np1
	WHERE NOT EXISTS (
	SELECT 1
	FROM new_prices AS np2
	WHERE np2.currency = np1.currency
	AND np2.dt_date = np1.dt_date
	AND np2.dt_time > np1.dt_time )
)
```

### Approach 2.2. Using partition and window function
For each day, I want to find the price at the end of the day. I will achieve this by:
•	Partition the data by both the currency and dt_date columns to group the data by each cryptocurrency and its corresponding day.
•	Sort the prices for each day by dt_time in descending order, so the most recent price appears first.
•	Use ROW_NUMBER/RANK/DENSE_RANK window function to assign a ranking to each row (You can use any of 3 three ranking functions above because they all give the same result when identifying the latest price). The price with a rank of 1 will correspond to the price at the end of the day (the latest time for that day).

```sql
WITH rank_prices AS (
	SELECT
	currency,
	dt_date,
	dt_time,
	price,
	ROW_NUMBER() OVER (
	PARTITION BY currency, dt_date
	ORDER BY dt_time DESC
	) AS ranking
	FROM new_prices
),
last_prices AS (
	SELECT dt_date, price AS last_price
	FROM rank_prices
	WHERE ranking = 1
)
```

As you have pointed out, after performing the sorting by dt_time and partitioning by both currency and dt_date, the price I am looking for (the price at the end of the day) will always appear first within each partition. PostgreSQL provides the FIRST_VALUE function, which can directly return the first value in an ordered partition. By using this function, I can simplify the query and avoid the need for ROW_NUMBER to assign rankings.
Note that there are multiple entries for the same currency and dt_date with different dt_time values in the new_prices table, you may encounter duplicates when using the FIRST_VALUE function.  In this case, you should handle this by using DISTINCT.

```sql
WITH last_prices AS (
	SELECT DISTINCT
	currency,
	dt_date,
	FIRST_VALUE(price) OVER (
	PARTITION BY currency, dt_date
	ORDER BY dt_time DESC
	) AS last_price
	FROM new_prices
)
```

## 3. Calculate previous day's price and price change
In this step, I aim to calculate the price_change, which is defined as:
price_change = price − previous_day_last_price
For calculating previous_day_last_price, I have 2 approaches:
### Approach 3.1. Using self-join
In this approach, I will use a self-join technique to compare the prices from the current day with those from the previous day. The key idea is to find the price from the previous day by joining the table with itself and using a condition that checks for dates that differ by exactly one day (yesterday’s price). This requires a LEFT JOIN, which ensures that even if there is no previous day (for example, for the earliest day in the dataset), you will still handle it.

```sql
WITH previous_day_prices AS (
	SELECT
	l1.currency,
	l1.dt_date,
	l1.last_price,
	l2.last_price AS previous_day_last_price,
	l1.last_price - l2.last_price AS price_change
	FROM last_prices AS l1 LEFT JOIN last_prices AS l2
	ON l1.dt_date - INTERVAL '1 DAY' = l2.dt_date
	AND l1.currency = l2.currency
)
```

### Approach 3.2. Using window function
In this approach, I will use the LAG window function to find the price of the previous day for each record. The LAG function allows you to access data from a previous row within the same result set, making it an ideal tool for this scenario:
•	Partition by currency to ensure dealing with data for each cryptocurrency.
•	Order the rows by dt_time to accurately identify the "previous" price.
•	Use LAG function to fetch the price value from the previous row (the previous day).

```sql
WITH previous_day_prices AS (
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
	ORDER BY dt_time
	) AS price_change
	FROM last_prices
)
```

## 4. Handle null values
When using LEFT JOIN as described in previous steps, there may be cases where the last_price for the first day is null. This can result in previous_day_last_price and price_change also being null because they depend on last_price. Since the question specifies null values would be replaced with 'N/A', I will handle this scenario using the COALESCE function in PostgreSQL.
The COALESCE function in PostgreSQL returns the first non-null value from a list of values. In this case, I will use it to replace any null values with the string 'N/A'. The COALESCE function requires all values in its argument list to have the same data type. If there is a mismatch of data types, such as attempting to combine numeric values previous_day_last_price and price_change with a string 'N/A', PostgreSQL will raise an error. To resolve this, I explicitly convert the numeric columns to a text data type using the CAST operator before applying COALESCE. This ensures that all values in the COALESCE function have the same data type.

```sql
WITH crypto_report AS (
	SELECT
	currency,
	dt_date,
	last_price,
	COALESCE(CAST(previous_day_last_price AS TEXT), 'N/A'),
	COALESCE(CAST(price_change AS TEXT), 'N/A')
	FROM previous_day_prices
)
```
