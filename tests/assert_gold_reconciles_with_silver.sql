-- Reconciliation control: the total net flow in gold must match the
-- transaction detail in silver (to the cent). Any row returned is a failure.
with silver as (
    select sum(amount_eur) as total_eur
    from {{ ref('slv_cash_transactions') }}
),

gold as (
    select sum(net_flow_eur) as total_eur
    from {{ ref('gold_daily_cash_flows') }}
)

select
    silver.total_eur as silver_total_eur,
    gold.total_eur   as gold_total_eur
from silver
cross join gold
where abs(silver.total_eur - gold.total_eur) > 0.01
