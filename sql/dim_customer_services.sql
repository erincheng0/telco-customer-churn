
CREATE EXTERNAL TABLE IF NOT EXISTS telco_churn_db.dim_customer_services (
    customer_id         string,
    phone_service       string,
    multiple_lines      string,
    internet_service    string,
    online_security     string,
    online_backup       string,
    device_protection   string,
    tech_support        string,
    streaming_tv        string,
    streaming_movies    string
)
STORED AS PARQUET
LOCATION 's3://telco-churn-project-dev-622247619837-us-west-1-an/curated/telco_churn/';