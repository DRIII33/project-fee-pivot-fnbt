-- Project Fee-Pivot: Analytical SQL Suite

-- 1. Revenue Mix & Fee Reliance

SELECT
    EXTRACT(YEAR FROM transaction_date) AS audit_year,
    EXTRACT(MONTH FROM transaction_date) AS audit_month,
    FORMAT_TIMESTAMP('%B', transaction_date) AS month_name,
    ROUND(SUM(CASE WHEN transaction_type = 'Overdraft_Fee' THEN transaction_amount ELSE 0 END), 2) AS total_overdraft_rev,
    ROUND(SUM(CASE WHEN transaction_type = 'Maintenance_Fee' THEN transaction_amount ELSE 0 END), 2) AS total_maintenance_rev,
    COUNTIF(transaction_type = 'Overdraft_Fee') AS overdraft_incident_count,
    ROUND(SAFE_DIVIDE(
        SUM(CASE WHEN transaction_type IN ('Overdraft_Fee', 'Maintenance_Fee') THEN transaction_amount ELSE 0 END),
        SUM(transaction_amount)
    ) * 100, 2) AS service_charge_reliance_index
FROM
    `driiiportfolio.fnbt_ledger_operations.fact_ledger`
GROUP BY 1, 2, 3
ORDER BY 1, 2


-- 2. Branch & Segment Analysis

WITH customer_metrics AS (
    SELECT 
        a.branch_location,
        a.account_type,
        a.account_id,
        COUNTIF(l.transaction_type = 'Overdraft_Fee') AS individual_overdraft_count,
        SUM(CASE WHEN l.transaction_type = 'Overdraft_Fee' THEN l.transaction_amount ELSE 0 END) AS individual_fees_paid,
        SUM(CASE WHEN l.ledger_impact = 'CREDIT' THEN l.transaction_amount ELSE 0 END) AS total_inbound_deposits
    FROM 
        `driiiportfolio.fnbt_ledger_operations.dim_accounts` a
    INNER JOIN 
        `driiiportfolio.fnbt_ledger_operations.fact_ledger` l ON a.account_id = l.account_id
    GROUP BY 1, 2, 3
)
SELECT 
    branch_location,
    account_type,
    COUNT(DISTINCT account_id) AS total_active_accounts,
    SUM(individual_overdraft_count) AS aggregate_overdraft_events,
    ROUND(SUM(individual_fees_paid), 2) AS aggregate_fee_revenue,
    ROUND(AVG(total_inbound_deposits), 2) AS avg_liquidity_cushion,
    CASE 
        WHEN SUM(individual_overdraft_count) > 100 THEN 'CRITICAL RISK SEGMENT'
        WHEN SUM(individual_overdraft_count) BETWEEN 50 AND 100 THEN 'STABLE SEGMENT'
        ELSE 'LOW RELIANCE SEGMENT'
    END AS segment_classification
FROM 
    customer_metrics
GROUP BY 1, 2
ORDER BY aggregate_fee_revenue DESC


-- 3. Multi-Vendor Reconciliation

SELECT
    vendor_source_system,
    COUNT(*) AS total_records,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_volume,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_value
FROM
    `driiiportfolio.fnbt_ledger_operations.fact_ledger`
GROUP BY
    vendor_source_system
ORDER BY
    total_records DESC


-- 4. Dashboard Mart View

CREATE OR REPLACE VIEW `driiiportfolio.fnbt_ledger_operations.vw_fnbt_dashboard` AS
SELECT
    l.transaction_id,
    l.transaction_date,
    l.transaction_type,
    l.transaction_amount,
    l.ledger_impact,
    l.vendor_source_system,
    a.branch_location,
    a.account_type,
    a.current_balance,
    l.etl_processed_timestamp
FROM
    `driiiportfolio.fnbt_ledger_operations.fact_ledger` l
INNER JOIN
    `driiiportfolio.fnbt_ledger_operations.dim_accounts` a ON l.account_id = a.account_id
