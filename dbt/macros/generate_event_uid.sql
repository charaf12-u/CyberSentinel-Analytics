{% macro generate_event_uid(
    machine_id,
    category,
    event_record_id,
    event_timestamp
) %}
    md5(
        concat_ws(
            '|',
            coalesce(cast({{ machine_id }} as text), ''),
            coalesce(cast({{ category }} as text), ''),
            coalesce(cast({{ event_record_id }} as text), ''),
            coalesce(cast({{ event_timestamp }} as text), '')
        )
    )
{% endmacro %}