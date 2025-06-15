-- Creating the database.

create database pizzahut;
use pizzahut;

-- Creating the tables.

CREATE TABLE orders (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

CREATE TABLE order_details (
    order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (order_details_id)
);

-- 1. Retrieve the total number of orders placed.

SELECT 
    COUNT(*) AS Total_orders
FROM
    orders;
    
-- 2. Calculate the total revenue generated from pizza sales.

SELECT 
    SUM(od.quantity * p.price) AS Total_revenue
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id;
    
-- 3. Identify the highest-priced pizza.

SELECT 
    pt.name AS Costliest_pizza, p.price
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- 4. Identify the most common pizza size ordered.

SELECT 
    p.size, COUNT(*) AS No_of_pizzas
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY No_of_pizzas DESC
LIMIT 1;

-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name, SUM(od.quantity) AS Ordered_quantity
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY Ordered_quantity DESC
LIMIT 5;

-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pt.category, SUM(od.quantity) AS Ordered_quantity
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY Ordered_quantity DESC;

-- 7. Determine the distribution of orders by hour of the day.

SELECT 
    EXTRACT(HOUR FROM order_time) AS Hour_of_day,
    COUNT(*) AS Orders_by_hour
FROM
    orders
GROUP BY Hour_of_day
ORDER BY Hour_of_day;

-- 8. Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    category, COUNT(*) AS No_of_pizzas
FROM
    pizza_types
GROUP BY category;

-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.

WITH cte AS (
    SELECT 
        o.order_date, 
        SUM(od.quantity) AS qty_sum
    FROM 
        orders o
        LEFT JOIN order_details od ON od.order_id = o.order_id
    GROUP BY 
        o.order_date
    ORDER BY 
        o.order_date
)

SELECT 
    ROUND(AVG(qty_sum), 0) AS Avg_pizzas_ordered_daily
FROM 
    cte;
    
-- 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM(od.quantity * p.price) AS Total_revenue
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY Total_revenue DESC
LIMIT 3;

-- 11. Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
    pt.category,
    CONCAT(ROUND((SUM(od.quantity * p.price) / (SELECT 
                            SUM(od.quantity * p.price)
                        FROM
                            order_details od
                                LEFT JOIN
                            pizzas p ON od.pizza_id = p.pizza_id)) * 100,
                    2),
            '%') AS Percentage_contribution
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY Percentage_contribution DESC;

-- 12. Analyze the cumulative revenue generated over time.

WITH cte AS (
    SELECT 
        o.order_date, 
        ROUND(SUM(od.quantity * p.price), 2) AS revenue
    FROM 
        order_details od
        LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN orders o ON od.order_id = o.order_id
    GROUP BY 
        o.order_date
)

SELECT 
    order_date, 
    revenue, 
    SUM(revenue) OVER (
        ORDER BY order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Cumulative_total
FROM 
    cte;
    
-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT 
    category, 
    name, 
    revenue
FROM (
    SELECT 
        pt.category, 
        pt.name,
        ROUND(SUM(od.quantity * p.price), 2) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY pt.category 
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS rn
    FROM 
        order_details od
        LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN orders o ON od.order_id = o.order_id
        LEFT JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY 
        pt.category, pt.name
) AS ranked
WHERE 
    rn <= 3
ORDER BY 
    category, revenue DESC;















