import yaml
from pathlib import Path
import numpy as np
import pandas as pd
import boto3

# --------------------
# Config
# --------------------

CONFIG_PATH = Path("/workspace/src/config/config.yml")

with open(CONFIG_PATH) as f:
    cfg = yaml.safe_load(f)

RAW_PATH = Path(cfg["paths"]["raw_csv"])
CURATED_DIR = Path(cfg["paths"]["curated_dir"])
CURATED_FACT = CURATED_DIR / "fact_customer_churn.parquet"

S3_BUCKET = cfg["s3"]["bucket"]
S3_KEY = cfg["s3"]["key"]  # e.g. "curated/telco_churn/fact_customer_churn.parquet"


# --------------------
# Extract
# --------------------

def extract_raw(csv_path: Path) -> pd.DataFrame:
    if not csv_path.exists():
        raise FileNotFoundError(f"Raw CSV not found at {csv_path}")
    df = pd.read_csv(csv_path)
    return df


# --------------------
# Transform helpers
# --------------------

def clean_types(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # fix TotalCharges: spaces -> NaN -> numeric
    if "TotalCharges" in df.columns:
        df["TotalCharges"] = (
            df["TotalCharges"]
            .replace(" ", np.nan)
            .astype("float64")
        )

    # Ensure SeniorCitizen is treated as integer / categorical
    if "SeniorCitizen" in df.columns:
        df["SeniorCitizen"] = df["SeniorCitizen"].astype("int64")

    # Standardize yes/no style categoricals
    yes_no_cols = [
        "Partner",
        "Dependents",
        "PhoneService",
        "PaperlessBilling",
        "Churn",
    ]
    for col in yes_no_cols:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip()

    # drop rows with missing TotalCharges
    if "TotalCharges" in df.columns:
        df = df.dropna(subset=["TotalCharges"])

    # rename to snake_case
    RENAME_COLUMNS = {
        "customerID": "customer_id",
        "tenure": "tenure_months",
        "MonthlyCharges": "monthly_charges",
        "monthly_charge_band": "monthly_charge_band",
        "TotalCharges": "total_charges",
        "Churn": "churn_flag",
        "Contract": "contract_type",
        "PaymentMethod": "payment_method",

        "gender": "gender",
        "SeniorCitizen": "senior_citizen",
        "Partner": "partner",
        "Dependents": "dependents",

        "PhoneService": "phone_service",
        "MultipleLines": "multiple_lines",
        "InternetService": "internet_service",
        "OnlineSecurity": "online_security",
        "OnlineBackup": "online_backup",
        "DeviceProtection": "device_protection",
        "TechSupport": "tech_support",
        "StreamingTV": "streaming_tv",
        "StreamingMovies": "streaming_movies",

        "PaperlessBilling": "paperless_billing",
    }

    df = df.rename(columns=RENAME_COLUMNS)
    return df


def add_simple_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # tenure bands
    if "tenure_months" in df.columns:
        bins = [0, 12, 24, 60, np.inf]
        labels = ["0-12", "13-24", "25-60", "60+"]
        df["tenure_band"] = pd.cut(
            df["tenure_months"], bins=bins, labels=labels, right=True
        )

    # monthly charge bands
    if "monthly_charges" in df.columns:
        q = df["monthly_charges"].quantile([0.33, 0.66]).tolist()
        bins = [
            df["monthly_charges"].min() - 1,
            q[0],
            q[1],
            df["monthly_charges"].max() + 1,
        ]
        labels = ["low", "medium", "high"]
        df["monthly_charge_band"] = pd.cut(
            df["monthly_charges"], bins=bins, labels=labels
        )

    return df


# --------------------
# Star schema – fact only
# --------------------

def build_fact_customer_churn(df: pd.DataFrame) -> pd.DataFrame:
    cols = [
        "customer_id",
        "tenure_months",
        "tenure_band",
        "monthly_charges",
        "monthly_charge_band",
        "total_charges",
        "churn_flag",
        "contract_type",
        "payment_method",
    ]
    existing = [c for c in cols if c in df.columns]
    fact = df[existing].copy()
    return fact


# --------------------
# Load
# --------------------

def write_parquet(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(path, index=False)


def upload_to_s3(local_path: Path, bucket: str, key: str) -> None:
    s3 = boto3.client("s3")
    s3.upload_file(str(local_path), bucket, key)
    print(f"Uploaded {local_path} to s3://{bucket}/{key}")


# --------------------
# Main ETL
# --------------------

def run_etl():
    print(f"Reading raw data from {RAW_PATH}...")
    df_raw = extract_raw(RAW_PATH)

    print("Cleaning and typing data...")
    df_clean = clean_types(df_raw)
    df_features = add_simple_features(df_clean)

    print("Building fact table...")
    fact = build_fact_customer_churn(df_features)

    print(f"Writing curated fact table to {CURATED_FACT}...")
    write_parquet(fact, CURATED_FACT)

    print("Uploading fact table to S3...")
    upload_to_s3(CURATED_FACT, S3_BUCKET, S3_KEY)

    print("ETL completed successfully.")


if __name__ == "__main__":
    run_etl()