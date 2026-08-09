from __future__ import annotations
import os
from datetime import datetime, timedelta
from pathlib import Path
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# --> project directory structure
PROJECT_DIR = "/opt/airflow/project"
DBT_DIR = f"{PROJECT_DIR}/dbt"
SQL_DIR = f"{PROJECT_DIR}/sql"
ML_DIR = f"{PROJECT_DIR}/cybersentinel_auth_ml"
# --> SQL files
SQL_FILES = (
    "02_create_schemas.sql",
    "03_create_raw_tables.sql",
    "04_create_bronze_indexes.sql",
    "05_create_ml_schema.sql",
    "06_create_ml_tables.sql",
)

# --> airflow environment variables
def build_pipeline_env() -> dict[str, str]:

    # --> build environment variables for airflow tasks
    return {
        **os.environ,
        "POSTGRES_HOST": os.getenv(
            "POSTGRES_HOST",
            "cybersentinel-postgres",
        ),
        "POSTGRES_PORT": os.getenv(
            "POSTGRES_PORT",
            "5432",
        ),
        "POSTGRES_USER": os.getenv(
            "POSTGRES_USER",
            "postgres",
        ),
        "POSTGRES_PASSWORD": os.getenv(
            "POSTGRES_PASSWORD",
            "CyberSentinel_DB_2026",
        ),
        "POSTGRES_DB": os.getenv(
            "POSTGRES_DB",
            "cybersentinel_dw",
        ),
        "DBT_TARGET": os.getenv(
            "DBT_TARGET",
            "dev",
        ),
        "DBT_PROFILES_DIR": DBT_DIR,
        "PYTHONPATH": PROJECT_DIR,
    }

# --> build airflow environment variables
PIPELINE_ENV = build_pipeline_env()

# --> airflow DAG definition
def check_pipeline_environment() -> None:

    # --> check required environment variables and paths
    required_variables = (
        "POSTGRES_HOST",
        "POSTGRES_PORT",
        "POSTGRES_DB",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
    )
    # --> check for missing environment variables
    missing_variables = [
        variable_name
        for variable_name in required_variables
        if not PIPELINE_ENV.get(variable_name)
    ]
    # --> raise error if any required environment variables are missing
    if missing_variables:
        raise RuntimeError(
            "Missing environment variables: "
            + ", ".join(missing_variables)
        )

    # --> check for required paths
    required_paths = (
        Path(PROJECT_DIR),
        Path(DBT_DIR),
        Path(DBT_DIR) / "dbt_project.yml",
        Path(DBT_DIR) / "profiles.yml",
        Path(PROJECT_DIR)
        / "scripts"
        / "load_bronze_to_postgres.py",
        Path(ML_DIR),
        Path(ML_DIR) / "__init__.py",
        Path(ML_DIR) / "main.py",
        Path(ML_DIR) / "pipeline.py",
        Path(ML_DIR) / "config.py",
        Path(ML_DIR) / "database.py",
        Path(ML_DIR) / "repository.py",
    )

    # --> check for missing required paths
    sql_paths = tuple(
        Path(SQL_DIR) / sql_file
        for sql_file in SQL_FILES
    )
    required_paths = required_paths + sql_paths
    missing_paths = [
        str(path)
        for path in required_paths
        if not path.exists()
    ]
    if missing_paths:
        raise RuntimeError(
            "Missing project files:\n- "
            + "\n- ".join(missing_paths)
        )
    
    # --> check PostgreSQL database connection
    database_url = URL.create(
        drivername="postgresql+psycopg2",
        username=PIPELINE_ENV["POSTGRES_USER"],
        password=PIPELINE_ENV["POSTGRES_PASSWORD"],
        host=PIPELINE_ENV["POSTGRES_HOST"],
        port=int(PIPELINE_ENV["POSTGRES_PORT"]),
        database=PIPELINE_ENV["POSTGRES_DB"],
    )

    # --> check PostgreSQL database connection
    engine = create_engine(
        database_url,
        pool_pre_ping=True,
        connect_args={
            "connect_timeout": 15,
        },
    )

    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    finally:
        engine.dispose()

# --> configuration for airflow DAG
default_args = {
    "owner": "cybersentinel",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}

# --> airflow DAG definition
with DAG(
    dag_id="cybersentinel_security_pipeline",
    description=(
        "CyberSentinel collectors to PostgreSQL Bronze, "
        "dbt transformations, authentication ML scoring "
        "and Power BI models"
    ),
    start_date=datetime(2026, 7, 1),
    schedule="0 2 * * *",
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=[
        "cybersentinel",
        "postgresql",
        "dbt",
        "machine-learning",
        "power-bi",
        "security",
    ],
) as dag:
    
    # --> check required environment variables and paths
    check_environment = PythonOperator(
        task_id="check_environment",
        python_callable=check_pipeline_environment,
    )

    # --> initialize PostgreSQL database schemas and tables
    initialize_database = BashOperator(
        task_id="initialize_database_schemas_and_tables",
        bash_command=f"""
        set -euo pipefail

        export PGPASSWORD="$POSTGRES_PASSWORD"

        for sql_file in \
          02_create_schemas.sql \
          03_create_raw_tables.sql \
          04_create_bronze_indexes.sql \
          05_create_ml_schema.sql \
          06_create_ml_tables.sql
        do
          echo "Executing $sql_file"

          psql \
            --host="$POSTGRES_HOST" \
            --port="$POSTGRES_PORT" \
            --username="$POSTGRES_USER" \
            --dbname="$POSTGRES_DB" \
            --set=ON_ERROR_STOP=1 \
            --file="{SQL_DIR}/$sql_file"
        done
        """,
        env=PIPELINE_ENV,
    )

    # --> load local files to PostgreSQL Bronze tables
    load_bronze = BashOperator(
        task_id="load_local_files_to_postgresql_bronze",
        bash_command=f"""
        set -euo pipefail

        cd "{PROJECT_DIR}"

        python scripts/load_bronze_to_postgres.py
        """,
        env=PIPELINE_ENV,
    )

    # --> run dbt debug to check dbt configuration
    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"""
        set -euo pipefail

        cd "{DBT_DIR}"

        dbt debug \
          --profiles-dir "{DBT_DIR}" \
          --target "$DBT_TARGET"
        """,
        env=PIPELINE_ENV,
    )

    # --> build staging models using dbt
    dbt_build_staging = BashOperator(
        task_id="dbt_build_staging",
        bash_command=f"""
        set -euo pipefail

        cd "{DBT_DIR}"

        dbt build \
          --select "path:models/staging" \
          --profiles-dir "{DBT_DIR}" \
          --target "$DBT_TARGET"
        """,
        env=PIPELINE_ENV,
    )

    # --> build intermediate models using dbt
    dbt_build_intermediate = BashOperator(
        task_id="dbt_build_intermediate",
        bash_command=f"""
        set -euo pipefail

        cd "{DBT_DIR}"

        dbt build \
          --select "path:models/intermediate" \
          --profiles-dir "{DBT_DIR}" \
          --target "$DBT_TARGET"
        """,
        env=PIPELINE_ENV,
    )

    # --> build marts using dbt
    dbt_build_marts = BashOperator(
        task_id="dbt_build_marts",
        bash_command=f"""
        set -euo pipefail

        cd "{DBT_DIR}"

        dbt build \
          --select "path:models/marts" \
          --exclude "path:models/marts/powerbi" \
          --profiles-dir "{DBT_DIR}" \
          --target "$DBT_TARGET"
        """,
        env=PIPELINE_ENV,
    )

    # --> run authentication anomaly detection ML model
    run_authentication_ml = BashOperator(
        task_id="run_authentication_ml",
        bash_command=f"""
        set -euo pipefail

        cd "{PROJECT_DIR}"

        echo "Starting authentication anomaly detection model"

        python -m cybersentinel_auth_ml.main

        echo "Authentication ML scoring completed"
        """,
        env=PIPELINE_ENV,
    )

    # --> build Power BI models using dbt
    dbt_build_powerbi_models = BashOperator(
        task_id="dbt_build_powerbi_models",
        bash_command=f"""
        set -euo pipefail

        cd "{DBT_DIR}"

        dbt build \
          --select "path:models/marts/powerbi" \
          --profiles-dir "{DBT_DIR}" \
          --target "$DBT_TARGET"
        """,
        env=PIPELINE_ENV,
    )
    
    # --> define task dependencies
    (
        check_environment
        >> initialize_database
        >> load_bronze
        >> dbt_debug
        >> dbt_build_staging
        >> dbt_build_intermediate
        >> dbt_build_marts
        >> run_authentication_ml
        >> dbt_build_powerbi_models
    )