CREATE DATABASE chicagopizza;
USE chicagopizza;
create table orders (
order_id int not null,
order_date date not null,
order_time time not null,
PRIMARY KEY(order_id)
);

create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
PRIMARY KEY(order_details_id)
);


SELECT * FROM pizzas;
SELECT * FROM pizza_types;
SELECT * FROM orders;
SELECT * FROM order_details;


-- Retrieve the total number of orders placed.
SELECT 
    COUNT(order_id) AS Total_Orders
FROM
    orders;


-- Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(quantity * price), 2) AS Total_Revenue
FROM
    order_details od
        JOIN
    pizzas p ON p.pizza_id = od.pizza_id;


-- Identify the highest-priced pizza.
SELECT 
    pt.name, p.price
FROM
    pizza_types pt
        JOIN
    pizzas p ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;


-- Identify the most common pizza size ordered.
-- SOLVED USING window function
WITH pizzasize as(
SELECT size, COUNT(p.pizza_id) OrderCount, DENSE_RANK() OVER(ORDER BY COUNT(pizza_id) DESC) MostOrderedSize
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
JOIN orders o ON o.order_id = od.order_id
GROUP BY size
)
SELECT size,OrderCount
FROM pizzasize
WHERE MostOrderedSize = 1;

-- SOLVED USING SUBQUERY
select size from
(SELECT size, COUNT(size) OrderCount
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
JOIN orders o ON o.order_id = od.order_id
GROUP BY size) a where OrderCount = 
(SELECT max(OrderCount) num from 
(SELECT size, COUNT(size) OrderCount
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
JOIN orders o ON o.order_id = od.order_id
GROUP BY size)a) ;

-- SOLVED USING cte
with sizesols as (
SELECT size, count(size) sizecount
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
JOIN orders o ON o.order_id = od.order_id
GROUP BY size
), maxsizesold as (
SELECT max(sizecount) as highsizesold from sizesols
)
SELECT size, sizecount
from sizesols
WHERE sizecount = (SELECT max(sizecount) as highsizesold from sizesols);


-- List the top 5 most ordered pizza types along with their quantities.
WITH pizza_sold as (
SELECT p.pizza_type_id,
       name,
       SUM(quantity) quantity,
       DENSE_RANK() OVER (ORDER BY SUM(quantity) DESC) rnk
FROM pizza_types pt
JOIN pizzas p ON p.pizza_type_id = pt.pizza_type_id 
JOIN order_details od ON od.pizza_id = p.pizza_id
group by p.pizza_type_id, name
)
SELECT name, quantity
FROM pizza_sold
WHERE rnk <= 5;


-- find the total quantity of each pizza category ordered.
SELECT category, SUM(quantity) quantity
FROM pizza_types pt
LEFT JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY category
ORDER BY quantity DESC;



-- Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) hour, COUNT(order_id) order_count
FROM
    orders o
GROUP BY HOUR(order_time)
ORDER BY order_count DESC;



-- find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(name) pizza_category_count
FROM
    pizza_types
GROUP BY category
ORDER BY pizza_category_count DESC;



-- calculate the average number of pizzas ordered on a per day.
SELECT 
    ROUND(AVG(Order_By_Date)) avg_pizza_ordered_per_date
FROM
    (SELECT 
        order_date, SUM(quantity) Order_By_Date
    FROM
        orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY order_date
    ORDER BY Order_By_Date DESC) AS qty_ordered;


-- Determine the top 3 most ordered pizza types based on revenue.
WITH pizza_revenue as (
SELECT p.pizza_type_id, name, ROUND(SUM(price*quantity)) revenue,
DENSE_RANK() OVER(ORDER BY SUM(price*quantity) DESC) revenue_rank
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY p.pizza_type_id, name
)
SELECT name, revenue
FROM pizza_revenue
WHERE revenue_rank <=3;




-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    category,
    CONCAT(percentage_revenue_contri, '%') percentage_revenue_contribution
FROM
    (SELECT 
        category,
            ROUND((SUM(price * quantity) / (SELECT 
                    SUM(price * quantity)
                FROM
                    pizzas p
                JOIN order_details od ON od.pizza_id = p.pizza_id)) * 100, 2) AS percentage_revenue_contri
    FROM
        pizza_types pt
    JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
    JOIN order_details od ON od.pizza_id = p.pizza_id
    GROUP BY category
    ORDER BY percentage_revenue_contri DESC) percentage_revenue;




-- Analyze the cumulative revenue generated over time.
WITH sales as(
SELECT order_date, SUM(quantity* price) revenue
FROM pizzas p
JOIN order_details od ON od.pizza_id = p.pizza_id
JOIN orders o ON o.order_id = od.order_id
 GROUP BY order_date
 )
SELECT order_date,
       ROUND(SUM(revenue) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING), 2) cumulative_revenue
FROM sales;



-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH pizza_ordered as (
SELECT category, name, SUM(price* quantity) as revenue,
DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(price* quantity) DESC) pizza_rank
FROM pizza_types pt
JOIN pizzas p ON p.pizza_type_id =pt.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY category, name
)
SELECT category, name, revenue
FROM pizza_ordered
WHERE pizza_rank <= 3
