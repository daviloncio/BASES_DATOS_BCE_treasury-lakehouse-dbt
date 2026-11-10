-- An FX rate of zero or below is always a data error.
select *
from {{ ref('slv_fx_rates') }}
where rate_per_eur <= 0
