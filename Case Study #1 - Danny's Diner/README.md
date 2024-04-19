# 🍜 Case Study #1 - Danny's Diner.
<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" width="500" height="500">

## Table of Contents
* [Business Task](#business-task)
* [Entity Relationship Diagram](#entity-relationship-diagram)
* [Question and Solution](#question-and-solution)

***
## Business Task
Danny aims to utilize the data to glean insights into customer behavior, particularly focusing on visitation trends, expenditure patterns, and preferred menu items. By establishing this deeper understanding of his clientele, he endeavors to enhance and personalize their experience, fostering stronger relationships with his loyal customer base.
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
- Use **INNER JOIN** to merge `dannys_diner.sales` & `dannys_diner.menu` tables through their `product_id` column.
- Use **SUM** to calculate total sales by each customer.
- Group the aggregated results by `s.customer_id`.
- Sort by `total_amount` in descending order to see which customers have spent the most.

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
- Use **COUNT** to count the number of days visited, but here it is important to apply the **DISTINCT** keyword to avoid duplicating the count of a day in which the customer has visited the establishment more than once.
- Group the aggregated results by `customer_id`.

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
- Create a Common Table Expression **(CTE)** called `ranking_by_date`, inside this cte we create a new column `rk` and calculate the row number using ROW_NUMBER() windows function.
- Out of the CTE, in the other query select the relevant columns, then filter in the **WHERE** clause by the `rk` column where the rows are equal to 1, which represents the first row after partitioning by `rd.customer_id`.

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
- Use **COUNT** aggregation function on `s.product_id` to get the number of times a product was purchased, and **ORDER BY** our created column `times_purchased` in descending order.
- At this point I decided not to add **LIMIT 1** at the end of the query, which would allow us to see only the most purchased product **(ramen -> 8)**, I left it like this to see the subsequent products.

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
- Create a CTE called `ranking_items`, join the tables `dannys_diner.sales` and `dannys_diner.menu` by the common column `product_id`.
- Group results by `customer_id` and `product_name`.
- Create the `rk` column in which we will partition by `customer_id` and calculate the count with the `product_id` column for each guy, these results are sorted in descending order.
- Out of the CTE, in the other query select the relevant columns, then filter in the WHERE clause by the `rk` column where the rows are equal to 1.

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
- Create 2 CTE, `cte` in which we rank the items and it does exactly the same as in the above problem, the difference is that we filter with a condition `(s.order_date >= m.join_date)` in where clause to get only the items purchased when the customer became a member.
- In CTE `joining_the_item` join the tables `cte` and `dannys_diner.menu`, then filter in WHERE clause by the column `rk` where the rows are equal to 1, select the desired columns.
- In the outer query order the results by `customer_id` column in ascending order.

>**Note:** I know that this particular case can be done exactly the same as case #5, but I am practicing what can be done with CTE's.

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
- Create a CTE called `ranking_by_date`, select the relevant columns, create a new column `rk` and calculate the row number using the windows function **DENSE_RANK()** as it ranks us without leaving gaps between rows.
- Join the tables `dannys_diner.sales` and `dannys_diner.Members` through `customer_id` column.
- Join the tables `dannys_diner.sales` and `dannys_diner.menu` through `product_id` column.
- Filter with a condition `(s.order_date < m.join_date)` in where clause.
- Sort the results by `menu.product_name` in ascending order.

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
- Select `customer_id` column, calculate the count with `s.*`, or if you want to be more specific use `s.product_id` to get the total purchases as items_bought and calculate the sum of `menu.price` as total_amount_spent.
- Join the tables `dannys_diner.sales` and `dannys_diner.menu` through `s.product_id` column.
- Join the tables `dannys_diner.sales` and `dannys_diner.Members` through `s.customer_id` column.
- Filter with a condition `(s.order_date < m.join_date)` in where clause.
- Group results by `s.customer_id` column.
- Sort the results by `s.customer_id` in ascending order.

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
Let's break down the question to understand the point about how to calculate the points for each user.
- Each $1 spent = 10 points, in the case of the **sushi** product you get 2x points, so $1 spent = 20 points.
- Here's how the calculation is performed using a conditional **CASE statement**:
	- If `product_id = 'sushi'`, multiply every $1 by 20 points.
	- Otherwise, multiply $1 by 10 points.
- Then calculates the sum of the user_points for each user

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
#### Understanding the problem
- Day 1-7 the client becomes a member, each $1 spent = 20 on all items.
- Day 8 to the last day of January, each $1 spent = 10 on all items.
  
#### Steps
- Create a CTE called `members_week`, calculate `complete_week` by adding 6 days to join_date 
- Join the tables `dannys_diner.sales` and `dannys_diner.menu` through `s.product_id` column.
- Join the tables `dannys_diner.sales` and `members_week` through `mw.customer_id` column.
- Filter with a condition `(s.order_date >= mw.join_date)` in where clause to ensure that the date of purchase is the same day or after he has become a member and filter by January month `EXTRACT(MONTH FROM s.order_date) = 1`
- Then calculates the sum of `user_points` for each user
- Group results by `s.customer_id` column.
- Sort the results by `user_points` in descending order.

#### Answer
| customer_id | user_points |
| ----------- | ----------- |
| A           | 1020        |
| B           | 320         |

- Customer A is the highest point user with 1020 points in January.
- Customer B have 320 points.

***

### Bonus Question
* **Join all the things and crecreate the table with_ customer_id, order_date, product_name, price, member (Y/N)**
* **Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.**
````sql
WITH Dannys_diner_table AS(
  SELECT
    s.customer_id,
    s.order_date,
    menu.product_name,
    menu.price,
    CASE WHEN s.order_date >= m.join_date THEN 'Y' ELSE 'N' END AS member
  FROM dannys_diner.sales AS s
  LEFT JOIN dannys_diner.menu
    ON s.product_id = menu.product_id
  LEFT JOIN dannys_diner.Members AS m
    ON s.customer_id = m.customer_id
)

SELECT 
  *,
  CASE
    WHEN member = 'N' THEN NULL
    ELSE ROW_NUMBER() OVER(PARTITION BY customer_id, member ORDER BY order_date)
  END AS ranking
FROM Dannys_diner_table
````
#### Answer
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL

***
☝🏽 **All the information for this case study has been obtained from this** [website](https://8weeksqlchallenge.com/case-study-1/)
