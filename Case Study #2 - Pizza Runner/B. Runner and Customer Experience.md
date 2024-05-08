## 🏃🤷‍♂️ B. Runner and Customer Experience.

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

````sql
SELECT
    EXTRACT(WEEK FROM registration_date) AS registration_week,
    COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week
````

**Answer:**

![0 (2)](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/4f00b37a-2b6f-4b23-a358-918ef13e55a5)

- On Week **1** of Jan 2021, **2** new runners signed up.
- On Week **2** & **3** of Jan 2021, **1** new runner signed up.

***

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

````sql
WITH calculate_time AS(
    SELECT
    runner_id,
    EXTRACT(EPOCH FROM (runner_orders_tempp.pickup_time - customer_orders_temp.order_time) / 60 ) AS time_difference
    FROM runner_orders_temp
    LEFT JOIN customer_orders_temp
        ON runner_orders_temp.order_id = customer_orders_temp.order_id
    WHERE distance != 0
    GROUP BY runner_id, runner_orders_temp.pickup_time, customer_orders_temp.order_time
)

SELECT 
    CEIL(AVG(time_difference)) AS avg_time_in_minutes --> 15.97 = 16
FROM calculate_time    
````

**Answer:**

![Captura de pantalla 2024-05-08 130727](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/8c107127-d50b-4be2-923e-79799edf328b)

- The average time it takes each runner to reach at Pizza Runner HQ branch and pick up the pizza is 16 minutes.

***

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

````sql
WITH cte AS(
SELECT 
    COUNT(customer_orders_temp.order_id) AS num_pizza,
    EXTRACT(EPOCH FROM (runner_orders_tempp.pickup_time - customer_orders_temp.order_time) / 60 ) AS time_difference
FROM customer_orders_temp
LEFT JOIN runner_orders_temp
    ON runner_orders_temp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY runner_orders_temp.pickup_time, customer_orders_temp.order_time, customer_orders_temp.order_id)

SELECT
    num_pizza,
    CEIL(AVG(time_difference)) AS avg_prep_time_in_minutes
FROM cte
GROUP BY num_pizza
ORDER BY num_pizza ASC
````

**Answer:**

![Captura de pantalla 2024-05-08 130620](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/46baf880-2439-42b1-bf02-68df4a4fd1a3)

- On average, it takes **13** minutes to make 1 pizza.
- To make 2 pizzas takes **19** minutes, on average it takes 9.5 minutes per pizza.
- To make 3 pizzas takes **30** minutes, on average it takes 10 minutes per pizza.

***

### 4. What was the average distance travelled for each customer?

````sql
SELECT
    customer_id,
    ROUND(AVG(distance), 2) AS avg_distance_travelled
FROM runner_orders_temp
LEFT JOIN customer_orders_temp
    ON runner_orders_temp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY customer_id
````

**Answer:**

![Captura de pantalla 2024-05-08 131652](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/4fafa8f4-98b3-48e6-ba48-588278210b05)

- `customer_id` 104 is the closest to the branch with an average distance of **10** km, while the customer with `customer_id` 105 is the farthest with an average distance of **25** km.

***

### 5. What was the difference between the longest and shortest delivery times for all orders?

````sql
SELECT
    MAX(duration) - MIN(duration) AS delivery_times_difference
FROM runner_orders_tempp -- runner_orders_temp
WHERE duration != 0
````

**Answer:**

![Captura de pantalla 2024-05-08 132707](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/d06b05a4-c632-4ab0-88cd-60e56e08d977)

- The difference between the longest and shortest delivery is **30** minutes.

***

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

````sql
SELECT
    runner_orders_temp.runner_id,
    COUNT(customer_orders_temp.order_id) AS pizzas_count,
    (runner_orders_temp.distance::double precision / runner_orders_temp.duration::double precision * 60) AS avg_speed
FROM runner_orders_temp
JOIN customer_orders_temp
    ON runner_orders_temp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY runner_orders_temp.runner_id, runner_orders_temp.distance, runner_orders_temp.duration
````

**Answer:**

![Captura de pantalla 2024-05-08 134240](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/1766a333-5c9b-4ab5-a2ee-8ec1076dff8b)

- To calculate the average speed we will use this formula: Average Speed = Distance / Time.
- For runner 1, average speed run goes from 37km/h to 60km/h, normally when carrying +2 pizzas the speed goes up to that when carrying only 1 pizza.
- For runner 2, average speed run goes from 34.5km/h to 92km/h, it would be necessary to check why the speed increase was so drastic, ¡stop it! haha.
- For runner 3, average speed is 40km/h.


***

### 7. What is the successful delivery percentage for each runner?

````sql
SELECT
    runner_id,
    CONCAT(ROUND(100 * SUM(CASE 
            WHEN distance != 0 THEN 1
            ELSE 0
       END) / COUNT(*), 0),'%') AS succesful_delivers
FROM runner_orders_tempp
GROUP BY runner_id
ORDER BY runner_id ASC
````

**Answer:**

![Captura de pantalla 2024-05-08 173645](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/39baa0c2-c55e-4ddb-8f9a-d35fd0821334)

- Runner 1 has 100% of succesful delivery.
- Runner 2 has 75% of succesful delivery.
- Runner 3 has 50% of succesful delivery.

***
