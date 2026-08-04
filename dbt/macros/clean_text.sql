
{% macro clean_text(column_name) %}
    lower(
        trim(
            cast({{ column_name }} as text)
        )
    )
{% endmacro %}