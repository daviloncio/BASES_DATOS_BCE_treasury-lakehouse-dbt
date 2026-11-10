-- Silver: typed FX rates, one row per date and currency.
with typed as (

    select
        cast(rate_date as date)                as rate_date,
        upper(trim(currency))                  as currency,
        cast(rate_per_eur as decimal(18, 6))   as rate_per_eur
    from {{ ref('brz_fx_rates') }}

)

select *
from typed
-- remove duplicated rows sent by the source
qualify row_number() over (partition by rate_date, currency order by rate_date) = 1
