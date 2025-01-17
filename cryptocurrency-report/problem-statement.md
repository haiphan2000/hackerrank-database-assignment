# Cryptocurrency Daily Price Report

Please note that this is not the full question; I only recalled and summarized the parts I remember.

There were multiple price records for Bitcoin (BTC) and Ethereum (ETH) at various times during each day. Assume that there are no 2 prices recorded at the same time. You need to create a report that summarizes the price information for each cryptocurrency daily. The report should include the following:
- **price**: The price at the last recorded time of the day.
- **previous_day_last_price**: The price at the last recorded time of the previous day. If the previous day does not exist, return N/A.
- **price_change**: The difference between the current day's price and the previous day's last price. If the previous day does not exist, return N/A.

The report should be sorted by currency and then by date, both in ascending order.

## ▼ Schema

There are two tables: `btc_price` and `eth_price`.

### btc_price

| Name | Type      | Description                        |
|------|-----------|------------------------------------|
| dt   | TIMESTAMP | The timestamp when the price was recorded |
| price| DECIMAL   | The price at the recorded time     |

### eth_price

| Name | Type      | Description                        |
|------|-----------|------------------------------------|
| dt   | TIMESTAMP | The timestamp when the price was recorded |
| price| DECIMAL   | The price at the recorded time     |

## ▼ Sample Data Tables

### btc_price

| dt               | price    |
|------------------|----------|
| 2/1/2024 01:00:23| 58000.45 |
| 2/1/2024 12:30:45| 62000.78 |
| 2/1/2024 23:59:59| 65696.33 |
| 2/2/2024 03:00:48| 67000.25 |
| 2/2/2024 15:45:00| 38400.75 |
| 2/2/2024 23:55:00| 68780.75 |
| 2/3/2024 08:20:30| 77030.15 |
| 2/3/2024 20:15:45| 66232.12 |

### eth_price

| dt               | price    |
|------------------|----------|
| 2/1/2024 02:00:30| 3000.25  |
| 2/1/2024 10:45:00| 3300.89  |
| 2/1/2024 23:59:59| 3478.18  |
| 2/2/2024 08:10:10| 3100.45  |
| 2/2/2024 15:30:00| 4250.56  |
| 2/2/2024 23:55:00| 3273.29  |
| 2/3/2024 09:10:15| 2154.89  |
| 2/3/2024 20:20:20| 3292.62  |

## ▼ Sample Output

| currency | date     | price   | previous_day_last_price | price_change |
|----------|----------|---------|-------------------------|--------------|
| BTC      | 2/1/2024 | 65696.33| N/A                     | N/A          |
| BTC      | 2/2/2024 | 68780.75| 65696.33                | 3084.42      |
| BTC      | 2/3/2024 | 66232.12| 68780.75                | -2548.63     |
| ETH      | 2/1/2024 | 3478.18 | N/A                     | N/A          |
| ETH      | 2/2/2024 | 3273.29 | 3478.18                 | -204.89      |
| ETH      | 2/3/2024 | 3292.62 | 3273.29                 | 19.33        |
