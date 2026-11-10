-- Silver: typed and standardised bank accounts.
select
    trim(account_id)                          as account_id,
    trim(entity_name)                         as entity_name,
    trim(bank_name)                           as bank_name,
    upper(trim(currency))                     as currency,
    cast(opening_balance as decimal(18, 2))   as opening_balance,
    cast(opening_date as date)                as opening_date
from {{ ref('brz_bank_accounts') }}
