-- Silver: clean, deduplicated cash transactions, converted to EUR.
with typed as (

    select
        trim(transaction_id)              as transaction_id,
        trim(account_id)                  as account_id,
        cast(value_date as date)          as value_date,
        upper(trim(currency))             as currency,   -- fixes ' usd ' -> 'USD'
        cast(amount as decimal(18, 2))    as amount,
        trim(category)                    as category
    from {{ ref('brz_cash_transactions') }}

),

deduplicated as (

    select *
    from typed
    -- the source system sometimes loads the same transaction twice
    qualify row_number() over (partition by transaction_id order by value_date) = 1

)

select
    t.transaction_id,
    t.account_id,
    a.entity_name,
    t.value_date,
    t.currency,
    t.amount,
    case when t.amount >= 0 then 'inflow' else 'outflow' end   as flow_direction,
    t.category,
    case when t.currency = 'EUR' then 1 else fx.rate_per_eur end as rate_per_eur,
    round(
        case when t.currency = 'EUR' then t.amount else t.amount / fx.rate_per_eur end,
        2
    )                                                           as amount_eur
from deduplicated as t
left join {{ ref('slv_bank_accounts') }} as a
    on t.account_id = a.account_id
left join {{ ref('slv_fx_rates') }} as fx
    on t.value_date = fx.rate_date
   and t.currency = fx.currency
