from pathlib import Path

import pandas as pd


# Set the project and raw data paths
project_root = Path(__file__).resolve().parents[1]
data_path = project_root / "data" / "raw" / "online_retail_II.xlsx"


def load_data(file_path):
    # Load the Excel sheets
    sheets = pd.read_excel(file_path, sheet_name=None)

    # Combine both sheets
    df = pd.concat(sheets.values(), ignore_index=True)

    return df


def dataset_overview(df):
    # Check the size and structure of the raw data
    print("\nDATASET OVERVIEW")
    print("=" * 50)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {df.shape[1]}")

    print("\nColumns:")
    print(df.columns.tolist())

    print("\nData types:")
    print(df.dtypes)

    # Check the full period covered by the transactions
    print("\nDate range:")
    print(df["InvoiceDate"].min())
    print(df["InvoiceDate"].max())


def missing_values(df):
    # Count missing values and their percentage
    missing_count = df.isna().sum()
    missing_percent = (missing_count / len(df) * 100).round(2)

    summary = pd.DataFrame({
        "missing_count": missing_count,
        "missing_percent": missing_percent
    })

    print("\nMISSING VALUES")
    print("=" * 50)
    print(summary)


def duplicate_check(df):
    # Count rows that are completely duplicated
    duplicate_rows = df.duplicated().sum()

    print("\nDUPLICATES")
    print("=" * 50)
    print(f"Exact duplicate rows: {duplicate_rows:,}")


def transaction_checks(df):
    # Cancellation invoices start with C
    cancelled = df["Invoice"].astype(str).str.startswith("C")

    # Check unusual quantity and price values
    negative_quantity = df["Quantity"] < 0
    zero_quantity = df["Quantity"] == 0
    negative_price = df["Price"] < 0
    zero_price = df["Price"] == 0

    print("\nTRANSACTION CHECKS")
    print("=" * 50)

    print(f"Cancelled rows: {cancelled.sum():,}")
    print(f"Negative quantities: {negative_quantity.sum():,}")
    print(f"Zero quantities: {zero_quantity.sum():,}")
    print(f"Negative prices: {negative_price.sum():,}")
    print(f"Zero prices: {zero_price.sum():,}")

    # Check extreme values before deciding cleaning rules
    print("\nQuantity range:")
    print(f"Minimum: {df['Quantity'].min():,}")
    print(f"Maximum: {df['Quantity'].max():,}")

    print("\nPrice range:")
    print(f"Minimum: {df['Price'].min():,.2f}")
    print(f"Maximum: {df['Price'].max():,.2f}")


def business_summary(df):
    # Check the overall business coverage
    print("\nBUSINESS SUMMARY")
    print("=" * 50)

    print(f"Unique invoices: {df['Invoice'].nunique():,}")
    print(f"Unique products: {df['StockCode'].nunique():,}")
    print(f"Unique customers: {df['Customer ID'].nunique():,}")
    print(f"Countries: {df['Country'].nunique():,}")


def unusual_records(df):
    # Keep the main fields together when checking unusual records
    columns = [
        "Invoice",
        "StockCode",
        "Description",
        "Quantity",
        "InvoiceDate",
        "Price",
        "Customer ID",
        "Country"
    ]

    # Check negative prices to understand what they represent
    print("\nNEGATIVE PRICE RECORDS")
    print("=" * 50)
    print(
        df[df["Price"] < 0][columns]
        .to_string(index=False)
    )

    # Check the largest negative quantities
    print("\nLARGEST NEGATIVE QUANTITIES")
    print("=" * 50)
    print(
        df.nsmallest(10, "Quantity")[columns]
        .to_string(index=False)
    )

    # Compare with the largest positive quantities
    print("\nLARGEST POSITIVE QUANTITIES")
    print("=" * 50)
    print(
        df.nlargest(10, "Quantity")[columns]
        .to_string(index=False)
    )


def country_summary(df):
    # Check which countries contain most transactions
    country_counts = df["Country"].value_counts().head(15)

    print("\nTOP COUNTRIES")
    print("=" * 50)
    print(country_counts)


def numeric_summary(df):
    # Review the overall quantity and price distribution
    summary = df[["Quantity", "Price"]].describe().round(2)

    print("\nNUMERIC SUMMARY")
    print("=" * 50)
    print(summary)


def main():
    # Load the raw data once for all exploration checks
    df = load_data(data_path)

    dataset_overview(df)
    missing_values(df)
    duplicate_check(df)
    transaction_checks(df)
    business_summary(df)
    unusual_records(df)
    country_summary(df)
    numeric_summary(df)


if __name__ == "__main__":
    main()