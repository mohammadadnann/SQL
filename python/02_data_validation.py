from pathlib import Path

import pandas as pd


# Set the project and raw data paths
project_root = Path(__file__).resolve().parents[1]
data_path = project_root / "data" / "raw" / "online_retail_II.xlsx"


# Define the columns required for the analysis
required_columns = [
    "Invoice",
    "StockCode",
    "Description",
    "Quantity",
    "InvoiceDate",
    "Price",
    "Customer ID",
    "Country"
]


def load_data(file_path):
    # Load the Excel sheets
    sheets = pd.read_excel(file_path, sheet_name=None)

    # Combine both sheets
    df = pd.concat(sheets.values(), ignore_index=True)

    return df


def check_columns(df):
    # Find required columns that are missing
    missing_columns = [
        column
        for column in required_columns
        if column not in df.columns
    ]

    print("\nCOLUMN CHECK")
    print("=" * 50)

    if missing_columns:
        print("Missing required columns:")
        print(missing_columns)
    else:
        print("All required columns are present")


def check_missing_values(df):
    # Check the main fields needed for transaction analysis
    columns_to_check = [
        "Invoice",
        "StockCode",
        "Quantity",
        "InvoiceDate",
        "Price",
        "Country"
    ]

    print("\nMISSING VALUE CHECK")
    print("=" * 50)

    for column in columns_to_check:
        missing = df[column].isna().sum()
        print(f"{column}: {missing:,}")

    # Check fields where missing values can still occur
    print(f"Description: {df['Description'].isna().sum():,}")
    print(f"Customer ID: {df['Customer ID'].isna().sum():,}")


def check_duplicates(df):
    # Count exact duplicate rows
    duplicates = df.duplicated().sum()

    print("\nDUPLICATE CHECK")
    print("=" * 50)
    print(f"Exact duplicate rows: {duplicates:,}")


def check_transaction_values(df):
    # Identify customer cancellations
    cancelled = df["Invoice"].astype(str).str.startswith("C")

    # Identify unusual quantity and price records
    negative_quantity = df["Quantity"] < 0
    negative_price = df["Price"] < 0
    zero_price = df["Price"] == 0

    print("\nTRANSACTION VALUE CHECK")
    print("=" * 50)

    print(f"Cancelled rows: {cancelled.sum():,}")
    print(f"Negative quantity rows: {negative_quantity.sum():,}")
    print(f"Negative price rows: {negative_price.sum():,}")
    print(f"Zero price rows: {zero_price.sum():,}")


def check_negative_quantities(df):
    # Identify negative quantities and cancellations
    negative_quantity = df["Quantity"] < 0
    cancelled = df["Invoice"].astype(str).str.startswith("C")

    # Separate cancellations from other stock movements
    cancelled_negative = negative_quantity & cancelled
    other_negative = negative_quantity & ~cancelled

    print("\nNEGATIVE QUANTITY CHECK")
    print("=" * 50)

    print(
        f"Negative quantities linked to cancellations: "
        f"{cancelled_negative.sum():,}"
    )

    print(
        f"Other negative quantities: "
        f"{other_negative.sum():,}"
    )


def check_customer_ids(df):
    # Check how much data can support customer analysis
    missing_customer = df["Customer ID"].isna().sum()
    known_customer = df["Customer ID"].notna().sum()

    print("\nCUSTOMER ID CHECK")
    print("=" * 50)

    print(f"Rows without Customer ID: {missing_customer:,}")
    print(f"Rows with Customer ID: {known_customer:,}")


def check_dates(df):
    # Check that transaction dates are complete
    missing_dates = df["InvoiceDate"].isna().sum()

    print("\nDATE CHECK")
    print("=" * 50)

    print(f"Missing dates: {missing_dates:,}")
    print(f"Earliest date: {df['InvoiceDate'].min()}")
    print(f"Latest date: {df['InvoiceDate'].max()}")


def main():
    # Load the raw data before running validation
    df = load_data(data_path)

    print(f"Rows loaded: {len(df):,}")

    check_columns(df)
    check_missing_values(df)
    check_duplicates(df)
    check_transaction_values(df)
    check_negative_quantities(df)
    check_customer_ids(df)
    check_dates(df)


if __name__ == "__main__":
    main()