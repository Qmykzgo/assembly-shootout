#!/usr/bin/env python3
"""Normalize per-strategy benchmark metric TSV files into TSV and Markdown."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

FIELDNAMES = [
    "sample",
    "strategy",
    "status",
    "total_length_bp",
    "contig_count",
    "n50",
    "auN",
    "completeness_qc",
    "correctness_qv",
    "wall_clock_seconds",
    "peak_rss_mb",
    "note",
]


def read_rows(paths: list[Path]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in sorted(paths, key=lambda item: item.name):
        with path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle, delimiter="\t")
            missing = set(FIELDNAMES) - set(reader.fieldnames or [])
            if missing:
                raise ValueError(f"{path} is missing columns: {', '.join(sorted(missing))}")
            rows.extend({field: (row.get(field) or "").strip() for field in FIELDNAMES} for row in reader)
    return sorted(rows, key=lambda row: (row["sample"], row["strategy"]))


def write_tsv(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


def write_markdown(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write("# Assembly shootout summary\n\n")
        handle.write("Raw values are preserved. `STUB`, `NOT_RUN`, `MISSING_EVIDENCE`, and `NA` are explicit states rather than zeros. No universal winner is inferred.\n\n")
        columns = ["sample", "strategy", "status", "total_length_bp", "contig_count", "n50", "auN", "completeness_qc", "correctness_qv", "wall_clock_seconds", "peak_rss_mb"]
        handle.write("| " + " | ".join(columns) + " |\n")
        handle.write("| " + " | ".join("---" for _ in columns) + " |\n")
        for row in rows:
            handle.write("| " + " | ".join(row[column].replace("|", "\\|") for column in columns) + " |\n")
        handle.write("\n## Interpretation guardrails\n\n")
        handle.write("Contiguity, completeness, correctness, runtime, and memory must be interpreted together. N50 is not a release criterion, and missing evidence prevents a strong ranking claim. Runtime is not biological quality.\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metrics", nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--markdown", required=True, type=Path)
    args = parser.parse_args()
    rows = read_rows(args.metrics)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    write_tsv(args.output, rows)
    write_markdown(args.markdown, rows)
    print(f"Wrote {len(rows)} metric rows to {args.output} and {args.markdown}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
