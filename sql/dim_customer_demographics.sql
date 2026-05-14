
CREATE EXTERNAL TABLE IF NOT EXISTS telco_churn_db.dim_customer_demographics (
    customer_id         string,
    gender              string,
    senior_citizen      int,
    partner             string,
    dependents          string
)
STORED AS PARQUET
LOCATION 's3://telco-churn-project-dev-622247619837-us-west-1-an/curated/telco_churn/';