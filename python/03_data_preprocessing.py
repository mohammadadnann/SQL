from pathlib import Path

import pandas as pd


# Set the input and output paths
project_root = Path(__file__).resolve().parents[1]
raw_path = project_root / "data" / "raw" / "online_retail_II.xlsx"
output_path = project_root / "data" / "processed" / "transactions_clean.csv"


def load_data(file_path):
    # Load the Excel sheets
    sheets = pd.read_excel(file_path, sheet_name=None)

    # Combine both sheets
    df = pd.concat(sheets.values(), ignore_index=True)

    return df


def clean_columns(df):
    # Rename columns so they are easier to use in SQL
    df = df.rename(columns={
        "Invoice": "invoice",
        "StockCode": "stock_code",
        "Description": "description",
        "Quantity": "quantity",
        "InvoiceDate": "invoice_date",
        "Price": "unit_price",
        "Customer ID": "customer_id",
        "Country": "country"
    })

    return df


def clean_text(df):
    # Remove extra spaces from text fields
    text_columns = [
        "invoice",
        "stock_code",
        "description",
        "country"
    ]

    for column in text_columns:
        df[column] = df[column].astype("string").str.strip()

    return df


def remove_duplicates(df):
    # Remove rows that are completely duplicated
    df = df.drop_duplicates().copy()

    return df


def add_transaction_type(df):
    # Identify customer cancellations from the invoice code
    cancelled = df["invoice"].str.startswith("C", na=False)

    # Identify records where quantity is negative
    negative_quantity = df["quantity"] < 0

    # Treat normal transactions as sales
    df["transaction_type"] = "Sale"

    # Keep cancellations separate from normal sales
    df.loc[cancelled, "transaction_type"] = "Cancellation"

    # Keep other negative quantities as stock adjustments
    df.loc[
        negative_quantity & ~cancelled,
        "transaction_type"
    ] = "Stock Adjustment"

    return df


def add_record_status(df):
    # Start with all records marked as valid
    df["record_status"] = "Valid"

    # Negative prices represent accounting adjustments
    df.loc[
        df["unit_price"] < 0,
        "record_status"
    ] = "Accounting Adjustment"

    # Keep zero price records but flag them for SQL analysis
    df.loc[
        df["unit_price"] == 0,
        "record_status"
    ] = "Zero Price"

    return df


def format_customer_id(df):
    # Remove decimal formatting while keeping missing customer IDs
    df["customer_id"] = df["customer_id"].astype("Int64")

    return df


def save_data(df, file_path):
    # Save the processed data for SQL loading
    df.to_csv(file_path, index=False)


def main():
    # Load the original transaction data
    df = load_data(raw_path)

    # Keep the original row count for comparison
    original_rows = len(df)

    # Apply the preprocessing steps
    df = clean_columns(df)
    df = clean_text(df)
    df = remove_duplicates(df)
    df = add_transaction_type(df)
    df = add_record_status(df)
    df = format_customer_id(df)

    # Save the final processed dataset
    save_data(df, output_path)

    print("\nPREPROCESSING COMPLETE")
    print("=" * 50)

    print(f"Original rows: {original_rows:,}")
    print(f"Clean rows: {len(df):,}")
    print(f"Duplicates removed: {original_rows - len(df):,}")

    # Check how records were classified
    print("\nTransaction types:")
    print(df["transaction_type"].value_counts())

    print("\nRecord status:")
    print(df["record_status"].value_counts())

    print(f"\nSaved to: {output_path}")


if __name__ == "__main__":
    main()