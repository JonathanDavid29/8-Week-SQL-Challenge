# 🍜 Case Study #1 - Danny's Diner.
<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" width="500" height="500">

## Table of Contents
* [Business Task](#business-task)
* [Entity Relationship Diagram](#entity-relationship-diagram)
* [Question and Solution](#question-and-solution)

***
## Business Task
bsdssd

***
## Entity Relationship Diagram
![1 db diagram](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/168b0f2b-f020-400c-9700-39b44d7e6dfa)

***
## Question and Solution

**1. What is the total amount each customer spent at the restaurant?**

````sql
SELECT
  s.customer_id,
  SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_amount DESC
````
#### Steps
- a
- b

#### Answer
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent **$76**.
- Customer B spent **$74**.
- Customer C spent **$36**.
***

**2. How many days has each customer visited the restaurant?**

````sql
SELECT
  customer_id,
  COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id
````
#### Steps
- a
- b

#### Answer
| customer_id | days_visited |
| ----------- | ------------ |
| A           | 4            |
| B           | 6            |
| C           | 2            |

- Customer A visited the restaurant for **4** days.
- Customer B visited the restaurant for **6** days.
- Customer C visited the restaurant for **2** days.
***

**3. What was the first item from the menu purchased by each customer?**

````sql
WITH ranking_by_date AS(
  SELECT
    customer_id,
    product_id,
    ROW_NUMBER() OVER( PARTITION BY customer_id ORDER BY order_date ASC) AS rk
  FROM dannys_diner.sales
)

SELECT 
  rd.customer_id,
  m.product_name
FROM ranking_by_date AS rd
INNER JOIN dannys_diner.menu AS m
  ON rd.product_id = m.product_id
WHERE rk = 1
````
#### Steps
- a
- b

#### Answer
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

- Customer A bought **sushi** for the first time.
- Customer B bought **curry** for the first time.
- Customer C bought **ramen** for the first time.
***

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

````sql
SELECT
  m.product_name,
  COUNT(s.product_id) AS times_purchased
FROM dannys_diner.menu AS m
LEFT JOIN dannys_diner.sales AS s
  ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
````
#### Steps
- a
- b

#### Answer
| product_name | times_purchased |
| ------------ | --------------- |
| ramen        | 8               |
| curry        | 4               |
| sushi        | 3               |

- Ramen is the most purchased item on the menu with 8 times purchased.
- In second place curry wih 4 times purchased.
- In third place sushi wih 3 times purchased.
***

**5. Which item was the most popular for each customer?**

````sql
WITH ranking_items AS(
  SELECT
    s.customer_id,
    m.product_name,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rk
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id,
  product_name
FROM ranking_items
WHERE rk = 1
````
#### Steps
- a
- b

#### Answer
| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | sushi        |
| C           | ramen        |

- Customer A loves ramen.
- Customer B loves sushi.
- Customer C loves ramen.
***

**6. Which item was purchased first by the customer after they became a member?**

````sql
WITH cte AS(
  SELECT
    s.customer_id,
    s.product_id,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS rk
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.members AS m
    ON s.customer_id = m.customer_id
  WHERE s.order_date >= m.join_date
)
,
joining_the_item AS(
  SELECT
    c.customer_id,
    m.product_name 
  FROM cte AS c
  LEFT JOIN dannys_diner.menu AS m
    ON c.product_id = m.product_id
  WHERE rk = 1
)

SELECT 
  * 
FROM joining_the_item
ORDER BY customer_id ASC
````
#### Steps
- a
- b

#### Answer
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |

- Customer A purchased curry after he became a member.
- Customer B purchased sushi after he became a member.

***

**7. Which item was purchased just before the customer became a member?**

````sql
WITH ranking_by_date AS(
  SELECT
    s.customer_id,
    s.order_date,
    menu.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rk
  FROM dannys_diner.sales AS s
  LEFT JOIN dannys_diner.Members AS m
    ON s.customer_id = m.customer_id
  LEFT JOIN dannys_diner.menu 
    ON s.product_id = menu.product_id
  WHERE s.order_date < m.join_date
  ORDER BY menu.product_name ASC
)

SELECT 
  customer_id,
  product_name
FROM ranking_by_date
WHERE rk = 1
````
#### Steps
- a
- b

#### Answer
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | sushi        |

- Customer A purchased curry & sushi the same day before he became a member.
- Customer B purchased sushi before he became a member.
***

**8. What is the total items and amount spent for each member before they became a member?**

````sql
SELECT
  s.customer_id,
  COUNT(s.*) AS items_bought,
  SUM(menu.price) AS total_amount_spent
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu 
  ON s.product_id = menu.product_id
LEFT JOIN dannys_diner.Members AS m
  ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id ASC
````
#### Steps
- a
- b

#### Answer
| customer_id | items_bought | total_amount_spent |
| ----------- | ------------ | ------------------ |
| A           | 2            | 25                 |
| B           | 3            | 40                 |

- Customer A bought 2 items and spent $25 before he became a member.
- Customer B bought 3 items and spent $40 before he became a member.
***

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

````sql
SELECT
  s.customer_id,
  SUM(
    CASE 
      WHEN m.product_name = 'sushi' THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS user_points
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY user_points DESC
````
#### Steps
- a
- b

#### Answer
| customer_id | user_points  |
| ----------- | ------------ |
| B           | 940          |
| A           | 860          |
| C           | 360          |

- Customer B is the highest point user with 940 points.
- Customer A have 860 points.
- Customer C have 360 points.
***

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

````sql
WITH members_week AS (
  SELECT
    customer_id,
    join_date,
    join_date + 6 AS complete_week
  FROM dannys_diner.members
)

SELECT
  s.customer_id,
  SUM(CASE
        WHEN s.order_date BETWEEN mw.join_date AND mw.complete_week  THEN menu.price * 20
        ELSE menu.price * 10
      END) AS user_points
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu 
  ON s.product_id = menu.product_id
LEFT JOIN members_week AS mw
  ON s.customer_id = mw.customer_id
WHERE s.order_date >= mw.join_date
  AND EXTRACT(MONTH FROM s.order_date) = 1
GROUP BY s.customer_id
ORDER BY user_points DESC
````
#### Steps
- a
- b

#### Answer
| customer_id | user_points |
| ----------- | ----------- |
| A           | 1020        |
| B           | 320         |

- Customer A is the highest point user with 1020 points in January.
- Customer B have 320 points.

***
