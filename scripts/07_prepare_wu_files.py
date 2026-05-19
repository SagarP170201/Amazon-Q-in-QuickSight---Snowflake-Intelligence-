"""
XpressBees - Weighted Utilization Parquet Cleaner
=================================================
WU parquet files have:
- Junk column names (...1, ...2, etc.)
- Row 0 contains actual headers
- Repeated column names (Phy, Vol, Chg) that need positional renaming
- Some months have extra columns (ss, aa) or different naming (Route type vs route_type)

This script:
1. Reads each WU parquet file
2. Uses row 0 as column headers
3. Applies positional renaming for repeated Phy/Vol/Chg columns
4. Normalizes column names across months
5. Writes clean parquet files ready for Snowflake ingestion

Usage:
    python 07_prepare_wu_files.py /path/to/parquet/folder /path/to/output/folder

Output files will be named: Weighted_Utilization_<month>_clean.parquet
"""

import sys
import os
import pandas as pd

POSITIONAL_COLUMN_MAP = {
    0: "Start Date Day",
    1: "Start Date",
    2: "Close Date",
    3: "connectionid",
    4: "TripSheetNo",
    5: "stoppointorder",
    6: "Final connection name",
    7: "Lane",
    8: "route_type",
    9: "load_unloadcity",
    10: "vehiclename",
    11: "Phy Wt",
    12: "Phy wt Ecomm",
    13: "Phy wt Cargo",
    14: "Vol Wt",
    15: "Vol wt Ecomm",
    16: "Vol wt Cargo",
    17: "Chg Wt",
    18: "Chg wt Ecomm",
    19: "Chg wt Cargo",
    20: "Phy Cap",
    21: "Vol Cap",
    22: "Chg Cap",
    23: "Dist.",
    24: "LU_Phy",
    25: "LU_Vol",
    26: "LU_Chg",
    27: "WC_Phy",
    28: "WC_Vol",
    29: "WC_Chg",
    30: "WA_Phy",
    31: "WA_Vol",
    32: "WA_Chg",
    33: "WU_Phy",
    34: "WU_Vol",
    35: "WU_Chg",
    36: "Cost Leg wise",
    37: "LPK_Phy",
    38: "LPK_Vol",
    39: "LPK_Chg",
    40: "TC_Phy",
    41: "TC_Vol",
    42: "TC_Chg",
    43: "CD_Phy",
    44: "CD_Vol",
    45: "CD_Chg",
    46: "Trip Cost",
    47: "Dist Sum",
}

COLUMN_RENAMES = {
    "Route type": "route_type",
    "Vehicle hired type": "vehicle_hired",
}

DROP_COLUMNS = {"ss", "aa", "Start Date Day"}

OCT_EXTRA_COLS = {
    "Date", "Ecomm Comp Volm", "Cargo Comp Volm",
    "Leg wise cost on utlsn%", "Remaining Leg wise cost",
    "Ecomm Cost on utlsn", "Cargo Cost on utlsn",
    "Total Ecomm Cost", "Total Cargo Cost",
}

FINAL_COLUMNS = [
    "Start Date", "Close Date", "connectionid", "TripSheetNo", "stoppointorder",
    "Final connection name", "Lane", "route_type", "load_unloadcity", "vehiclename",
    "Phy Wt", "Phy wt Ecomm", "Phy wt Cargo", "Vol Wt", "Vol wt Ecomm", "Vol wt Cargo",
    "Chg Wt", "Chg wt Ecomm", "Chg wt Cargo", "Phy Cap", "Vol Cap", "Chg Cap", "Dist.",
    "LU_Phy", "LU_Vol", "LU_Chg", "WC_Phy", "WC_Vol", "WC_Chg",
    "WA_Phy", "WA_Vol", "WA_Chg", "WU_Phy", "WU_Vol", "WU_Chg",
    "Cost Leg wise", "LPK_Phy", "LPK_Vol", "LPK_Chg",
    "TC_Phy", "TC_Vol", "TC_Chg", "CD_Phy", "CD_Vol", "CD_Chg",
    "Trip Cost", "Dist Sum",
    "Phy wt Ecomm_IGN", "Phy wt Cargo_IGN", "Vol wt Ecomm_IGN", "Vol wt Cargo_IGN",
    "Phy Cap_IGN", "Vol Cap_IGN", "Chg Cap_IGN", "Phy Wt_IGN", "Vol Wt_IGN", "Chg Wt_IGN",
    "Vendor_Name", "Start", "Close", "Dedicated Route as per Mapping",
    "Cost_sharing", "New_trip_cost", "Vehicle_Volume", "vehicle_hired",
    "Cargo Cost", "Ecom Cost", "PK_at_90%", "Cargo Cost on billed weight",
    "Start date Month", "Start date Year", "Ecom ComP", "Cargo comp",
    "Ecom_vol_Cap", "Cargo_Vol_Cap", "TTL_Vol_Cap", "Min_Vol_Cap", "Max_Vol_Cap",
    "route mode",
]


def clean_wu_file(input_path, output_path):
    df = pd.read_parquet(input_path)
    headers = df.iloc[0].tolist()
    data = df.iloc[1:].copy()

    has_ss = headers[0] == "ss"
    offset = 2 if has_ss else 0

    new_columns = []
    for i in range(len(headers)):
        adjusted_pos = i - offset
        if adjusted_pos in POSITIONAL_COLUMN_MAP:
            new_columns.append(POSITIONAL_COLUMN_MAP[adjusted_pos])
        else:
            header_val = headers[i] if headers[i] else f"col_{i}"
            if header_val in COLUMN_RENAMES:
                header_val = COLUMN_RENAMES[header_val]
            new_columns.append(header_val)

    data.columns = new_columns

    cols_to_drop = [c for c in data.columns if c in DROP_COLUMNS or c in OCT_EXTRA_COLS]
    if cols_to_drop:
        data = data.drop(columns=cols_to_drop, errors='ignore')

    ign_cols_after_dist_sum = False
    renamed_cols = []
    ign_prefix_map = {
        "Phy wt Ecomm": "Phy wt Ecomm_IGN",
        "Phy wt Cargo": "Phy wt Cargo_IGN",
        "Vol wt Ecomm": "Vol wt Ecomm_IGN",
        "Vol wt Cargo": "Vol wt Cargo_IGN",
        "Phy Cap": "Phy Cap_IGN",
        "Vol Cap": "Vol Cap_IGN",
        "Chg Cap": "Chg Cap_IGN",
        "Phy Wt": "Phy Wt_IGN",
        "Vol Wt": "Vol Wt_IGN",
        "Chg Wt": "Chg Wt_IGN",
    }
    for col in data.columns:
        if col == "Dist Sum":
            ign_cols_after_dist_sum = True
            renamed_cols.append(col)
        elif ign_cols_after_dist_sum and col in ign_prefix_map:
            renamed_cols.append(ign_prefix_map[col])
            ign_cols_after_dist_sum = col != "Chg Wt"
        else:
            renamed_cols.append(col)
    data.columns = renamed_cols

    if "route mode" not in data.columns:
        data["route mode"] = None

    final_cols = [c for c in FINAL_COLUMNS if c in data.columns]
    data = data[final_cols]

    data.to_parquet(output_path, index=False)
    print(f"  Cleaned: {os.path.basename(input_path)} -> {os.path.basename(output_path)} ({len(data)} rows, {len(data.columns)} cols)")


def main():
    if len(sys.argv) < 3:
        print("Usage: python 07_prepare_wu_files.py <input_folder> <output_folder>")
        print("  input_folder: folder containing monthly subfolders with WU parquet files")
        print("  output_folder: where to write cleaned parquet files")
        sys.exit(1)

    input_folder = sys.argv[1]
    output_folder = sys.argv[2]
    os.makedirs(output_folder, exist_ok=True)

    month_map = {
        "october": "Oct", "november": "Nov", "december": "Dec",
        "january": "Jan", "february": "Feb", "march": "March",
        "april 2025": "April", "may 2025": "May", "june 2025": "June",
        "july 2025": "July", "august 2025": "Aug", "september": "Sept",
    }

    print("Cleaning Weighted Utilization parquet files...")
    for month_dir in sorted(os.listdir(input_folder)):
        month_path = os.path.join(input_folder, month_dir)
        if not os.path.isdir(month_path):
            continue
        for f in os.listdir(month_path):
            if ("eight" in f.lower() or "util" in f.lower()) and f.endswith(".parquet"):
                input_path = os.path.join(month_path, f)
                month_key = month_dir.lower()
                month_suffix = month_map.get(month_key, month_dir)
                output_name = f"Weighted_Utilization_{month_suffix}_clean.parquet"
                output_path = os.path.join(output_folder, output_name)
                clean_wu_file(input_path, output_path)

    print(f"\nDone! Clean files written to: {output_folder}")
    print("Upload these to @XPRESSBEES_PROFITABILITY.RAW.DATA_STAGE")


if __name__ == "__main__":
    main()
