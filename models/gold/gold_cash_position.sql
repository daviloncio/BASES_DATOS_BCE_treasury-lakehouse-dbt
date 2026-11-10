-- Gold: current cash position per bank account, in local currency and in EUR.
with movements as (

    select
        account_id,
        sum(amount)       as total_movements,
        max(value_date)   as last_movement_date
    from {{ ref('slv_cash_transactions') }}
    group by account_id

),

latest_fx as (

    select currency, rate_date, rate_per_eur
    from {{ ref('slv_fx_rates') }}
    qualify row_number() over (partition by currency order by rate_date desc) = 1

)

select
    a.account_id,
    a.entity_name,
    a.bank_name,
    a.currency,
    a.opening_balance,
    coalesce(m.total_movements, 0)                          as total_movements,
    a.opening_balance + coalesce(m.total_movements, 0)      as closing_balance,
    m.last_movement_date                                    as as_of_date,
    case when a.currency = 'EUR' then 1 else fx.rate_per_eur end as rate_per_eur,
    round(
        case
            when a.currency = 'EUR' then a.opening_balance + coalesce(m.total_movements, 0)
            else (a.opening_balance + coalesce(m.total_movements, 0)) / fx.rate_per_eur
        end,
        2
    )                                                       as closing_balance_eur
from {{ ref('slv_bank_accounts') }} as a
left join movements as m
    on a.account_id = m.account_id
left join latest_fx as fx
    on a.currency = fx.currency
