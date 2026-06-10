/*
Data Preparation

1. Mask card numbers to protect sensitive information.
2. Convert transaction amounts from text format to numeric format for analysis.
*/

UPDATE
	cards_data
SET
	card_number =
    SUBSTR(card_number, 1, 4) ||
    '****' ||
    SUBSTR(card_number, -4);

UPDATE
	transactions_data
SET
	amount = CAST(REPLACE(amount, '$', '') AS REAL);

/*
High-Risk MCC Categories

4829 - Money Transfer
7995 - Betting, Lottery, Casinos
4722 - Travel Agencies
4511 - Airlines
5815 - Digital Goods (Media, Books, Apps)
*/
-- Top 10 clients by spending in high-risk MCC categories
SELECT
	client_id,
	COUNT(*) AS transaction_count,
	ROUND(SUM(amount), 2) AS total_amount,
	ROUND(AVG(amount), 2) AS avg_amount
FROM
	transactions_data
WHERE
	mcc IN (4829, 7995, 4722, 4511, 5815)
GROUP BY
	client_id
ORDER BY
	total_amount DESC
LIMIT 10;
-- Clients active across the largest number of high-risk MCC categories
SELECT
	client_id,
	COUNT(DISTINCT mcc) AS suspicious_mcc_count,
	COUNT(*) AS transaction_count,
	ROUND(SUM(amount), 2) AS total_amount
FROM
	transactions_data
WHERE
	mcc IN (4829, 7995, 4722, 4511, 5815)
GROUP BY
	client_id
ORDER BY
	suspicious_mcc_count DESC,
	total_amount DESC
LIMIT 10;
-- Clients associated with more than 5 payment cards

SELECT
	client_id,
	COUNT(DISTINCT card_number ) AS card_count
FROM
	cards_data
GROUP BY
	client_id
HAVING
	COUNT(DISTINCT card_number) > 5
ORDER BY
	card_count DESC;


-- Cards with activity across more than 10 states


SELECT
	c.card_number,
	td.card_id,
	COUNT(DISTINCT td.merchant_state) AS area_count,
	COUNT(*) AS transaction_count,
	ROUND(SUM(td.amount), 2) AS total_amount
FROM
	transactions_data td
JOIN cards_data c
    ON
	td.card_id = c.id
WHERE
	td.mcc IN (4829, 7995, 4722, 4511, 5815)
	AND td.merchant_state is not ''
GROUP BY
	td.card_id,
	c.card_number
HAVING
	COUNT(DISTINCT td.merchant_state) > 10
ORDER BY
	area_count DESC
LIMIT 10;

/* Analyze spending patterns in high-risk MCC categories by age group.
Display transaction volume, total spending, and largest transaction amount
for each age cohort. */

SELECT
	CASE
		WHEN u.current_age BETWEEN 18 AND 30 THEN '18-30'
		WHEN u.current_age BETWEEN 31 AND 45 THEN '31-45'
		WHEN u.current_age BETWEEN 46 AND 60 THEN '46-60'
		ELSE '60+'
	END AS age_group,
	COUNT(*) AS transaction_count,
	ROUND(SUM(t.amount), 2) AS total_amount,
	ROUND(MAX(amount), 2) AS max_transaction
FROM
	transactions_data t
JOIN users_data u
    ON
	t.client_id = u.id
WHERE
	t.mcc IN (4829, 7995, 4722, 4511, 5815)
GROUP BY
	age_group
ORDER BY
	total_amount DESC;

/* Identify top-spending clients by state.
For each state, rank clients based on total transaction value
and return the highest-spending client.*/
SELECT
	*
FROM
	(
	SELECT
		merchant_state,
		client_id,
		ROUND(SUM(amount), 2) AS total_amount,
		ROW_NUMBER() OVER (
            PARTITION BY merchant_state
	ORDER BY
		SUM(amount) DESC
        ) AS rn
	FROM
		transactions_data
	WHERE
		merchant_state is not ''
		AND mcc IN (4829, 7995, 4722, 4511, 5815)
	GROUP BY
		merchant_state,
		client_id
)
WHERE
	rn = 1
ORDER BY
	total_amount DESC
LIMIT 20;
