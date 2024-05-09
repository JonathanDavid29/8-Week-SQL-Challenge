--                  DATA CLEANING

CREATE TEMPORARY TABLE customer_orders_temp AS
SELECT
	order_id,
	customer_id,
	pizza_id,
	CASE 
		WHEN exclusions IS null OR exclusions LIKE '%null%' THEN ' '
		ELSE exclusions
	END AS exclusions,
	CASE 
		WHEN extras IS null OR extras LIKE '%null%' OR extras LIKE '%NaN%' THEN ' '
		ELSE extras
	END AS extras,
	order_time
FROM pizza_runner.customer_orders;

CREATE TEMPORARY TABLE runner_orders_temp AS
SELECT
	order_id,
	runner_id,
	CASE 
		WHEN pickup_time IS null OR pickup_time LIKE '%null%' THEN ' '
		ELSE pickup_time
	END AS pickup_time,
	CASE 
		WHEN distance IS null OR distance LIKE '%null%' THEN ' '
		WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
		ELSE distance 
	END AS distance,
	CASE
		WHEN duration IS null OR duration LIKE '%null%' THEN ' '
		WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
		ELSE duration
	END AS duration,
	CASE 
		WHEN cancellation IS null OR cancellation LIKE '%null%' OR cancellation LIKE '%NaN%' THEN ' '
		ELSE cancellation
	END AS cancellation
FROM pizza_runner.runner_orders;

ALTER TABLE runner_orders1
ALTER COLUMN distance TYPE double precision USING distance::double precision,
ALTER COLUMN duration TYPE INT USING duration::integer,
ALTER COLUMN pickup_time TYPE timestamp USING pickup_time::timestamp WITHOUT time zone;

--                  A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT
	COUNT(pizza_id) AS orders
FROM customer_orders_temp

-- 2. How many unique customer orders were made?
SELECT
	COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders_temp

-- 3. How many successful orders were delivered by each runner?
SELECT 
	runner_id,
	COUNT(order_id) AS succesful_orders
FROM runner_orders_tempp -- runner_orders_temp
WHERE distance != 0
GROUP BY runner_id
ORDER BY succesful_orders DESC

-- 4. How many of each type of pizza was delivered?
SELECT
	pizza_names.pizza_name,
	COUNT(customer_orders_temp.pizza_id)
FROM customer_orders_temp
LEFT JOIN pizza_runner.pizza_names 
	ON customer_orders_temp.pizza_id = pizza_runner.pizza_names.pizza_id
LEFT JOIN runner_orders_tempp -- runner_orders_temp
	ON customer_orders_temp.order_id = runner_orders_tempp.order_id
WHERE distance != 0
GROUP BY pizza_names.pizza_name

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	customer_id,
	pizza_names.pizza_name,
	COUNT( pizza_names.pizza_name)
FROM customer_orders_temp
LEFT JOIN pizza_runner.pizza_names 
	ON customer_orders_temp.pizza_id = pizza_runner.pizza_names.pizza_id
GROUP BY customer_id, pizza_names.pizza_name
ORDER BY customer_id ASC

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH cte AS(
	SELECT
		customer_orders_temp.order_id,
		COUNT(customer_orders_temp.order_id) AS count_p
	FROM customer_orders_temp
	LEFT JOIN runner_orders_tempp -- runner_orders_temp
	ON customer_orders_temp.order_id = runner_orders_tempp.order_id 
	WHERE runner_orders_tempp.distance != 0 
	GROUP BY customer_orders_temp.order_id
)

SELECT 
	MAX(count_p) AS maximum_pizzas_delivered
FROM cte

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
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
LEFT JOIN runner_orders_tempp -- runner_orders_temp
	ON customer_orders_temp.order_id = runner_orders_tempp.order_id
WHERE distance != 0
GROUP BY customer_id
ORDER BY customer_id ASC

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM(CASE
	   		WHEN exclusions IS NOT null AND exclusions <> ' ' 
				AND extras IS NOT NULL AND extras <> ' ' THEN 1
	   		ELSE 0
	  	END) AS test
FROM customer_orders_temp
LEFT JOIN runner_orders_tempp -- runner_orders_temp
	ON customer_orders_temp.order_id = runner_orders_tempp.order_id
WHERE distance != 0

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
	EXTRACT(HOUR FROM order_time) AS hour,
	COUNT(order_id) pizzas_ordered_for_each_hour
FROM customer_orders_temp
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY hour ASC

-- 10. What was the volume of orders for each day of the week?
SELECT
	TO_CHAR(order_time + INTERVAL '2 DAYS','Day') AS week_day,
	COUNT(order_id) AS orders
FROM customer_orders_temp
GROUP BY week_day
ORDER BY week_day ASC


--                  B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	EXTRACT(WEEK FROM registration_date) AS registration_week,
	COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH calculate_time AS(
	SELECT
	runner_id,
	EXTRACT(EPOCH FROM (runner_orders_tempp.pickup_time - customer_orders_temp.order_time) / 60 ) AS time_difference
	FROM runner_orders_tempp -- runner_orders_temp
	LEFT JOIN customer_orders_temp
		ON runner_orders_tempp.order_id = customer_orders_temp.order_id
	WHERE distance != 0
	GROUP BY runner_id, runner_orders_tempp.pickup_time, customer_orders_temp.order_time
)

SELECT 
	CEIL(AVG(time_difference)) AS avg_time_in_minutes --> 15.97 = 16
FROM calculate_time 

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS(
SELECT 
	COUNT(customer_orders_temp.order_id) AS num_pizza,
	EXTRACT(EPOCH FROM (runner_orders_tempp.pickup_time - customer_orders_temp.order_time) / 60 ) AS time_difference
FROM customer_orders_temp
LEFT JOIN runner_orders_tempp -- runner_orders_temp
	ON runner_orders_tempp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY runner_orders_tempp.pickup_time, customer_orders_temp.order_time, customer_orders_temp.order_id)

SELECT
	num_pizza,
	CEIL(AVG(time_difference)) AS avg_prep_time_in_minutes
FROM cte
GROUP BY num_pizza
ORDER BY num_pizza ASC

-- 4. What was the average distance travelled for each customer?
SELECT
	customer_id,
	ROUND(AVG(distance), 2) AS avg_distance_travelled
FROM runner_orders_tempp -- runner_orders_temp
LEFT JOIN customer_orders_temp
	ON runner_orders_tempp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY customer_id

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
	MAX(duration) - MIN(duration) AS delivery_times_difference
FROM runner_orders_tempp -- runner_orders_temp
WHERE duration != 0

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
	runner_orders_tempp.runner_id,
	COUNT(customer_orders_temp.order_id) AS pizzas_count,
	(runner_orders_tempp.distance::double precision / runner_orders_tempp.duration::double precision * 60) AS avg_speed
FROM runner_orders_tempp -- runner_orders_temp
JOIN customer_orders_temp
	ON runner_orders_tempp.order_id = customer_orders_temp.order_id
WHERE distance != 0
GROUP BY runner_orders_tempp.runner_id, runner_orders_tempp.distance, runner_orders_tempp.duration

-- 7. What is the successful delivery percentage for each runner?
SELECT
	runner_id,
	CONCAT(ROUND(100 * SUM(CASE 
			WHEN distance != 0 THEN 1
	   		ELSE 0
	   END) / COUNT(*), 0),'%') AS succesful_delivers
FROM runner_orders_tempp
GROUP BY runner_id
ORDER BY runner_id ASC

--                  C. Ingredient Optimization

-- 1. What are the standard ingredients for each pizza?
WITH full_pizza_temp AS(
	SELECT
		pizza_id,
		pizza_toppings.topping_id,
		pizza_toppings.topping_name
	FROM pizza_runner.pizza_recipes
	CROSS JOIN LATERAL unnest(string_to_array(toppings, ',')) AS value -- toma la columna toppings de pizza_recipes que parece ser una lista de ingredientes de pizza 
	JOIN pizza_runner.pizza_toppings                                   -- separada por comas, la divide en una matriz usando 'string_to_array', luego usa 'unnest'
		ON value::INTEGER = pizza_toppings.topping_id         -- para expandir la matriz en filas, la clausula 'CROSS JOIN LATERAL' asegura que esta operacion
	)																   -- se realice para cada fila de la tabla 'pizza_recipes'

SELECT 
	pizza_names.pizza_name,
	STRING_AGG(topping_name, ', ') AS standar_ingredients
FROM full_pizza_temp
LEFT JOIN pizza_runner.pizza_names
ON full_pizza_temp.pizza_id = pizza_names.pizza_id
GROUP BY pizza_names.pizza_name

-- 2. What was the most common exclusion?
WITH unnesting_exclusions AS(
SELECT
	unnest(string_to_array(exclusions, ',')) AS splited_exclusions
FROM customer_orders_temp
WHERE exclusions <> null OR exclusions <> ' '
)


SELECT 
	pizza_toppings.topping_name,
	COUNT(splited_exclusions) AS exclusions_count
FROM unnesting_exclusions
INNER JOIN pizza_runner.pizza_toppings
	ON pizza_toppings.topping_id = unnesting_exclusions.splited_exclusions::integer
GROUP BY pizza_toppings.topping_name
ORDER BY exclusions_count DESC
LIMIT 1



-- Other way to approach to the problem

SELECT 
	pizza_toppings.topping_name,
	COUNT(pizza_id) AS exclusions_count
FROM customer_orders_temp
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+') AS st(value) ON true
INNER JOIN pizza_runner.pizza_toppings
	ON pizza_toppings.topping_id = st.value::INTEGER
WHERE LENGTH(st.value) > 0
GROUP BY pizza_toppings.topping_name
ORDER BY exclusions_count DESC
LIMIT 1

-- 3. What was the most commonly added extra?
SELECT 
	pizza_toppings.topping_name,
	COUNT(pizza_id) AS extras_count
FROM customer_orders_temp
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+') AS st(value) ON true
INNER JOIN pizza_runner.pizza_toppings
	ON pizza_toppings.topping_id = st.value::INTEGER
WHERE LENGTH(st.value) > 0
GROUP BY pizza_toppings.topping_name
ORDER BY extras_count DESC
LIMIT 1

/* 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
WITH extras AS(
	SELECT 
		order_id,
		pizza_id,
		extras,
		STRING_AGG(DISTINCT pizza_toppings.topping_name , ', ') AS added_extra
	FROM customer_orders_temp
	LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+') AS st(value) ON true
	INNER JOIN pizza_runner.pizza_toppings
		ON pizza_toppings.topping_id = st.value::INTEGER
	WHERE LENGTH(st.value) > 0
	AND st.value <> 'null'
	GROUP BY order_id, pizza_id, extras
)
,
excluded AS(
	SELECT 
		order_id,
		pizza_id,
		exclusions,
		STRING_AGG(DISTINCT pizza_toppings.topping_name , ', ') AS excluded
	FROM customer_orders_temp
	LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+') AS st(value) ON true
	INNER JOIN pizza_runner.pizza_toppings
		ON pizza_toppings.topping_id = st.value::INTEGER
	WHERE LENGTH(st.value) > 0
		AND st.value <> 'null'
	GROUP BY order_id, pizza_id, exclusions
)

SELECT 
	co.order_id,
	CONCAT(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 'Meat Lovers' ELSE pn.pizza_name END,
		   COALESCE(' - Extra ' || ext.added_extra, ' '),
		   COALESCE(' - Exclude ' || exc.excluded, ' '))  AS order_details
FROM customer_orders_temp AS co
LEFT JOIN extras as ext ON ext.order_id = co.order_id AND ext.pizza_id = co.pizza_id AND ext.extras = co.extras
LEFT JOIN excluded as exc ON exc.order_id = co.order_id AND exc.pizza_id = co.pizza_id AND exc.exclusions = co.exclusions
INNER JOIN pizza_runner.pizza_names AS pn ON pn.pizza_id = co.pizza_id






