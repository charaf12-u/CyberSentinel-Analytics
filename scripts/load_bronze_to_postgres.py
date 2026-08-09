from __future__ import annotations
import sys
from collections import Counter
from pathlib import Path
from typing import Any
PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))
from ingestion.postgres_loader import load_bronze_files  # noqa: E402


# --> DISPLAY CONFIGURATION
STATUS_DISPLAY_ORDER = (
    "SUCCESS",
    "PARTIAL_SUCCESS",
    "EMPTY",
    "SKIPPED",
    "FAILED",
)
SUCCESSFUL_STATUSES = {
    "SUCCESS",
    "PARTIAL_SUCCESS",
    "EMPTY",
    "SKIPPED",
}

# --> pour évites erreur type int()
def safe_integer(value: Any) -> int:
    
    if value is None:
        return 0

    try:
        return int(value)
    except (TypeError, ValueError):
        return 0

# --> pour obtenir le chemin du fichier source à partir du résultat
def get_result_path(result: dict[str, Any]) -> str:

    return str(
        result.get("source_path")
        or result.get("object_name")
        or result.get("source_file")
        or result.get("file_name")
        or "unknown_source"
    )

# --> pour afficher le résultat d'un fichier 
def display_result(result: dict[str, Any]) -> None:
    
    status = str(result.get("status", "UNKNOWN")).upper()
    source_path = get_result_path(result)
    rows_loaded = safe_integer(
        result.get("rows_loaded", result.get("rows", 0))
    )
    table_name = result.get("table_name")
    if table_name:
        destination = f"bronze.{table_name}"
    else:
        destination = "-"

    print(
        f"[{status:<15}] "
        f"{source_path} "
        f"-> {destination} "
        f"({rows_loaded:,} lignes)"
    )

    if status == "SKIPPED":
        reason = result.get("reason")
        if reason:
            print(f"    Raison : {reason}")

    if status == "PARTIAL_SUCCESS":
        warning = (
            result.get("warning")
            or result.get("message")
            or result.get("reason")
        )
        if warning:
            print(f"    Warning: {warning}")

    if status == "FAILED":
        error = (
            result.get("error")
            or result.get("error_message")
            or "Erreur inconnue"
        )
        print(f"    Erreur : {error}")

# --> pour afficher le résumé global du chargement Bronze(ex: SUCCESS= 8, FAILED= 1, EMPTY= 2
def display_summary(results: list[dict[str, Any]]) -> None:

    statuses = Counter(
        str(result.get("status", "UNKNOWN")).upper()
        for result in results
    )
    total_rows_loaded = sum(
        safe_integer(
            result.get(
                "rows_loaded",
                result.get("rows", 0),
            )
        )
        for result in results
        if str(result.get("status", "")).upper()
        in {"SUCCESS", "PARTIAL_SUCCESS"}
    )

    print("\n" + "=" * 70)
    print("RÉSUMÉ DU CHARGEMENT")
    print("=" * 70)
    print(f"Fichiers traités : {len(results):,}")
    print(f"Lignes chargées  : {total_rows_loaded:,}")
    print("-" * 70)

    for status in STATUS_DISPLAY_ORDER:
        print(
            f"{status:<16}: "
            f"{statuses.get(status, 0):,}"
        )

    unknown_count = sum(
        count
        for status, count in statuses.items()
        if status not in STATUS_DISPLAY_ORDER
    )

    if unknown_count:
        print(f"{'UNKNOWN':<16}: {unknown_count:,}")

# --> pour afficher les erreurs détectées lors du chargement Bronze
def display_failures(
    results: list[dict[str, Any]],
) -> None:
    
    failed_results = [
        result
        for result in results
        if str(result.get("status", "")).upper() == "FAILED"
    ]

    if not failed_results:
        return

    print("\n" + "=" * 70)
    print("ERREURS DÉTECTÉES")
    print("=" * 70)

    for result in failed_results:
        source_path = get_result_path(result)

        error = (
            result.get("error")
            or result.get("error_message")
            or "Erreur inconnue"
        )

        print(f"- {source_path}")
        print(f"  {error}")

# --> MAIN FUNCTION
def main() -> int:
    
    print("=" * 70)
    print("CYBERSENTINEL ANALYTICS")
    print("LOCAL COLLECTOR FILES -> POSTGRESQL BRONZE")
    print("=" * 70)

    print(f"Projet : {PROJECT_ROOT}")

    # --> Load Bronze files
    try:
        results = load_bronze_files()
    # -->pour user ctrl+c
    except KeyboardInterrupt:
        print("\nChargement interrompu par l'utilisateur.")
        return 130
    # --> pour toutes autres erreurs
    except Exception as error:
        print("\nÉchec global du chargement Bronze.")
        print(f"Erreur: {error}")
        return 1

    # --> Check results load_bronze_files()
    if results is None:
        print(
            "\nLe loader n'a retourné aucun résultat."
        )
        return 1
    # --> check type results != list
    if not isinstance(results, list):
        print(
            "\nFormat invalide retourné par "
            "load_bronze_files()."
        )
        return 1
    # --> check results empty
    if not results:
        print(
            "\nAucun fichier compatible trouvé "
            "dans les dossiers configurés."
        )
        return 2

    print("\nRésultats par fichier:")
    print("-" * 70)
    # --> Display results for each file
    for result in results:
        if not isinstance(result, dict):
            print(
                "[UNKNOWN        ] Résultat invalide "
                "retourné par le loader."
            )
            continue

        display_result(result)

    # --> Display summary and failures
    display_summary(results)
    display_failures(results)

    # --> 
    failed_count = sum(
        1
        for result in results
        if isinstance(result, dict)
        and str(result.get("status", "")).upper()
        == "FAILED"
    )

    if failed_count:
        print(
            "\nChargement terminé avec "
            f"{failed_count} échec(s)."
        )
        return 1

    partial_count = sum(
        1
        for result in results
        if isinstance(result, dict)
        and str(result.get("status", "")).upper()
        == "PARTIAL_SUCCESS"
    )

    if partial_count:
        print(
            "\nChargement terminé avec succès, "
            f"mais {partial_count} fichier(s) ont un statut "
            "PARTIAL_SUCCESS."
        )
    else:
        print(
            "\nChargement Bronze terminé avec succès."
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())