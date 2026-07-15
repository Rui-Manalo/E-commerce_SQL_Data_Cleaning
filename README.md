# E-Commerce Order Data Cleaning (SQL)

SQL project that cleans a raw e-commerce orders export using a series of CTEs: standardizing columns, fixing data types, parsing dates, removing duplicates, handling nulls, and normalizing category labels.

## Overview

The raw dataset had the kind of issues you'd expect from a manual export: inconsistent column naming, numbers stored as text, two different date formats mixed in the same column, duplicate orders, missing values, negative quantities and prices, and category labels that weren't standardized in casing or pluralization.

The script builds a single `Cleaned_data` table through a sequence of CTEs, with each transformation isolated into its own step so it's easy to follow and check.

## Dataset

| | |
|---|---|
| Raw file | `data/messy_ecommerce_sales_data.csv` |
| Source table | `messy_data` |
| Output table | `Cleaned_data` |
| Rows | 103 |
| Columns | `id`, `customer_name`, `order_id`, `order_date`, `product`, `category`, `quantity`, `price`, `payment_method`, `status`, `total` |

Issues found in the raw file:
- A few empty trailing columns left over from the original export
- Missing values in `category` (9), `price` (8), and `total` (15)
- 2 duplicate `order_id` rows
- Inconsistent category labels (`sports` vs `Sports`, `electronic`/`electronics` vs `Electronics`)
- Mixed date formats in `order_date`
- One fully blank trailing row

## Tools

- SQL (MySQL dialect) — `REGEXP`, `STR_TO_DATE`, window functions

## Cleaning steps

1. **lower_column** — standardizes column names (e.g. `Customer_Name` to `customer_name`).
2. **type_fixed** — validates `price` and `total` against a numeric pattern and casts valid values to `DECIMAL(10,2)`; anything that doesn't match is set to null instead of being coerced.
3. **date_fixed** — parses `order_date` from two formats (`MM/DD/YYYY` and `Mon D YYYY`) into a proper date, with unmatched formats set to null.
4. **remove_duplicates** — keeps only the first row per `order_id` using `ROW_NUMBER()`.
5. **negative_fixed** — corrects negative `quantity` and `price` values with `ABS()`.
6. **fix_null** — fills missing `category` with the most frequent category, and missing `price` with the average price for that product.
7. **fix_total** — recalculates `total` as `quantity * price` instead of trusting the original column.
8. **fix_category** — standardizes category labels (e.g. `electronic`/`electronics` to `Electronics`).
9. **round_values** — rounds `price` and `total` to 2 decimal places.
10. Final queries check for remaining duplicates, remaining nulls, and preview the output.

## Data quality checks

```sql
-- no duplicate order IDs
select order_id, count(*) from Cleaned_data group by order_id having count(*) > 1;

-- no missing values in key columns
select count(*) from Cleaned_data where price is null or category is null or total is null;

-- spot-check the output
select * from Cleaned_data limit 20;
```

## Before / after

| Issue | Before | After |
|---|---|---|
| Column names | `Customer_Name`, `Order_ID` | `customer_name`, `order_id` |
| Dates | `7/4/2024`, `Jul 4 2024` (mixed) | `2024-07-04` (standardized) |
| Price | `"19.99"` as text, invalid entries | `19.99` as decimal, invalid entries set to null then imputed |
| Category | `electronic`, `Electronics`, `ELECTRONICS` | `Electronics` |
| Quantity | `-3` | `3` |
| Duplicates | same `order_id` appearing more than once | one row per `order_id` |

## Repository structure

```
├── data/
│   ├── messy_ecommerce_sales_data.csv   raw data
│   └── cleaned_data.csv                 output after running the script
├── sql/
│   └── data_cleaning.sql
└── README.md
```


## Notes

- Used regex validation before casting numeric fields, to avoid errors on dirty text values.
- Handled two date formats appearing in the same column.
- Recomputed `total` from `quantity * price` rather than trusting the raw column, since a few rows had inconsistent totals.

## Author

Made by Rui Manalo · [LinkedIn](www.linkedin.com/in/rui-manalo-71350a376), [Portfolio](https://www.datascienceportfol.io/ruicourse3)
