-- normalize_severity macro ( column_name )
{% macro normalize_severity(column_name) %}

case

    when lower(trim(cast({{ column_name }} as text)))
        in (
            'critical',
            'critique'
        )
    then 'Critical'

    when lower(trim(cast({{ column_name }} as text)))
        in (
            'error',
            'high',
            'grave'
        )
    then 'High'

    when lower(trim(cast({{ column_name }} as text)))
        in (
            'warning',
            'warn',
            'medium',
            'avertissement'
        )
    then 'Medium'

    when lower(trim(cast({{ column_name }} as text)))
        in (
            'information',
            'informational',
            'info',
            'low',
            'verbose',
            'success audit',
            'audit success'
        )
    then 'Low'

    when lower(trim(cast({{ column_name }} as text)))
        in (
            'failure audit',
            'audit failure'
        )
    then 'High'

    else 'Unknown'

end

{% endmacro %}