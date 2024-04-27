# 🍕 Case Study #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" width="500" height="500">

## 📋Table of Contents
* [Business Task](#business-task)
* [Entity Relationship Diagram](#entity-relationship-diagram)
* [Question and Solution](#question-and-solution)

***
## Business Task
Danny was enthusiastic about his pizza business idea, recognizing that pizza sales alone wouldn't secure the funding he needed to grow his Pizza Empire. To enhance his strategy, he decided to "Uberize" it,
leading to the launch of Pizza Runner. Despite maxing out his credit card to hire freelance developers for a mobile app, he now seeks assistance in cleaning data and performing basic calculations to optimize 
Pizza Runner's operations, using the entity relationship diagram he's prepared.

***
## Entity Relationship Diagram
![diagrama 2](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/75272cdb-d2b6-4f3e-a1d0-c668949db603)

***
## 🧽 Data Cleaning & Transformation

### Table: customer_orders.

Looking at table `customer_orders`, we can see that there are some irregularities:
- `exclusion` column, there are missing values, blanks and null values.
- `extras` column, there are missing values, blanks and null values.

![customers_orders](https://github.com/JonathanDavid29/8-Week-SQL-Challenge/assets/69162164/d9a55beb-3b67-4b46-9f9c-64cd927aada9")

Steps:
- Create a temporary table with all the columns.
- Remove null values in `exlusions` and `extras` columns and replace with blank space ' '.

````sql
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
````

***
## Question and Solution

***
