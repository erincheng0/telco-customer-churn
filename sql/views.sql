-- overall churn KPIs
SELECT COUNT(*) AS total_customers,
	SUM(
		CASE
			WHEN churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN churn_flag = 'No' THEN 1 ELSE 0
		END
	) AS retained_customers,
	SUM(
		CASE
			WHEN churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS overall_churn_rate
FROM telco_churn_db.fact_customer_churn;
-- churn rate by contract type - check syntax
SELECT d.contract_type,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
	JOIN telco_churn_db.dim_billing_contract AS d ON f.customer_id = d.customer_id
GROUP BY d.contract_type
ORDER BY churn_rate DESC;
-- churn rate by tenure band 
SELECT f.tenure_band,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
GROUP BY f.tenure_band
ORDER BY churn_rate DESC;
-- churn rate by monthly charge band
SELECT f.monthly_charge_band,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate,
	AVG(f.monthly_charges) AS avg_monthly_charges
FROM telco_churn_db.fact_customer_churn AS f
GROUP BY f.monthly_charge_band
ORDER BY churn_rate DESC;
-- churn by payment method -- check syntax
SELECT d.payment_method,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
	JOIN telco_churn_db.dim_billing_contract AS d ON f.customer_id = d.customer_id
GROUP BY d.payment_method
ORDER BY churn_rate DESC;
-- churn vs key service features
SELECT s.internet_service,
	s.streaming_tv,
	s.streaming_movies,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
	JOIN telco_churn_db.dim_customer_services AS s ON f.customer_id = s.customer_id
GROUP BY s.internet_service,
	s.streaming_tv,
	s.streaming_movies
ORDER BY churn_rate DESC;
-- demographic churn 
SELECT d.gender,
	d.senior_citizen,
	COUNT(*) AS customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) AS churned_customers,
	SUM(
		CASE
			WHEN f.churn_flag = 'Yes' THEN 1 ELSE 0
		END
	) * 1.0 / COUNT(*) AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
	JOIN telco_churn_db.dim_customer_demographics AS d ON f.customer_id = d.customer_id
GROUP BY d.gender,
	d.senior_citizen
ORDER BY churn_rate DESC;