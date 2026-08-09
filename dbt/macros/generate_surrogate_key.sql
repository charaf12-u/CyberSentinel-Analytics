-- generate_surrogate_key macro ( columns )
{% macro generate_surrogate_key(columns) %}

    (
        ('x' || substr(
            md5(
                concat_ws(
                    '|',
                    {% for column in columns %}
                        coalesce(
                            cast({{ column }} as text),
                            ''
                        )
                        {% if not loop.last %}, {% endif %}
                    {% endfor %}
                )
            ),
            1,
            16
        ))::bit(64)::bigint
    )

{% endmacro %}