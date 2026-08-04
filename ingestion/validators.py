from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path


ALLOWED_EXTENSIONS = {
    ".csv",
    ".json",
    ".jsonl",
    ".evtx",
    ".log",
}


@dataclass(frozen=True)
class ValidationResult:
    is_valid: bool
    reason: str
    size_bytes: int
    row_count: int | None = None
    columns: list[str] | None = None


def validate_csv(file_path: Path) -> ValidationResult:
    size_bytes = file_path.stat().st_size

    try:
        with file_path.open(
            "r",
            encoding="utf-8-sig",
            errors="replace",
            newline="",
        ) as file:
            reader = csv.reader(file)

            try:
                header = next(reader)
            except StopIteration:
                return ValidationResult(
                    is_valid=False,
                    reason="CSV totalement vide",
                    size_bytes=size_bytes,
                    row_count=0,
                    columns=[],
                )

            columns = [
                column.strip()
                for column in header
            ]

            if not columns or not any(columns):
                return ValidationResult(
                    is_valid=False,
                    reason="CSV sans colonnes",
                    size_bytes=size_bytes,
                    row_count=0,
                    columns=[],
                )

            if len(columns) != len(set(columns)):
                return ValidationResult(
                    is_valid=False,
                    reason="CSV avec colonnes dupliquées",
                    size_bytes=size_bytes,
                    row_count=0,
                    columns=columns,
                )

            row_count = sum(1 for row in reader if any(cell.strip() for cell in row))

        return ValidationResult(
            is_valid=True,
            reason="EMPTY" if row_count == 0 else "VALID",
            size_bytes=size_bytes,
            row_count=row_count,
            columns=columns,
        )

    except (OSError, csv.Error) as error:
        return ValidationResult(
            is_valid=False,
            reason=f"Erreur lecture CSV: {error}",
            size_bytes=size_bytes,
        )


def validate_file(file_path: Path) -> ValidationResult:
    if not file_path.exists():
        return ValidationResult(
            is_valid=False,
            reason="Fichier introuvable",
            size_bytes=0,
        )

    if not file_path.is_file():
        return ValidationResult(
            is_valid=False,
            reason="Le chemin n'est pas un fichier",
            size_bytes=0,
        )

    size_bytes = file_path.stat().st_size

    if size_bytes == 0:
        return ValidationResult(
            is_valid=False,
            reason="Fichier de 0 octet",
            size_bytes=0,
        )

    extension = file_path.suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        return ValidationResult(
            is_valid=False,
            reason=f"Extension non autorisée: {extension}",
            size_bytes=size_bytes,
        )

    if extension == ".csv":
        return validate_csv(file_path)

    return ValidationResult(
        is_valid=True,
        reason="VALID",
        size_bytes=size_bytes,
    )