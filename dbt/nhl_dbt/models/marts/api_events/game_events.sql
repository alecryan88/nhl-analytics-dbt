{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key = 'play_id'
    )
}}

Select 
        partition_date,
        {{ dbt_utils.generate_surrogate_key(['JSON_EXTRACT:gameData:game:pk::string', 'plays.value:about:eventId::int', 'plays.value:about.ordinalNum::string '])}} as play_id,
        JSON_EXTRACT:gameData:game:pk::string as game_id,
        plays.value:about:dateTime::timestamp as event_timestamp,
        plays.value:about:eventId::int as event_id,
        plays.value:team.id:: int as event_team_id,
        plays.value:coordinates.x::int as x_coor,
        plays.value:coordinates.y::int as y_coor,
        plays.value:result.description::string as description,
        plays.value:result.event::string as event,
        plays.value:result.eventCode::string as event_code,
        plays.value:result.eventTypeId::string as event_type_id,
        plays.value:about.period::int as period,
        plays.value:about.periodType::string as period_type,
        plays.value:about.ordinalNum::string as period_s,
        '{{ run_started_at }}' as last_updated_dbt

from {{ref('stg_api_game_events')}}, table(flatten(JSON_EXTRACT:liveData.plays.allPlays)) plays

 {% if is_incremental() %}

-- this filter will only be applied on an incremental run
where game_id > (select max(game_id) from {{ this }})

{% endif %}