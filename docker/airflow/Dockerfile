FROM apache/airflow:2.10.0-python3.12

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && chmod 755 /usr/bin/git

USER airflow

COPY docker/airflow/requirements.txt /requirements.txt

RUN pip install --no-cache-dir \
    "apache-airflow==2.10.0" \
    -r /requirements.txt \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.0/constraints-3.12.txt"