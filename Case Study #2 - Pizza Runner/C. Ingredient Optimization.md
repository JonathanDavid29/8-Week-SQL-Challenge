## 🍗⌛ C. Ingredient Optimization.

### 1. What are the standard ingredients for each pizza?

````sql
WITH full_pizza_temp AS(
  SELECT
    pizza_id,
    pizza_toppings.topping_id,
    pizza_toppings.topping_name
  FROM pizza_runner.pizza_recipes
  CROSS JOIN LATERAL unnest(string_to_array(toppings, ',')) AS value 
  JOIN pizza_runner.pizza_toppings                                   
    ON value::INTEGER = pizza_toppings.topping_id         
  )																  

SELECT 
  pizza_names.pizza_name,
  STRING_AGG(topping_name, ', ') AS standar_ingredients
FROM full_pizza_temp
LEFT JOIN pizza_runner.pizza_names
ON full_pizza_temp.pizza_id = pizza_names.pizza_id
GROUP BY pizza_names.pizza_name
````
**Answer:**

![Captura de pantalla 2024-05-08 175451](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/9e39109a-63d0-4cbb-a5d2-2c6388e23b8e)

**Steps:**
- Take the toppings column of `pizza_recipes` which appears to be a comma separated list of pizza toppings, splits it into an array using `string_to_array`, then uses `unnest` to expand the array into rows, the `CROSS JOIN LATERAL` clause ensures that this operation is performed for each row of the table `pizza_recipes`.

***

### 2. What was the most common exclusion?

````sql
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
  ON pizza_toppings.topping_id = unnesting_exclusions.splited_exclusions::INTEGER
GROUP BY pizza_toppings.topping_name
ORDER BY exclusions_count DESC
LIMIT 1
````
**Answer:**

![Captura de pantalla 2024-05-08 182453](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/844a702a-6929-4594-8088-f3e8103e1b30)

Note: 
Another very interesting way to approach this problem I discovered through a Youtube video of [Will](https://www.linkedin.com/in/will-sutton-14711627), who is a seasoned professional with over 10 years of experience, he also won in 2022 the Conquering Iron Viz competition, so his experience speaks for itself.

````sql
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
-- LIMIT 1
````

>In terms of performance and the low amount of data, the time difference between my query (169ms) and his (171ms) is minimal.

***

### 4. (Final Boss 💀) Generate an order item for each record in the `customers_orders` table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

````sql
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
````
**Answer:**

![Captura de pantalla 2024-05-08 191139](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/ddd7ce04-8768-421e-a164-b72dad1ab51c)

***


