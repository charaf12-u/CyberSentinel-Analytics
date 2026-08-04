{{ config(
    materialized='table',
    schema='warehouse'
) }}

with users as (

    select
        username,
        user_sid

    from {{ ref('stg_authentication') }}

    where username is not null
       or user_sid is not null


    union


    select
        username,
        cast(null as text) as user_sid

    from {{ ref('stg_antivirus') }}

    where username is not null

)

select
    {{ generate_surrogate_key([
        "coalesce(user_sid, '')",
        "coalesce(username, '')"
    ]) }} as user_key,

    user_sid,
    username,
    lower(username) as normalized_username,

    username like '%$' as is_service_account

from users