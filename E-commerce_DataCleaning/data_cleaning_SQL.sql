create table Cleaned_data as

with lower_column as (
	select ID as id, 
    Customer_Name as customer_name, 
    Order_ID as order_id, 
    Order_Date as order_date, 
    Product as product,
    Category as category,	
    Quantity as quantity,
    Price as price,
    Payment_Method as payment_method,
    `Status` as `status`,
    Total as total
    from messy_data
	),

type_fixed	as (
select id, customer_name, order_id, order_date, product, category, quantity, 
case when price regexp '^[0-9]+\.?[0-9]*$' then cast(price as decimal(10,2)) else null end as price,
payment_method, `status`,
case when total regexp '^[0-9]+\.?[0-9]*$' then cast(total as decimal(10,2)) else null end as total
from lower_column
),

date_fixed as (
select id, customer_name, order_id, product, category, quantity, price, payment_method, `status`, total,
case when order_date regexp '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' then str_to_date(order_date, '%m/%d/%Y')
when order_date regexp '^[A-Za-z]+ [0-9]{1,2} [0-9]{4}$' then str_to_date(order_date, '%b %e %Y')
else null end as order_date
from type_fixed
),

remove_duplicates as (
	select *, row_number() over (partition by order_id order by order_id) as rn
from date_fixed
),

negative_fixed as (
	select id, customer_name, order_id, order_date, product, category, 
    case when quantity < 0 then abs(quantity) else quantity end as quantity, 
    case when price < 0 then abs(price) else price end as price, 
    payment_method, `status`, total
    from remove_duplicates where rn = 1
),

-- select 
--     sum(case when ID is null or ID = '' then 1 else 0 end) as id_nulls,
--     sum(case when Customer_Name is null or Customer_Name = '' then 1 else 0 end) as customer_name_nulls,
--     sum(case when Order_ID is null or Order_ID = '' then 1 else 0 end) as order_id_nulls,
--     sum(case when Order_Date is null or Order_Date = '' then 1 else 0 end) as order_date_nulls,
--     sum(case when Product is null or Product = '' then 1 else 0 end) as product_nulls,
--     sum(case when Category is null or Category = '' then 1 else 0 end) as category_nulls,
--     sum(case when Quantity is null or Quantity = '' then 1 else 0 end) as quantity_nulls,
--     sum(case when Price is null or Price = '' then 1 else 0 end) as price_nulls,
--     sum(case when Payment_Method is null or Payment_Method = '' then 1 else 0 end) as payment_method_nulls,
--     sum(case when `Status` is null or `Status` = '' then 1 else 0 end) as status_nulls,
--     sum(case when Total is null or Total = '' then 1 else 0 end) as total_nulls
-- from messy_data;

fix_null as (
	select id, customer_name, order_id, order_date, product, 
    case when category is null or category in ('', 'nan', 'NaN') then 
			(select category from negative_fixed
            where category is not null and category not in ('', 'nan', 'NaN')
            group by category
            order by count(*) desc
            limit 1)
	else category end as category,
    quantity, 
    coalesce(price, avg(price) over (partition by product)) as price,
    payment_method, `status`, total
    from negative_fixed
),

fix_total as (
select id, customer_name, order_date, order_id, product, category, quantity, price, payment_method, `status`, 
(quantity * price) as total from fix_null
),

-- select distinct payment_method from messy_data;
-- select distinct `status` from messy_data;
-- select distinct category from messy_data
-- select distinct product from messy_data

fix_category as (
    select id, customer_name, order_id, order_date, product,
    case 
        when lower(category) in ('electronic', 'electronics') then 'Electronics'
        when lower(category) in ('book', 'books') then 'Books'
        when lower(category) in ('sport', 'sports') then 'Sports'
        when lower(category) in ('home') then 'Home'
        when lower(category) in ('clothing', 'clothes') then 'Clothing'
        else category
    end as category,
    quantity, price, payment_method, `status`, total
    from fix_total
),

round_values as (
select id, customer_name, order_id, order_date, product, category, quantity, 
round(price, 2) as price, payment_method, `status`, round(total, 2) as total
from fix_category
)

select * from round_values


-- final tests
select order_id, count(*) from cleaned_data group by order_id having count(*) > 1;
select count(*) from cleaned_data where price is null or category is null or total is null;
select * from cleaned_data limit 20;

























