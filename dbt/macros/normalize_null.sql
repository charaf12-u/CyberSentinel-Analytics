-- normalize_null macro ( column_name )
{% macro normalize_null(column_name) %}
    nullif(
        nullif(
            nullif(
                trim(cast({{ column_name }} as text)),
                ''
            ),
            '-'
        ),
        '''-'
    )
{% endmacro %}