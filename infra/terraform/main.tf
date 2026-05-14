terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"  
}

# S3 bucket for telco churn data
resource "aws_s3_bucket" "telco_churn" {
  bucket = "telco-churn-project-dev"
}

# Glue / Athena database
resource "aws_glue_catalog_database" "telco_churn_db" {
  name = "telco_churn_db"
}

# Glue table for curated fact_customer_churn parquet files
resource "aws_glue_catalog_table" "fact_customer_churn" {
  name          = "fact_customer_churn"
  database_name = aws_glue_catalog_database.telco_churn_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
    "EXTERNAL"       = "TRUE"
  }

  storage_descriptor {
    location      = "s3://telco-churn-project-dev/curated/telco_churn/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    # Athena will still read the rest from Parquet schema
    columns {
      name = "customer_id"
      type = "string"
    }
    columns {
      name = "tenure_months"
      type = "int"
    }
    columns {
      name = "monthly_charges"
      type = "double"
    }
    columns {
      name = "total_charges"
      type = "double"
    }
    columns {
      name = "churn_flag"
      type = "string"
    }
  }
}