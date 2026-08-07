# Data Dictionary: fnbt_ledger_operations

| Table/View | Field | Type | Description |
|---|---|---|---|
| fact_ledger | transaction_id | STRING | Unique ID for each banking transaction |
| fact_ledger | ledger_impact | STRING | DEBIT or CREDIT status |
| fact_ledger | transaction_amount | FLOAT | Currency value of the transaction |
| dim_accounts | branch_location | STRING | FNBT physical branch associated with account |
| vw_fnbt_dashboard | service_charge_reliance | FLOAT | Calculated ratio of fee revenue to total volume |
