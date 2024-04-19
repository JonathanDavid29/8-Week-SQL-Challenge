-- 1. What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id, 
    SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_amount DESC 

-- 2. How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    COUNT(s.product_id) AS times_purchased
FROM dannys_diner.menu AS m
LEFT JOIN dannys_diner.sales AS s
    ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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

-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
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

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
    SUM(
	CASE 
	    WHEN m.product_name = 'sushi' THEN m.price * 20
	    ELSE m.price * 10
	END) AS user_points
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY user_points DESC

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?*/
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


-- Bonus Question
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
