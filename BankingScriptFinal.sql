-- Creating Database 
create database banking_cases;

show tables;

select * from banking_uncleaned limit 10;

-- Imported 3 more tables and changed name of 1 table 
RENAME TABLE banking_uncleaned TO customers;

-- Adding columns to store value 
ALTER TABLE customers ADD COLUMN Gender VARCHAR(10);
ALTER TABLE customers ADD COLUMN InvestmentAdvisor VARCHAR(100);
ALTER TABLE customers ADD COLUMN BankingRelationship VARCHAR(50);

-- Improving database structure 

-- 1. Updating Gender
UPDATE customers c
JOIN gender g 
ON c.GenderId = g.GenderId
SET c.Gender = g.Gender;

-- 2. Updating Investment Advisor
UPDATE customers c
JOIN `investment advisor` ia 
ON c.IAId = ia.IAId
SET c.InvestmentAdvisor = ia.`Investment Advisor`;

-- 3. Update Banking Relationship
UPDATE customers c
JOIN `banking relationship` br 
ON c.BRId = br.BRId
SET c.BankingRelationship = br.`Banking Relationship`;

-- 4. Droping previous columns 

ALTER TABLE customers DROP COLUMN GenderId;
ALTER TABLE customers DROP COLUMN IAId;
ALTER TABLE customers DROP COLUMN BRId;

-- 5. Counting Number of columns 

SELECT COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers';

# Cleaning tables 

select * from customers;

-- 1. Detect Duplicate Clients:

SELECT `Client ID`, COUNT(*) AS count
FROM customers
GROUP BY `Client ID`
HAVING count >  1;

WITH ranked_customers AS (
  SELECT *, 
         ROW_NUMBER() OVER (PARTITION BY `Client ID` ORDER BY `Client ID`) AS rn
  FROM customers
)

DELETE FROM customers
WHERE `Client ID` IN (
  SELECT `Client ID` FROM ranked_customers WHERE rn > 1
);

-- 2. Dropping unwanted columns

ALTER TABLE customers
DROP COLUMN `duplicate age`;

ALTER TABLE customers
DROP COLUMN `Name_copy`;

 -- 3. Null or Missing Values

DELETE FROM customers
WHERE Age IS NULL
   OR TRIM(Age) = '';

-- 4. Invalid age column 

SELECT * FROM customers
WHERE Age < 18 OR Age > 100;

DELETE FROM customers
WHERE Age > 100;

-- 5. Negative or Invalid Income

SELECT * FROM customers
WHERE `Estimated Income` < 0;

delete from customers 
where `Estimated Income` < 0;

-- 6. Inconsistent Occupation Formatting

SELECT DISTINCT Occupation
FROM customers
WHERE Occupation = '' OR Occupation = LOWER(Occupation);

UPDATE customers
SET Occupation = CONCAT(UCASE(LEFT(Occupation, 1)), LCASE(SUBSTRING(Occupation, 2)));

-- revewing cleaned dataset 
 select * from customers ; 

#. Data Exploration and Analysis

-- 1. Count total records:
SELECT COUNT(*) AS total_customers FROM customers;

-- 2. Gender-wise customer count:
select gender , count(*)
from customers
group by gender ;

-- 3. Customer count by Fee Structure:
SELECT `Fee Structure`, COUNT(*) AS total FROM customers GROUP BY `Fee Structure`;

-- 4. Average income by occupation:
SELECT Occupation, ROUND(AVG(`Estimated Income`), 2) AS avg_income
FROM customers
GROUP BY Occupation
ORDER BY avg_income DESC;

-- 5. Top 5 customers by loan amount:
SELECT `Client ID`, Name, `Bank Loans` FROM customers ORDER BY `Bank Loans` DESC LIMIT 5;

-- 6. count customers who joined after 2018
SELECT COUNT(*) FROM customers
WHERE STR_TO_DATE(`Joined Bank`, '%d-%m-%Y') >= '2019-01-01';

-- 7. SELECT * FROM customers WHERE `Properties Owned` > 2;

SELECT * FROM customers WHERE `Properties Owned` > 2;


-- 8. Unique Value Counts for advisors top performing advisors 

SELECT DISTINCT `InvestmentAdvisor` , count(*) FROM customers group by `InvestmentAdvisor`;

-- 9. count for clients of all domains

SELECT DISTINCT `BankingRelationship`, count(*) FROM customers group by `BankingRelationship`;

-- 10. Age Distribution (Grouped)

SELECT 
  CASE 
    WHEN Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN Age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '51+' 
  END AS age_group,
  COUNT(*) AS total
FROM customers
GROUP BY age_group ;

-- 11. Filtering Nationality 

select nationality , count(*)
from customers group by nationality ; 

-- ================================================
-- Adding new column to identify high potential leads
-- for sales outreach (credit cards, loans, etc.)
--
-- Criteria Used:
-- +-------------------------------+---------------------------------------------------+
-- | Criteria                      | Meaning                                           |
-- +-------------------------------+---------------------------------------------------+
-- | Age BETWEEN 25 AND 60         | Active working age                               |
-- | Estimated Income > 150000     | Financial capability                             |
-- | Risk Weighting <= 3           | Low to medium risk profile                       |
-- | Credit Card Balance < 50000   | Not over-utilizing credit                        |
-- | Amount of Credit Cards < 3    | Room for cross-selling credit cards              |
-- | Bank Deposits > 100000        | Good banking history                             |
-- | Saving + Checking > 50000     | Indicates healthy account activity               |
-- +-------------------------------+---------------------------------------------------+
-- Result:
-- Adds a column `High_Potential_Leads` marked 'Yes' or 'No'
-- based on the criteria above.
-- ================================================


ALTER TABLE 
customers 
ADD COLUMN High_Potential_Lead VARCHAR(3);

UPDATE customers
SET High_Potential_Lead = 
  CASE 
    WHEN Age BETWEEN 25 AND 60
      AND `Estimated Income` > 150000
      AND `Risk Weighting` <= 3
      AND `Credit Card Balance` < 50000
      AND `Amount of Credit Cards` < 3
      AND `Bank Deposits` > 100000
      AND (`Saving Accounts` + `Checking Accounts`) > 50000
    THEN 'Yes'
    ELSE 'No'
  END;

select count(*) from customers 
where High_Potential_Lead = "yes";

select * from customers ; 