from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.engine import Engine, URL

from ingestion.config import (
    load_ingestion_config,
    load_postgres_config,
)
from ingestion.metadata import calculate_sha256
from ingestion.validators import validate_file


# =========================================================
# FILE → BRONZE TABLE
# =========================================================

FILE_TABLE_MAPPING = {
    "windows_system_logs.csv": "windows_system_logs",
    "windows_application_logs.csv": "windows_application_logs",
    "authentication_logs.csv": "authentication_logs",
    "antivirus_logs.csv": "antivirus_logs",
    "defender_threats.csv": "defender_threats",
    "firewall_logs.csv": "firewall_logs",
    "usb_devices.csv": "usb_devices",
    "usb_event_logs.csv": "usb_event_logs",
    "machine_inventory.csv": "machine_inventory",
    "network_inventory.csv": "network_inventory",
    "extraction_report.csv": "extraction_report",
    "data_quality_report.csv": "data_quality_report",
}


# Compatibilité avec d'anciennes versions du collector.
LEGACY_COLUMN_MAPPING = {
    "timestamp": "timestamp_utc",
    "timestamp_raw": "timestamp_utc",
    "extracted_at_utc_raw": "extracted_at_utc",
    "usb_vid": "vendor_id",
    "usb_pid": "product_id",
    "domain": "domain_name",
}


LOADER_COLUMNS = {
    "raw_id",
    "source_path",
    "source_sha256",
    "extra_data",
    "ingestion_timestamp",
}


def normalize_column_name(column: object) -> str:
    """
    Transforme un nom de colonne en snake_case compatible PostgreSQL.
    """

    name = str(column).strip().lower()
    name = re.sub(r"[^a-z0-9_]+", "_", name)
    name = re.sub(r"_+", "_", name)

    return name.strip("_")


def create_postgres_engine() -> Engine:
    config = load_postgres_config()

    url = URL.create(
        drivername="postgresql+psycopg2",
        username=config.user,
        password=config.password,
        host=config.host,
        port=config.port,
        database=config.database,
    )

    return create_engine(
        url,
        pool_pre_ping=True,
        connect_args={
            "connect_timeout": config.connect_timeout_seconds,
        },
    )


def get_bronze_table_columns(
    engine: Engine,
    table_name: str,
) -> set[str]:
    """
    Lit directement les colonnes physiques de PostgreSQL.

    Cela évite de maintenir une grande liste TABLE_COLUMNS
    dans le code Python.
    """

    inspector = inspect(engine)

    if not inspector.has_table(
        table_name,
        schema="bronze",
    ):
        raise RuntimeError(
            f"Table introuvable: bronze.{table_name}"
        )

    return {
        column["name"]
        for column in inspector.get_columns(
            table_name,
            schema="bronze",
        )
    }


def relative_source_path(
    file_path: Path,
    raw_local_dir: Path,
) -> str:
    return (
        file_path.resolve()
        .relative_to(raw_local_dir.resolve())
        .as_posix()
    )


def extract_source_machine(
    file_path: Path,
    raw_local_dir: Path,
) -> str | None:
    """
    Exemple:

    data/raw/local/pc1/logs/authentication_logs.csv
    → pc1
    """

    relative_parts = (
        file_path.resolve()
        .relative_to(raw_local_dir.resolve())
        .parts
    )

    return relative_parts[0] if relative_parts else None


def serialize_extra_value(value: Any) -> Any:
    """
    Convertit les types pandas/numpy en valeurs compatibles JSON.
    """

    if pd.isna(value):
        return None

    if hasattr(value, "item"):
        try:
            return value.item()
        except (ValueError, AttributeError):
            pass

    if isinstance(value, (datetime, pd.Timestamp)):
        return value.isoformat()

    return value


def normalize_dataframe(
    dataframe: pd.DataFrame,
    *,
    source_file: str,
    source_path: str,
    source_sha256: str,
    physical_columns: set[str],
) -> pd.DataFrame:
    """
    Prépare les données pour Bronze.

    Bronze garde les valeurs source sous forme principalement TEXT.
    Les casts, validations et déduplications seront faits par dbt Silver.
    """

    dataframe = dataframe.copy()

    dataframe.columns = [
        normalize_column_name(column)
        for column in dataframe.columns
    ]

    if not all(dataframe.columns):
        raise ValueError(
            "Une ou plusieurs colonnes ont un nom vide."
        )

    if dataframe.columns.duplicated().any():
        duplicates = sorted(
            set(
                dataframe.columns[
                    dataframe.columns.duplicated()
                ]
            )
        )

        raise ValueError(
            f"Colonnes dupliquées après normalisation: {duplicates}"
        )

    dataframe = dataframe.rename(
        columns={
            old_name: new_name
            for old_name, new_name
            in LEGACY_COLUMN_MAPPING.items()
            if old_name in dataframe.columns
            and new_name not in dataframe.columns
        }
    )

    if dataframe.columns.duplicated().any():
        duplicates = sorted(
            set(
                dataframe.columns[
                    dataframe.columns.duplicated()
                ]
            )
        )

        raise ValueError(
            f"Collision après renommage: {duplicates}"
        )

    # Représentations considérées comme NULL.
    dataframe = dataframe.replace(
        {
            "": None,
            "-": None,
            "'-": None,
            "NULL": None,
            "null": None,
            "None": None,
            "none": None,
        }
    )

    modelled_columns = physical_columns - LOADER_COLUMNS

    extra_columns = [
        column
        for column in dataframe.columns
        if column not in modelled_columns
    ]

    if extra_columns:
        dataframe["extra_data"] = dataframe[
            extra_columns
        ].apply(
            lambda row: {
                key: serialize_extra_value(value)
                for key, value in row.items()
                if pd.notna(value)
            },
            axis=1,
        )

        dataframe = dataframe.drop(
            columns=extra_columns
        )

    else:
        dataframe["extra_data"] = [
            {}
            for _ in range(len(dataframe))
        ]

    dataframe["source_file"] = source_file
    dataframe["source_path"] = source_path
    dataframe["source_sha256"] = source_sha256

    allowed_columns = physical_columns - {
        "raw_id",
        "ingestion_timestamp",
    }

    dataframe = dataframe[
        [
            column
            for column in dataframe.columns
            if column in allowed_columns
        ]
    ]

    return dataframe


def is_current_file_loaded(
    engine: Engine,
    *,
    source_path: str,
    source_sha256: str,
) -> bool:
    query = text(
        """
        SELECT EXISTS (
            SELECT 1
            FROM audit.file_loads
            WHERE source_path = :source_path
              AND source_sha256 = :source_sha256
              AND load_status IN (
                  'SUCCESS',
                  'PARTIAL_SUCCESS',
                  'EMPTY',
                  'SKIPPED'
              )
        )
        """
    )

    with engine.connect() as connection:
        return bool(
            connection.execute(
                query,
                {
                    "source_path": source_path,
                    "source_sha256": source_sha256,
                },
            ).scalar()
        )


def register_file_load(
    connection,
    *,
    collection_id: str | None,
    machine_id: str | None,
    source_path: str,
    source_file: str,
    source_machine: str | None,
    source_sha256: str,
    file_size_bytes: int,
    rows_discovered: int,
    rows_loaded: int,
    rows_rejected: int,
    load_status: str,
    started_at: datetime,
    error_message: str | None = None,
) -> None:
    query = text(
        """
        INSERT INTO audit.file_loads (
            collection_id,
            machine_id,
            source_path,
            source_file,
            source_machine,
            source_sha256,
            file_size_bytes,
            rows_discovered,
            rows_loaded,
            rows_rejected,
            load_status,
            error_message,
            started_at,
            loaded_at
        )
        VALUES (
            :collection_id,
            :machine_id,
            :source_path,
            :source_file,
            :source_machine,
            :source_sha256,
            :file_size_bytes,
            :rows_discovered,
            :rows_loaded,
            :rows_rejected,
            :load_status,
            :error_message,
            :started_at,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (
            source_path,
            source_sha256
        )
        DO UPDATE SET
            collection_id = EXCLUDED.collection_id,
            machine_id = EXCLUDED.machine_id,
            source_file = EXCLUDED.source_file,
            source_machine = EXCLUDED.source_machine,
            file_size_bytes = EXCLUDED.file_size_bytes,
            rows_discovered = EXCLUDED.rows_discovered,
            rows_loaded = EXCLUDED.rows_loaded,
            rows_rejected = EXCLUDED.rows_rejected,
            load_status = EXCLUDED.load_status,
            error_message = EXCLUDED.error_message,
            started_at = EXCLUDED.started_at,
            loaded_at = CURRENT_TIMESTAMP
        """
    )

    connection.execute(
        query,
        {
            "collection_id": collection_id,
            "machine_id": machine_id,
            "source_path": source_path,
            "source_file": source_file,
            "source_machine": source_machine,
            "source_sha256": source_sha256,
            "file_size_bytes": file_size_bytes,
            "rows_discovered": rows_discovered,
            "rows_loaded": rows_loaded,
            "rows_rejected": rows_rejected,
            "load_status": load_status,
            "error_message": error_message,
            "started_at": started_at,
        },
    )


def first_value(
    dataframe: pd.DataFrame,
    column_name: str,
) -> str | None:
    if column_name not in dataframe.columns:
        return None

    values = dataframe[column_name].dropna()

    if values.empty:
        return None

    return str(values.iloc[0])


def load_file(
    engine: Engine,
    file_path: Path,
    raw_local_dir: Path,
    chunksize: int,
) -> dict[str, object]:
    started_at = datetime.now(timezone.utc)

    source_path = relative_source_path(
        file_path,
        raw_local_dir,
    )

    source_file = file_path.name
    table_name = FILE_TABLE_MAPPING[source_file.lower()]
    source_machine = extract_source_machine(
        file_path,
        raw_local_dir,
    )

    validation = validate_file(file_path)
    source_sha256 = calculate_sha256(file_path)

    if not validation.is_valid:
        return {
            "source_path": source_path,
            "table_name": table_name,
            "rows": 0,
            "status": "FAILED",
            "error": validation.reason,
        }

    if is_current_file_loaded(
        engine,
        source_path=source_path,
        source_sha256=source_sha256,
    ):
        return {
            "source_path": source_path,
            "table_name": table_name,
            "rows": 0,
            "status": "SKIPPED",
            "reason": "Même fichier déjà chargé.",
        }

    try:
        dataframe = pd.read_csv(
            file_path,
            encoding="utf-8-sig",
            low_memory=False,
            keep_default_na=False,
            na_values=[
                "",
                "-",
                "'-",
                "NULL",
                "null",
                "None",
                "none",
            ],
        )

        rows_discovered = len(dataframe)

        physical_columns = get_bronze_table_columns(
            engine,
            table_name,
        )

        dataframe = normalize_dataframe(
            dataframe,
            source_file=source_file,
            source_path=source_path,
            source_sha256=source_sha256,
            physical_columns=physical_columns,
        )

        collection_id = first_value(
            dataframe,
            "collection_id",
        )

        machine_id = first_value(
            dataframe,
            "machine_id",
        )

        status = (
            "EMPTY"
            if dataframe.empty
            else "SUCCESS"
        )

        with engine.begin() as connection:
            if not dataframe.empty:
                dataframe.to_sql(
                    name=table_name,
                    con=connection,
                    schema="bronze",
                    if_exists="append",
                    index=False,
                    method="multi",
                    chunksize=chunksize,
                    dtype={
                        "extra_data": JSONB,
                    },
                )

            register_file_load(
                connection,
                collection_id=collection_id,
                machine_id=machine_id,
                source_path=source_path,
                source_file=source_file,
                source_machine=source_machine,
                source_sha256=source_sha256,
                file_size_bytes=file_path.stat().st_size,
                rows_discovered=rows_discovered,
                rows_loaded=len(dataframe),
                rows_rejected=0,
                load_status=status,
                started_at=started_at,
            )

        return {
            "source_path": source_path,
            "table_name": table_name,
            "rows": len(dataframe),
            "rows_loaded": len(dataframe),
            "status": status,
        }

    except Exception as error:
        with engine.begin() as connection:
            register_file_load(
                connection,
                collection_id=None,
                machine_id=None,
                source_path=source_path,
                source_file=source_file,
                source_machine=source_machine,
                source_sha256=source_sha256,
                file_size_bytes=file_path.stat().st_size,
                rows_discovered=0,
                rows_loaded=0,
                rows_rejected=0,
                load_status="FAILED",
                started_at=started_at,
                error_message=str(error),
            )

        return {
            "source_path": source_path,
            "table_name": table_name,
            "rows": 0,
            "rows_loaded": 0,
            "status": "FAILED",
            "error": str(error),
        }


def load_bronze_files() -> list[dict[str, object]]:
    ingestion_config = load_ingestion_config()
    raw_local_dir = ingestion_config.raw_local_dir

    if not raw_local_dir.exists():
        raise FileNotFoundError(
            f"Dossier Bronze local introuvable: {raw_local_dir}"
        )

    engine = create_postgres_engine()

    try:
        files = sorted(
            path
            for path in raw_local_dir.rglob("*.csv")
            if path.name.lower() in FILE_TABLE_MAPPING
        )

        results: list[dict[str, object]] = []

        for file_path in files:
            relative_path = relative_source_path(
                file_path,
                raw_local_dir,
            )

            print(f"Loading: {relative_path}")

            result = load_file(
                engine=engine,
                file_path=file_path,
                raw_local_dir=raw_local_dir,
                chunksize=ingestion_config.batch_size,
            )

            results.append(result)

            print(
                f"  -> {result['status']} "
                f"({result.get('rows', 0)} rows)"
            )

        return results

    finally:
        engine.dispose()