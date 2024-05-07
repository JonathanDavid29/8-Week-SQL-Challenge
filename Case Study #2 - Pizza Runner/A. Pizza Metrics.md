## 🍕🗒️ Solution A. Pizza Metrics.

### 1. How many pizzas were ordered?

````sql
SELECT
	COUNT(pizza_id) AS orders
FROM customer_orders_temp
````

**Answer:**

![Captura de pantalla 2024-05-07 134056](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/a40bd18b-5636-4d7d-b7e1-2d3fc581d105)

- Total pizzas ordered were **14**.

***

### 2. How many unique customer orders were made?

````sql
SELECT
  COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders_temp
````

**Answer:**

![Captura de pantalla 2024-05-07 134726](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/c71963d0-4b5d-4c43-9a5a-7f2f41c3ff26)

- There are **10** unique customer orders.

***

### 3. How many successful orders were delivered by each runner?

````sql
SELECT 
  runner_id,
  COUNT(order_id) AS succesful_orders
FROM runner_orders_temp
WHERE distance != 0
GROUP BY runner_id
ORDER BY succesful_orders DESC
````

**Answer:**

![Captura de pantalla 2024-05-07 135046](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/b1d5e1d1-331a-4725-b487-a03a745ad2a9)

- Runner with id **1** successfully delivered *4* orders, thus being the most efficient one.
- Runner with id **2** successfully delivered *3* orders.
- Runner with id **3** successfully delivered *1* orders.

***

### 4. How many of each type of pizza was delivered?

````sql
SELECT
  pizza_names.pizza_name,
  COUNT(customer_orders_temp.pizza_id)
FROM customer_orders_temp
LEFT JOIN pizza_runner.pizza_names 
  ON customer_orders_temp.pizza_id = pizza_runner.pizza_names.pizza_id
LEFT JOIN runner_orders_temp
  ON customer_orders_temp.order_id = runner_orders_tempp.order_id
WHERE distance != 0
GROUP BY pizza_names.pizza_name
````

**Answer:**

![Captura de pantalla 2024-05-07 135858](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/f9c96f19-b1e6-49de-a6ab-1aa672195bdc)

- For Meatlovers pizza were delivered **9**.
- For Vegetarian pizza were delivered **3**.

***

### 5. How many Vegetarian and Meatlovers were ordered by each customer?

````sql
SELECT
  customer_id,
  pizza_names.pizza_name,
  COUNT( pizza_names.pizza_name)
FROM customer_orders_temp
LEFT JOIN pizza_runner.pizza_names 
  ON customer_orders_temp.pizza_id = pizza_runner.pizza_names.pizza_id
GROUP BY customer_id, pizza_names.pizza_name
ORDER BY customer_id ASC
````

**Answer:**

![Captura de pantalla 2024-05-07 140403](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/21225282-dfe8-4729-a233-249c61f9642f)

- Customer with id **101** ordered **2** Meatlovers pizzas and **1** Vegetarian pizza.
- Customer with id **102** ordered **2** Meatlovers pizzas and **1** Vegetarian pizza.
- Customer with id **103** ordered **3** Meatlovers pizzas and **1** Vegetarian pizza.
- Customer with id **104** ordered **3** Meatlovers pizzas.
- Customer with id **105** ordered **1** Vegetarian pizza.

***

### 6. What was the maximum number of pizzas delivered in a single order?

````sql
WITH cte AS(
  SELECT
    customer_orders_temp.order_id,
    COUNT(customer_orders_temp.order_id) AS count_p
  FROM customer_orders_temp
  LEFT JOIN runner_orders_temp
    ON customer_orders_temp.order_id = runner_orders_temp.order_id 
  WHERE runner_orders_temp.distance != 0 
  GROUP BY customer_orders_temp.order_id
)

SELECT 
  MAX(count_p) AS maximum_pizzas_delivered
FROM cte
````

**Answer:**

![Captura de pantalla 2024-05-07 141110](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/d33e56c0-a049-4bbf-a3fe-9f9b689bf32f)

- Maximum number of pizzas delivered was 3

***

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

````sql
SELECT 
  customer_id,
  SUM(CASE
        WHEN customer_orders_temp.exclusions <> ' ' OR customer_orders_temp.extras <> ' ' THEN 1
        ELSE 0
     END) AS had_at_least_1_change,
  SUM(CASE
        WHEN customer_orders_temp.exclusions = ' ' OR customer_orders_temp.extras = ' ' THEN 1
        ELSE 0
     END) AS had_no_changes
FROM customer_orders_temp
LEFT JOIN runner_orders_temp 
  ON customer_orders_temp.order_id = runner_orders_temp.order_id
WHERE distance != 0
GROUP BY customer_id
ORDER BY customer_id ASC
````

**Answer:**

![0](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/2c588e28-f3d4-4c44-ab7e-0e7f6e6149e3)

- Customers with id **101** & **102** didn't make any ingredient modifications to their pizzas.
- Customer with id **103**, **104** & **105** requested at least one change in their pizzas.

***

### 8. How many pizzas were delivered that had both exclusions and extras?

````sql
SELECT
  SUM(CASE
        WHEN exclusions IS NOT null AND exclusions <> ' ' 
        AND extras IS NOT NULL AND extras <> ' ' THEN 1
        ELSE 0
      END) AS delivered_pizza
FROM customer_orders_temp
LEFT JOIN runner_orders_temp
  ON customer_orders_temp.order_id = runner_orders_temp.order_id
WHERE distance != 0
````

**Answer:**

![1](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/071bddc1-79fc-48f3-9fda-55d445d92745)

- Only 1 pizza was delivered that had exclusions and extras.

***

### 9. How many pizzas were ordered?

````sql
SELECT
  EXTRACT(HOUR FROM order_time) AS hour,
  COUNT(order_id) pizzas_ordered_for_each_hour
FROM customer_orders_temp
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY hour ASC
````

**Answer: **

![Captura de pantalla 2024-05-07 165501](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/c8de62d2-97bc-4df3-9577-f027459fe8a4)

- Hours when most orders are placed is at **13:00** (1:00 pm), **18:00** (6:00 pm), **21:00** (9:00 pm), **23:00** (11:00 pm).
- Hours when the least orders are placed is at **11:00** (11:00 am) and **19:00** (7:00 pm).

***

### 10. What was the volume of orders for each day of the week?

````sql
SELECT
  TO_CHAR(order_time + INTERVAL '2 DAYS','Day') AS week_day,
  COUNT(order_id) AS orders
FROM customer_orders_temp
GROUP BY week_day
ORDER BY week_day ASC
````

**Answer: **

![Captura de pantalla 2024-05-07 170730](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/702f851b-0060-4019-8d8a-2a3add65bb14)

- There are 5 pizzas ordered on Friday and Monday.
- There are 3 pizzas ordered on Saturday.
- There is 1 pizza ordered on Sunday.

***
