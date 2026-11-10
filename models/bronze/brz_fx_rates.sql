-- Bronze: raw data exactly as received, plus load metadata.
select
    *,
    current_timestamp as _loaded_at
from {{ ref('fx_rates') }}
