docker compose down
docker compose build --no-cache airflow-init airflow-webserver airflow-scheduler
docker compose up -d

docker exec -it cybersentinel-airflow-scheduler bash

which git
git --version
dbt debug --profiles-dir /opt/airflow/project/dbt --target dev

hostname -I
