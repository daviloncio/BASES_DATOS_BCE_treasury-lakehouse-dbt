"""
Generate small, synthetic treasury datasets as dbt seeds.

- bank_accounts.csv     : company bank accounts (entity, bank, currency, opening balance)
- cash_transactions.csv : daily inflows/outflows per account
- fx_rates.csv          : daily FX reference rates, quoted as 1 EUR = X units of currency
                          (same convention as the ECB reference rates)

The raw files are deliberately a bit "dirty" (duplicate rows, lowercase or padded
currency codes, amounts stored as text) so the silver layer has real cleaning to do.

Usage:
    python scripts/generate_data.py
"""

import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

SEEDS_DIR = Path(__file__).resolve().parent.parent / "seeds"
START = date(2026, 1, 2)
END = date(2026, 3, 31)

ACCOUNTS = [
    # account_id, entity, bank, currency, opening_balance
    ("ACC-ES-001", "Alcora Holding SA", "Banco Santander", "EUR", 2_500_000),
    ("ACC-ES-002", "Alcora Holding SA", "BBVA", "EUR", 1_200_000),
    ("ACC-UK-001", "Alcora Trading UK Ltd", "Barclays", "GBP", 800_000),
    ("ACC-US-001", "Alcora Americas Inc", "JPMorgan Chase", "USD", 1_500_000),
    ("ACC-CH-001", "Alcora Holding SA", "UBS", "CHF", 400_000),
]

# Approximate starting levels for 1 EUR = X
FX_START = {"USD": 1.08, "GBP": 0.85, "CHF": 0.94}

CATEGORIES_IN = ["customer_receipt", "intercompany_in", "interest_income"]
CATEGORIES_OUT = ["supplier_payment", "payroll", "tax_payment", "intercompany_out", "loan_repayment"]


def business_days(start, end):
    d = start
    while d <= end:
        if d.weekday() < 5:
            yield d
        d += timedelta(days=1)


def write_csv(name, header, rows):
    SEEDS_DIR.mkdir(exist_ok=True)
    with open(SEEDS_DIR / name, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def main():
    days = list(business_days(START, END))

    # Bank accounts
    write_csv(
        "bank_accounts.csv",
        ["account_id", "entity_name", "bank_name", "currency", "opening_balance", "opening_date"],
        [(a, e, b, c, ob, START.isoformat()) for a, e, b, c, ob in ACCOUNTS],
    )

    # FX rates: a small random walk per currency, business days only
    fx_rows = []
    level = dict(FX_START)
    for d in days:
        for ccy in sorted(level):
            level[ccy] *= 1 + random.gauss(0, 0.003)
            fx_rows.append((d.isoformat(), ccy, f"{level[ccy]:.4f}"))
    # data-quality issue: one duplicated rate row
    fx_rows.append(fx_rows[10])
    write_csv("fx_rates.csv", ["rate_date", "currency", "rate_per_eur"], fx_rows)

    # Cash transactions
    tx_rows = []
    tx_id = 1
    for d in days:
        for account_id, _, _, ccy, opening in ACCOUNTS:
            for _ in range(random.randint(1, 3)):
                inflow = random.random() < 0.45
                category = random.choice(CATEGORIES_IN if inflow else CATEGORIES_OUT)
                amount = round(random.uniform(0.002, 0.03) * opening, 2)
                if not inflow:
                    amount = -amount
                currency_raw = ccy
                # data-quality issue: inconsistent currency formatting
                if random.random() < 0.05:
                    currency_raw = f" {ccy.lower()} "
                tx_rows.append(
                    (f"TX{tx_id:06d}", account_id, d.isoformat(), currency_raw, f"{amount:.2f}", category)
                )
                tx_id += 1
    # data-quality issue: a few rows loaded twice by the source system
    tx_rows.extend(random.sample(tx_rows, 5))
    write_csv(
        "cash_transactions.csv",
        ["transaction_id", "account_id", "value_date", "currency", "amount", "category"],
        tx_rows,
    )

    print(f"Wrote {len(ACCOUNTS)} accounts, {len(fx_rows)} FX rows, {len(tx_rows)} transactions to {SEEDS_DIR}")


if __name__ == "__main__":
    main()
