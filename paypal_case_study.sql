USE paypal_cs;

SHOW TABLES;

DESC countries;
DESC currencies;
DESC merchants;
DESC transactions;
DESC users;

/* Determine the top 5 countries by total transaction amount for both sending and receiving funds in the last quarter of 2023 (October to December 2023).
 Provide separate lists for the countries that sent the most funds and those that received the most funds. 
 Additionally, round the totalsent and totalreceived amounts to 2 decimal places.*/
SELECT C.Country_Name AS country_name,ROUND(SUM(T.Transaction_amount), 2) AS total_sent
FROM Transactions T
JOIN Users U ON T.Sender_ID = U.User_ID
JOIN Countries C ON U.Country_ID = C.Country_ID
WHERE T.Transaction_date BETWEEN '2023-10-01' AND '2024-01-01'
GROUP BY C.Country_Name
ORDER BY total_sent DESC
LIMIT 5;

SELECT C.Country_name AS country_name, ROUND(SUM(T.Transaction_amount),2) AS total_received
FROM Transactions T
JOIN Users U ON T.Recipient_ID = U.User_ID
JOIN Countries C ON U.Country_ID = C.Country_ID
WHERE T.Transaction_date BETWEEN '2023-10-01' AND '2024-01-01'
GROUP BY C.Country_Name
ORDER BY total_received DESC
LIMIT 5;

-- Find transactions exceeding $10,000 in the year 2023 and include transaction ID, sender ID, recipient ID (if available), transaction amount, and currency used.
SELECT transaction_id, sender_id, recipient_id, transaction_amount, currency_code
FROM Transactions
WHERE transaction_amount > 10000 AND transaction_date BETWEEN '2023-01-01' AND '2024-01-01';

/* Analyze the transaction data and determine the top 10 merchants, sorted by the total transaction amount they received, 
within the period from November 2023 to April 2024. For each of these top 10 merchants, provide the following details: 
merchant ID, business name, the total transaction amount received, and the average transaction amount.*/
SELECT M.merchant_id, M.business_name, SUM(T.transaction_amount) AS AmountReceived, AVG(T.transaction_amount) AS AvgTransactionAmount
FROM merchants M
JOIN transactions T ON T.Recipient_id = M.merchant_id
WHERE T.transaction_date BETWEEN '2023-11-01' AND '2024-05-01'
GROUP BY M.merchant_id, M.business_name
ORDER BY AmountReceived DESC
LIMIT 10;

/* Analyze currency conversion trends from 22 May 2023 to 22 May 2024. 
Calculate the total amount converted from each source currency to the top 3 most popular destination currencies.
*/
SELECT currency_code,SUM(transaction_amount) AS total_converted
FROM transactions
WHERE transaction_date BETWEEN '2023-05-22' AND '2024-05-22'
GROUP BY currency_code
ORDER BY total_converted DESC
LIMIT 3;

/* Categorize transactions as 'High Value' (above $10,000) or 'Regular' (less than or equal to $10,000) and
 calculate the total amount for each category for the year 2023.*/
SELECT CASE
		WHEN transaction_amount > 10000 THEN "High Value"
        WHEN transaction_amount <= 10000 THEN "Regular"
	END AS transaction_category, SUM(transaction_amount) AS total_amount
FROM transactions
WHERE transaction_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY transaction_category;

/* analyze transaction data for the first quarter of 2024 (January to March).
Your task is to create a new column in the dataset that indicates whether each transaction is international (where the sender and recipient are from different countries)
or domestic (where the sender and recipient are from the same country).Additionally, provide a count of the number of international and 
domestic transactions for this period.*/
SELECT CASE
		WHEN S.country_id = R.country_id THEN "Domestic"
        ELSE "International"
	END AS transaction_type, COUNT(*) AS transaction_count
FROM transactions T
JOIN users S ON S.user_id = T.sender_id
JOIN users R ON R.user_id = T.recipient_id
WHERE T.transaction_date BETWEEN '2024-01-01' AND '2024-04-01'
GROUP BY transaction_type;

/* Your task is to calculate the average transaction amount per user (Round up to 2 Decimal Places) for the past six months,
covering the period from November 2023 to April 2024.  Once you have the average transaction amount for each user, 
identify and list the users whose average transaction amount exceeds $5,000.
Order the result by user_id in ascending order.*/
WITH Temp AS(
SELECT U.user_id, U.email, ROUND(AVG(T.transaction_amount),2) AS Avg_amount
FROM transactions T
JOIN users U ON U.user_id = T.sender_id
WHERE T.transaction_date BETWEEN '2023-11-01' AND '2024-05-01'
GROUP BY U.user_id, U.email
)
SELECT user_id,email, Avg_amount
FROM Temp
WHERE Avg_amount > 5000
ORDER BY user_id;

/* Your task is to extract the month and year from each transaction date and then calculate the total transaction amount for each month-year combination.
This will involve summarizing the total transactions on a monthly basis to provide a clear view of financial activities throughout the year. 
Please ensure that your report includes a breakdown of the total transaction amounts for each month and year combination for 2023,
helping the finance team to review and analyze the company's monthly financial performance comprehensively.*/
SELECT EXTRACT(YEAR FROM transaction_date) AS transaction_year, EXTRACT(MONTH FROM transaction_date) AS transaction_month, 
SUM(transaction_amount) AS total_amount
FROM transactions
WHERE transaction_date BETWEEN '2023-01-01' AND '2024-01-01'
GROUP BY transaction_year, transaction_month
ORDER BY transaction_year, transaction_month;

/* your task is to determine the user who has the highest total transaction amount from May 22, 2023, to May 22, 2024.
provide the details of this user, including their user ID,email, name, and total transaction amount. */
SELECT U.user_id, U.email, U.Name, ROUND(SUM(T.transaction_amount),2) AS total_amount
FROM users U
JOIN transactions T ON T.sender_id = U.user_id
WHERE T.transaction_date BETWEEN '2023-05-22' AND '2024-05-23'
GROUP BY U.user_id, U.email, U.Name
ORDER BY total_amount DESC
LIMIT 1;

/* The sales team wants to identify top-performing merchants. 
Which merchant should be considered as the most successful in terms of total transaction amount received between November 2023 and April 2024?*/
SELECT M.business_name, SUM(T.transaction_amount) AS total_amount
FROM merchants M
JOIN transactions T ON T.recipient_id = M.merchant_id
WHERE T.transaction_date BETWEEN '2023-11-01' AND '2024-05-01'
GROUP BY M.business_name
ORDER BY total_amount DESC;

/* Create a report that categorizes transactions into 'High Value International', 'High Value Domestic', 'Regular International', and
'Regular Domestic' based on the following criteria:
High Value: transaction amount > $10,000
International: sender and recipient from different countries
Write a query to categorize each transaction and count the number of transactions in each category for the year 2023.*/
SELECT CASE
		WHEN S.country_id != R.country_id AND T.transaction_amount > 10000 THEN "High Value International"
        WHEN S.country_id = R.country_id AND T.transaction_amount > 10000 THEN "High Value Domestic"
        WHEN S.country_id != R.country_id AND T.transaction_amount < 10000 THEN "Regular International"
        WHEN S.country_id = R.country_id AND T.transaction_amount < 10000 THEN "Regular Domestic"
	END AS transaction_category, COUNT(*) AS no_of_transactions
FROM transactions T
JOIN users S ON S.user_id = T.sender_id
JOIN users R ON R.user_id = T.recipient_id
WHERE YEAR(transaction_date) = 2023
GROUP BY transaction_category;

/*The finance department requires a comprehensive monthly report for the year 2023 that segments transactions by type and nature. Specifically,
the report should classify transactions into 'High Value' (above $10,000) and 'Regular' (below $10,000),
and further differentiate them as either 'International' (sender and recipient from different countries) or 'Domestic' (sender and recipient from the same country).
Your task is to write a query that groups transactions by year, month, value_category, location_category, and then calculates both the total transaction amount
and the average transaction amount for each group*/
SELECT EXTRACT(YEAR FROM T.transaction_date) AS transaction_year, EXTRACT(MONTH FROM T.transaction_date) AS transaction_month,
CASE
	WHEN T.transaction_amount > 10000 THEN "High Value"
    WHEN T.transaction_amount < 10000 THEN "Regular"
END AS value_category,
CASE
	WHEN S.country_id = R.country_id THEN "Domestic"
    ELSE "International"
END AS location_category, SUM(T.transaction_amount) AS total_amount, AVG(T.transaction_amount) AS average_amount
FROM Transactions T
JOIN users S ON S.user_id = T.sender_id
JOIN users R ON R.user_id = T.recipient_id
WHERE YEAR(T.transaction_date) = 2023
GROUP BY transaction_year,transaction_month,value_category,location_category
ORDER BY transaction_year,transaction_month,value_category,location_category;

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/* The sales team wants to evaluate the performance of merchants by creating a score based on their transaction amounts. The score is calculated as follows:
If total transactions exceed $50,000, the score is 'Excellent'
If total transactions are greater than $20,000 and lesser than or equal to $50,000, the score is 'Good'
If total transactions are greater than $10,000 and lesser than or equal to $20,000, the score is 'Average'
If total transactions are lesser than or equal to $10,000, the score is 'Below Average'
Write a query to assign a performance score to each merchant and calculate the average transaction amount for each performance category
for the period from November 2023 to April 2024.*/
WITH Temp AS(
SELECT M.merchant_id, M.business_name, SUM(T.transaction_amount) AS total_received, AVG(T.transaction_amount) AS average_transaction
FROM transactions T
JOIN merchants M ON M.merchant_id = T.recipient_id
WHERE T.transaction_date BETWEEN '2023-11-01' AND '2024-05-01'
GROUP BY M.merchant_id, M.business_name
)
SELECT merchant_id, business_name, total_received, 
CASE
		WHEN total_received > 50000 THEN "Excellent"
        WHEN total_received BETWEEN 20000 AND 50000 THEN "Good"
        WHEN total_received BETWEEN 10000 AND 200000 THEN "Average"
        WHEN total_received <= 10000 THEN "Below Average"
	END AS performance_score, average_transaction
FROM Temp
ORDER BY total_received DESC;

/* Write a query to list user IDs and their email addresses for users who have made at least one transaction
in at least 6 out of 12 months from May 2023 to April 2024.*/
WITH monthly_activity AS (
    SELECT 
        t.sender_id,
        DATE_FORMAT(t.transaction_date, '%Y-%m') AS txn_month
    FROM Transactions t
    WHERE t.transaction_date BETWEEN '2023-05-01' AND '2024-04-30'
    GROUP BY t.sender_id, DATE_FORMAT(t.transaction_date, '%Y-%m')
),
user_months AS (
    SELECT 
        sender_id,
        COUNT(DISTINCT txn_month) AS active_months
    FROM monthly_activity
    GROUP BY sender_id
    HAVING COUNT(DISTINCT txn_month) >= 6
)
SELECT 
    u.user_id,
    u.email
FROM user_months um
JOIN Users u 
    ON um.sender_id = u.user_id
ORDER BY u.user_id;

/*Write a query that calculates the total transaction amount for each merchant by month, and then create a column to indicate
 whether the merchant exceeded $50,000 in that month.The transaction date range should be considered from 1st Nov 2023 to 1st May 2024.
 The new column should contain the values 'Exceeded $50,000' or 'Did Not Exceed $50,000'.Display the merchant ID, business name,
 transaction year, transaction month, total transaction amount, and the new column indicating performance status.*/
 SELECT merchant_id,business_name, transaction_year, transaction_month, total_transaction_amount,
	CASE
		WHEN total_transaction_amount > 50000 THEN "Exceeded $50,000"
        ELSE "Did Not Exceed $50,000"
	END AS performance_status
FROM(
 SELECT M.merchant_id, M.business_name, EXTRACT(YEAR FROM T.transaction_date) AS transaction_year, EXTRACT(MONTH FROM transaction_date) AS transaction_month,
 SUM(T.transaction_amount) AS total_transaction_amount
 FROM transactions T
 JOIN merchants M ON M.merchant_id = T.recipient_id
 WHERE T.transaction_date BETWEEN '2023-11-01' AND '2024-05-01'
 GROUP BY M.merchant_id, M.business_name, transaction_year, transaction_month
 ) AS A
 ORDER BY merchant_id,transaction_year, transaction_month