-- Gold: daily cash flows per entity and currency, ready for reporting.
select
    value_date,
    entity_name,
    currency,
    count(*)                                                as transaction_count,
    sum(case when amount > 0 then amount else 0 end)        as inflows,
    sum(case when amount < 0 then amount else 0 end)        as outflows,
    sum(amount)                                             as net_flow,
    sum(amount_eur)                                         as net_flow_eur
from {{ ref('slv_cash_transactions') }}
group by value_date, entity_name, currency
