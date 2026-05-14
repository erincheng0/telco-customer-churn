
CREATE EXTERNAL TABLE IF NOT EXISTS telco_churn_db.dim_billing_contract (
    customer_id         string,
    contract_type       string,
    paperless_billing   string,
    payment_method      string
)
STORED AS PARQUET
LOCATION 's3://telco-churn-project-dev-622247619837-us-west-1-an/curated/telco_churn/';
