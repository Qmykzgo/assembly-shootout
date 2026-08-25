#!/usr/bin/env python3
"""Validate the assembly-shootout benchmark sample-sheet contract."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

REQUIRED_COLUMNS = {"sample", "reads1", "reads2", "long_reads"}


def clean(value: str | None) -> str:
    return (value or "").strip()


def validate(path: Path, check_paths: bool = False) -> list[str]:
    errors: list[str] = []
    try:
        with path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            fields = {clean(field) for field in (reader.fieldnames or [])}
            missing = REQUIRED_COLUMNS - fields
            if missing:
                return [f"missing required columns: {', '.join(sorted(missing))}"]
            seen: set[str] = set()
            for line_number, raw_row in enumerate(reader, start=2):
                row = {clean(key): clean(value) for key, value in raw_row.items() if key}
                sample = row.get("sample", "")
                if not sample:
                    errors.append(f"line {line_number}: sample is empty")
                elif sample in seen:
                    errors.append(f"line {line_number}: duplicate sample '{sample}'")
                else:
                    seen.add(sample)
                for field in ("reads1", "reads2", "long_reads"):
                    value = row.get(field, "")
                    if not value:
                        errors.append(f"line {line_number}: '{field}' is required for every strategy comparison")
                    elif check_paths and not Path(value).expanduser().exists():
                        errors.append(f"line {line_number}: {field} does not exist: {value}")
                if row.get("platform", "").lower() == "ont" and not row.get("basecaller"):
                    errors.append(f"line {line_number}: ONT rows should record basecaller metadata")
    except FileNotFoundError:
        errors.append(f"sample sheet not found: {path}")
    except csv.Error as exc:
        errors.append(f"CSV parsing error: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("samplesheet", type=Path)
    parser.add_argument("--check-paths", action="store_true")
    args = parser.parse_args()
    errors = validate(args.samplesheet, check_paths=args.check_paths)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Valid benchmark sample sheet: {args.samplesheet}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
