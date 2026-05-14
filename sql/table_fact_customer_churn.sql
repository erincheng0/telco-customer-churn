CREATE EXTERNAL TABLE IF NOT EXISTS telco_churn_db.fact_customer_churn (
    customer_id             string,
    tenure_months           int,
    tenure_band             string,
    monthly_charges         double,
    monthly_charges_band    string,
    total_charges           double,
    churn_flag              string,
    contract_type           int,
    payment_method          string
)
STORED AS PARQUET
LOCATION 's3://telco-churn-project-dev-622247619837-us-west-1-an/curated/telco_churn/';

SELECT
    f.churn_flag,
    COUNT(*) AS customers,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS churn_rate
FROM telco_churn_db.fact_customer_churn AS f
GROUP BY f.churn_flag;
