#!/bin/bash
set -e

# Run this script from the extracted Nexlyra_Final_Deliverables folder.
PROJECT="/Users/machd/Desktop/Nexlyra Projects"
PBIX="/Users/machd/Documents/Nexlyra_STR_Fraud_Dashboard.pbix"
EXCEL="$PROJECT/Nexlyra_STR_Syndicate_Audit.xlsx"

echo "Checking recovered source files..."
test -f "$PBIX" || { echo "PBIX not found: $PBIX"; exit 1; }
test -f "$EXCEL" || { echo "Excel workbook not found: $EXCEL"; exit 1; }

mkdir -p PowerBI Excel
cp -p "$PBIX" "PowerBI/Nexlyra_STR_Fraud_Dashboard.pbix"
cp -p "$EXCEL" "Excel/Nexlyra_STR_Syndicate_Audit.xlsx"

# Remove transient files before packaging.
find . -name ".DS_Store" -delete
rm -rf .venv __pycache__

cd ..
rm -f Carol_STR_Fraud_Analytics.zip
zip -r -q Carol_STR_Fraud_Analytics.zip Nexlyra_Final_Deliverables

echo
echo "FINAL ZIP CREATED:"
echo "$(pwd)/Carol_STR_Fraud_Analytics.zip"
echo
echo "Included:"
echo "  - Word audit report"
echo "  - README"
echo "  - Python scripts"
echo "  - SQL script"
echo "  - Charts"
echo "  - Power BI PDF + PBIX"
echo "  - Excel workbook"
