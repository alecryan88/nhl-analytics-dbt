{{
    config(
        materialized='incremental',
        unique_key='game_id'
    )
}}

with base as (

    Select
            split_part(split_part(file_name, '=', 2),'/',1)::date as PARTITION_DATE,
            split_part(split_part(FILE_NAME,'.',1), '/',2)::varchar as GAME_ID,
            FILE_NAME,
            JSON_EXTRACT,
            LOADED_AT

    from {{ source('NHL_API', 'NHL_API_GAME_EVENTS')}}

    
)

Select
        PARTITION_DATE,
        GAME_ID,
        FILE_NAME,
        JSON_EXTRACT,
        LOADED_AT

from base 

{% if is_incremental() %}

-- this filter will only be applied on an incremental run
where LOADED_AT > (select max(LOADED_AT) from {{ this }})

{% endif %}