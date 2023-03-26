{{
    config(
        materialized='incremental',
        unique_key='game_id'
    )
}}

with base as (
    Select distinct
            partition_date,
            JSON_EXTRACT:gameData:game:pk::string as game_id,
            teams.value:conference.id::integer as conference_id,
            teams.value:conference.name::string as conference_name,
            teams.value:division.id::int as division_id,
            '{{ run_started_at }}' as last_updated_dbt
    
    from {{ref('stg_api_game_events')}}, table(flatten(JSON_EXTRACT:gameData:teams)) teams

    {% if is_incremental() %}

    -- this filter will only be applied on an incremental run
    where game_id > (select max(game_id) from {{ this }})

    {% endif %}
)

Select * 
from base 