-- ANALYSIS ON SUPERMART DATABASE USING POSTGRESQL --

-- 1. Sales Performance by Region 
-- ● Question: What is the total sales amount by region?
select c.region, sum(s.sales_amount) as total_sales from
customer c join sales s
on c.customer_id=s.customer_id
group by 1;

-- 2. Top-Selling Products 
-- ● Question: Which products generated the most sales?
select p.product_id, p.product_name, sum(s.sales_amount) as total_sales 
from product p left join sales as s
on p.product_id = s.product_id
where sales_amount is not null
group by 1
order by 3 desc 
limit 1;

-- 3. Discount Impact on Profit 
-- ● Question: How does the discount affect profit?
select discount, profit from sales
order by discount desc;

-- 4. Sales by Customer Segment 
-- ● Question: How much sales does each customer segment contribute?
select c.segment, sum(s.sales_amount) as total_sales 
from customer c left join sales s
on c.customer_id = s.customer_id
group by 1;

-- 5. Product Category Sales 
-- ● Question: What are the total sales for each product category?
select p.category, sum(s.sales_amount) as total_sales 
from product p left join sales as s
on p.product_id = s.product_id
group by 1;

-- 6. Customer Orders by Ship Mode 
-- ● Question: How many orders were shipped by each shipping mode?
select ship_mode, count(order_id) as order_count from sales
group by ship_mode;

-- 7. Sales by Date 
-- ● Question: What are the total sales for each month?
select extract(month from order_date) as month, sum(sales_amount) as monthwise_total_sales
from sales
group by 1 
order by month;

-- 8. Customer Distribution by State 
-- ● Question: How many customers are there in each state?
select state, count(customer_id) as customers
from customer
group by 1 
order by state;

-- 9. Top 5 Customers by Sales 
-- ● Question: Who are the top 5 customers in terms of total sales?
select customer_id, sum(sales_amount) from sales
group by 1
order by 2 desc
limit 5;

-- 10. Product Performance in Subcategories 
-- ● Question: What is the total sales for each product subcategory?
select p.sub_category, sum(s.sales_amount) as total_sales 
from product p left join sales s
on p.product_id=s.product_id
group by 1;

-- 11. Rank Products by Sales 
-- ● Question: How can we rank products by their total sales within each product category?
select *, rank() over (partition by category order by total_sales desc) from 
(select p.product_id, p.category, sum(sales_amount) as total_sales from
product p join sales s
on p.product_id = s.product_id
group by 1,2);

-- 12. Cumulative Sales by Date 
-- ● Question: How can we calculate cumulative sales over time (running total) for each product?
select p.product_id, p.product_name, s.order_date, floor(s.sales_amount) as sales,
sum(floor(s.sales_amount)) over (partition by p.product_name order by s.order_date)
as running_total
from product p join sales s
on p.product_id = s.product_id;

-- 13. Find Top 3 Customers by Profit 
-- ● Question: How can we find the top 3 customers based on profit within each region?
with RankedCustomers as (
select c.customer_id, c.customer_name, c.region, sum(s.profit) as total_profit,
rank() over (partition by c.region 
order by sum(s.profit) desc) as rank
from 
	customer c left join sales s
	on c.customer_id = s.customer_id
group by 
	c.customer_id, c.customer_name, c.region
having count(c.region) = 3 )
	select * from RankedCustomers where rank <= 3;

-- 14. Average Sales by Segment with Row Number 
-- ● Question: How can we find the average sales for each segment and assign a row number to each customer based on their sales?
with AverageSalesPerSegment as (
select c.segment, avg(s.sales_amount) as average_sales_per_segment
from 
	customer c join sales s
	on c.customer_id = s.customer_id
group by c.segment
)
select 
    c.customer_id,
	c.customer_name,
    c.segment,
    s.sales_amount,
    a.average_sales_per_segment,
    row_number() over (partition by c.segment order by s.sales_amount desc) as row_number
from 
    sales s join customer c
	on s.customer_id = c.customer_id
join 
    AverageSalesPerSegment a
    on c.segment = a.segment;

-- 15. Difference in Sales Between Consecutive Days 
-- ● Question: How can we calculate the difference in sales between consecutive days for each product?
select *, (sales_amount - prev_date) as sales_difference
from (select s.order_date, s.sales_amount, LAG(s.sales_amount,1)
over (partition by p.product_name order by s.order_date) as prev_date
from sales s join product p
on p.product_id = s.product_id);

-- 16. Find Percent of Total Sales by Region 
-- ● Question: How can we calculate the percentage of total sales contributed by each region?
(select customer_region, total_sales_per_region/sum(total_sales_per_region)*100 as regionwise_total_sales_percentage from
(select c.region as customer_region, sum(s.sales_amount) as total_sales_per_region
from customer c join sales s on c.customer_id = s.customer_id
group by 1)
group by customer_region, total_sales_per_region);

-- 17. Calculate Moving Average of Sales 
-- ● Question: How can we calculate the moving average of sales over the last 3 orders for each product?
select product_name, round(avg(s.sales_amount) over(partition by p.product_name
order by s.order_date rows between
2 preceding and current row)) as moving_average
from sales s join product p
on s.product_id = p.product_id;

-- 18. Find Largest and Smallest Order by Customer 
-- ● Question: How can we find the largest and smallest order (by sales) for each customer?
select distinct customer_name, max(s.sales_amount) over (partition by c.customer_name) as largest_order,
min(s.sales_amount) over (partition by c.customer_name) as smallest_order
from sales s join customer c
on c.customer_id = s.customer_id;

-- 19. Running Total of Profit by Customer 
-- ● Question: How can we calculate the running total of profit for each customer?
select c.customer_id, c.customer_name, s.order_date, floor(s.profit) as profit,
sum(floor(s.profit)) over(partition by c.customer_name order by s.order_date)
as running_total
from customer c join sales s
on c.customer_id = s.customer_id;

-- 20. Calculate Dense Rank of Sales by Ship Mode 
-- ● Question: How can we assign a dense rank to each sale based on total sales, grouped by ship mode?
select ship_mode, dense_rank() over (partition by ship_mode order by sales_amount desc)
from sales;








