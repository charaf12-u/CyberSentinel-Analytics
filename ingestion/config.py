from __future__ import annotations
import os
from dataclasses import dataclass
from pathlib import Path
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]
# Charge le fichier .env situé à la racine du projet.
load_dotenv(PROJECT_ROOT / ".env")


# --> pour obtenir une variable d'environnement obligatoire
def get_required_env(name: str) -> str:
    
    value = os.getenv(name)
    if value is None or not value.strip():
        raise RuntimeError(
            f"Variable d'environnement obligatoire absente: {name}"
        )
    return value.strip()

# --> obtenir les variables int => .env
def get_env_int( name: str, default: int, *, minimum: int | None = None ) -> int:
    
    raw_value = os.getenv(name)

    if raw_value is None or not raw_value.strip():
        value = default
    else:
        try:
            value = int(raw_value.strip())
        except ValueError as error:
            raise RuntimeError(
                f"La variable {name} doit être un entier."
            ) from error

    if minimum is not None and value < minimum:
        raise RuntimeError(
            f"La variable {name} doit être supérieure "
            f"ou égale à {minimum}."
        )

    return value

# --> obtenir les variables bool => .env
def get_env_bool( name: str, default: bool = False ) -> bool:
    
    raw_value = os.getenv(name)
    if raw_value is None:
        return default
    normalized = raw_value.strip().lower()

    true_values = {
        "1",
        "true",
        "yes",
        "on",
    }

    false_values = {
        "0",
        "false",
        "no",
        "off",
    }

    if normalized in true_values:
        return True
    if normalized in false_values:
        return False

    raise RuntimeError(
        f"La variable {name} doit contenir une valeur booléenne."
    )

# --> pour obtenir le chemin du fichier source à partir du résultat
def resolve_project_path( environment_name: str, default_relative_path: str ) -> Path:
    
    configured_value = os.getenv(
        environment_name,
        default_relative_path,
    )

    configured_path = Path(
        configured_value.strip()
    ).expanduser()

    if configured_path.is_absolute():
        return configured_path.resolve()

    return (
        PROJECT_ROOT
        / configured_path
    ).resolve()


# LOCAL DATA PATHS
# =========================================================
# data/raw/local/
# ├── pc1/logs/
# ├── pc2/logs/
# └── pc3/logs/
RAW_LOCAL_DIR = resolve_project_path(
    "RAW_LOCAL_DIR",
    "data/raw/local",
)

# --> EVTX publics convertis ou préparés localement.
RAW_EVTX_DIR = resolve_project_path(
    "RAW_EVTX_DIR",
    "data/raw/public_evtx",
)

# --> Fichiers rejetés pendant la validation ou le chargement.
QUARANTINE_DIR = resolve_project_path(
    "QUARANTINE_DIR",
    "data/quarantine",
)

# --> Rapports produits par le loader.
INGESTION_REPORT_DIR = resolve_project_path(
    "INGESTION_REPORT_DIR",
    "data/reports/ingestion",
)


# --> POSTGRESQL CONFIGURATION
# =========================================================

@dataclass(frozen=True)
class PostgresConfig:
    host: str
    port: int
    database: str
    user: str
    password: str

    bronze_schema: str
    silver_schema: str
    intermediate_schema: str
    warehouse_schema: str
    audit_schema: str

    connect_timeout_seconds: int

    @property
    def sqlalchemy_url(self) -> str:
        # --> Retourne une URL de connexion compatible SQLAlchemy.
        return (
            "postgresql+psycopg2://"
            f"{self.user}:"
            f"{self.password}@"
            f"{self.host}:"
            f"{self.port}/"
            f"{self.database}"
        )

    @property
    def psycopg_dsn(self) -> str:
        # --> Retourne une chaîne de connexion compatible psycopg.
        return (
            f"host={self.host} "
            f"port={self.port} "
            f"dbname={self.database} "
            f"user={self.user} "
            f"password={self.password} "
            f"connect_timeout={self.connect_timeout_seconds}"
        )


def load_postgres_config() -> PostgresConfig:
    """
    Charge et valide la configuration PostgreSQL.

    --> Dans Docker:
        POSTGRES_HOST=postgres

    --> Depuis Windows:
        POSTGRES_HOST=localhost
    """

    return PostgresConfig(
        host=get_required_env("POSTGRES_HOST"),

        port=get_env_int(
            "POSTGRES_PORT",
            5432,
            minimum=1,
        ),

        database=get_required_env("POSTGRES_DB"),
        user=get_required_env("POSTGRES_USER"),
        password=get_required_env("POSTGRES_PASSWORD"),

        bronze_schema=os.getenv(
            "POSTGRES_BRONZE_SCHEMA",
            "bronze",
        ).strip(),

        silver_schema=os.getenv(
            "POSTGRES_SILVER_SCHEMA",
            "silver",
        ).strip(),

        intermediate_schema=os.getenv(
            "POSTGRES_INTERMEDIATE_SCHEMA",
            "intermediate",
        ).strip(),

        warehouse_schema=os.getenv(
            "POSTGRES_WAREHOUSE_SCHEMA",
            "warehouse",
        ).strip(),

        audit_schema=os.getenv(
            "POSTGRES_AUDIT_SCHEMA",
            "audit",
        ).strip(),

        connect_timeout_seconds=get_env_int(
            "POSTGRES_CONNECT_TIMEOUT",
            15,
            minimum=1,
        ),
    )


# --> INGESTION CONFIGURATION
# =========================================================

@dataclass(frozen=True)
class IngestionConfig:
    raw_local_dir: Path
    raw_evtx_dir: Path
    quarantine_dir: Path
    report_dir: Path

    recursive_scan: bool
    csv_encoding: str
    csv_delimiter: str

    chunk_size: int
    batch_size: int

    skip_loaded_files: bool
    quarantine_failed_files: bool
    include_empty_files: bool

    accepted_extensions: tuple[str, ...]


def load_ingestion_config() -> IngestionConfig:
    # --> Retourne la configuration utilisée par postgres_loader.py.
    extensions_value = os.getenv(
        "INGESTION_ACCEPTED_EXTENSIONS",
        ".csv,.json",
    )

    accepted_extensions = tuple(
        extension.strip().lower()
        if extension.strip().startswith(".")
        else f".{extension.strip().lower()}"
        for extension in extensions_value.split(",")
        if extension.strip()
    )

    return IngestionConfig(
        raw_local_dir=RAW_LOCAL_DIR,
        raw_evtx_dir=RAW_EVTX_DIR,
        quarantine_dir=QUARANTINE_DIR,
        report_dir=INGESTION_REPORT_DIR,

        recursive_scan=get_env_bool(
            "INGESTION_RECURSIVE_SCAN",
            True,
        ),

        csv_encoding=os.getenv(
            "INGESTION_CSV_ENCODING",
            "utf-8-sig",
        ).strip(),

        csv_delimiter=os.getenv(
            "INGESTION_CSV_DELIMITER",
            ",",
        ),

        chunk_size=get_env_int(
            "INGESTION_CHUNK_SIZE",
            10_000,
            minimum=1,
        ),

        batch_size=get_env_int(
            "INGESTION_BATCH_SIZE",
            1_000,
            minimum=1,
        ),

        skip_loaded_files=get_env_bool(
            "INGESTION_SKIP_LOADED_FILES",
            True,
        ),

        quarantine_failed_files=get_env_bool(
            "INGESTION_QUARANTINE_FAILED_FILES",
            True,
        ),

        include_empty_files=get_env_bool(
            "INGESTION_INCLUDE_EMPTY_FILES",
            True,
        ),

        accepted_extensions=accepted_extensions,
    )


# =========================================================
# DIRECTORY INITIALIZATION
# =========================================================

def ensure_runtime_directories() -> None:
    """
    Crée uniquement les dossiers générés par le pipeline.

    Les dossiers sources ne sont pas créés automatiquement,
    afin de détecter clairement une mauvaise configuration.
    """

    QUARANTINE_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    INGESTION_REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )


def validate_source_directories() -> list[str]:
    """
    Vérifie les dossiers sources.

    Retourne une liste de warnings au lieu d'interrompre
    immédiatement le pipeline.
    """

    warnings: list[str] = []

    if not RAW_LOCAL_DIR.exists():
        warnings.append(
            f"Dossier local introuvable: {RAW_LOCAL_DIR}"
        )

    if not RAW_EVTX_DIR.exists():
        warnings.append(
            f"Dossier EVTX introuvable: {RAW_EVTX_DIR}"
        )

    return warnings