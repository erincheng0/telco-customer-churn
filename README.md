# Telco Customer Churn Analytics Pipeline (AWS, Kestra, Athena, QuickSight)

## 1. Problem statement

Churn is the rate at which customers leave a subscription service, directly reducing recurring revenue and slowing growth. In a telecom business, churn:

- Reduces predictable monthly revenue because fewer customers are paying each month.
- Forces the company to spend more on marketing and sales just to “fill the hole” left by departing customers.
- Often signals deeper issues with pricing, service quality, billing, or customer support that can damage the brand and trigger more churn.

In this project, I analyze Telco Customer Churn to understand how churn rates vary by contract type, payment method, and customer tenure, and to identify high‑risk segments that marketing and customer success teams can target with retention campaigns.

---

## 2. Dataset description

This project uses the Telco Customer Churn dataset, which contains 7,043 customers of a subscription‑based telecom provider offering phone and internet services in California. Each row represents a single customer and their most recent status.

Link to data: https://www.kaggle.com/datasets/blastchar/telco-customer-churn/data

The dataset includes four main groups of features:

- **Customer demographics**: gender, senior citizen flag, marital status, and whether the customer has dependents.  
- **Services**: phone service, multiple lines, internet service type, device protection, streaming TV, streaming movies, and add‑on services such as online security, online backup, and tech support.  
- **Billing and contract details**: contract type, paperless billing, payment method, tenure, monthly charges, and total charges to date.  
- **Target variable (churn)**: a binary flag indicating whether the customer left the company in the most recent month or remained.  

In this project, I treat each record as a snapshot of the customer’s latest state and do not model multiple time points per customer.

---

## 3. Architecture and pipeline

This project uses a batch data pipeline on AWS, built around an S3‑based data lake with Amazon Athena as the query layer.

### Raw ingestion

- The original Telco Customer Churn CSV from Kaggle is uploaded to an S3 **raw** zone and stored exactly as received.  
- This provides an immutable source that can be reprocessed at any time.

### ETL orchestration with Kestra

- A scheduled workflow in Kestra orchestrates the end‑to‑end ETL process by triggering a Python script (`telco_churn_pipeline`) in the `erin.telco` namespace.  
- The script reads the raw CSV from a configured local path, applies data cleaning and type normalization, and derives features such as tenure bands and monthly charge bands needed for churn analysis and modeling.  
- It then builds a `fact_customer_churn` table and writes it as a single Parquet file to `/workspace/data/curated/fact_customer_churn.parquet` on the local filesystem.

### Publish curated data to S3

- A second Kestra task, `upload_fact_to_s3`, uploads this Parquet file to the S3 **curated** zone at:  
  `s3://telco-churn-project-dev/curated/telco_churn/fact_customer_churn.parquet`  
- This step makes the curated dataset available in the data lake and cleanly separates local processing from durable object storage.

### Analytics layer with Glue & Athena

- The curated dataset is registered in the AWS Glue Data Catalog as an external table that defines the schema and points to the curated S3 path.  
- Amazon Athena uses this metadata to run SQL queries directly over the Parquet data in S3, eliminating the need for a separate data warehouse engine.  

This architecture enables interactive analysis of churn rates, customer segments, and model features while keeping the stack simple, serverless, and cost‑efficient.

---

## 4. Data model (tables/views)

The project uses a star‑schema‑style data model centered on customer churn. All tables join on `customer_id`, making it easy to analyze churn across demographic segments, service bundles, and billing characteristics. Keeping separate dimensions makes it clearer which attributes belong together.

### Main tables

**`fact_customer_churn`**  
One row per customer with churn‑related measures and status.  
Includes:

- `customer_id`
- `tenure_months`
- `tenure_band`
- `monthly_charges`
- `monthly_charge_band`
- `total_charges`
- `churn_flag`
- `contract_type`
- `payment_method`

**`dim_customer_demographics`**  
Used to segment churn by demographic groups.  
Includes:

- `customer_id`
- `gender`
- `senior_citizen`
- `partner`
- `dependents`

**`dim_customer_services`**  
Describes the product mix and service bundle for each customer.  
Includes:

- `customer_id`
- `phone_service`
- `multiple_lines`
- `internet_service`
- `online_security`
- `online_backup`
- `device_protection`
- `tech_support`
- `streaming_tv`
- `streaming_movies`

**`dim_billing_contract`**  
Supports questions about churn by contract, payment method, and billing preferences.  
Includes:

- `customer_id`
- `contract_type`
- `paperless_billing`
- `payment_method`

---

## 5. Dashboard and key insights

The **Telco Churn Analysis** dashboard summarizes overall churn and highlights how churn varies across key customer segments. It includes:

- A headline tile with overall churn rate.  
- Bar charts for churn rate by contract type, payment method, and internet service.  
- Segment views combining internet service with streaming TV and streaming movies subscriptions.  
- Demographic views for churn by gender and senior citizen status.  

### Key insights

**Overall churn is substantial**

- The total churn rate is **26.58%**, indicating churn is a material business problem that deserves focused attention.

**Contract type is a major driver**

- Month‑to‑month customers churn at much higher rates than those on one‑ or two‑year contracts, suggesting that incentives to move customers onto longer‑term contracts could reduce churn.

**Payment method is strongly associated with churn risk**

- Customers paying by **electronic check** exhibit notably higher churn than those using automatic payments such as bank transfer or credit card, highlighting an opportunity to encourage lower‑churn payment methods.

**Internet service type and streaming behavior matter**

- Churn varies by internet service type, with fiber‑optic customers showing elevated churn 
