#!/usr/bin/env python3
"""Validate the assembly-shootout repository contract."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
METRIC_COLUMNS = {
    "sample", "strategy", "status", "total_length_bp", "contig_count", "n50", "auN",
    "completeness_qc", "correctness_qv", "wall_clock_seconds", "peak_rss_mb", "note"
}


def read_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"(?ms)^---\s*\n(.*?)\n---\s*\n", text)
    if not match:
        raise ValueError("missing YAML frontmatter")
    value = yaml.safe_load(match.group(1))
    if not isinstance(value, dict):
        raise ValueError("frontmatter must be a mapping")
    return value


def validate_skill(path: Path) -> list[str]:
    errors: list[str] = []
    skill = path / "SKILL.md"
    guide = path / "usage-guide.md"
    if not skill.exists():
        return [f"{path}: missing SKILL.md"]
    try:
        data = read_frontmatter(skill)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        return [f"{skill}: {exc}"]
    for field in ("name", "description", "tool_type", "primary_tool"):
        if field not in data:
            errors.append(f"{skill}: missing {field}")
    if str(data.get("name", "")) != path.name:
        errors.append(f"{skill}: name does not match directory")
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", str(data.get("name", ""))):
        errors.append(f"{skill}: name is not kebab-case")
    if "Use when" not in str(data.get("description", "")):
        errors.append(f"{skill}: description lacks Use when trigger")
    if "," in str(data.get("primary_tool", "")):
        errors.append(f"{skill}: primary_tool must be a single value")
    text = skill.read_text(encoding="utf-8")
    if len(text.splitlines()) > 500:
        errors.append(f"{skill}: exceeds 500 lines")
    for heading in ("## Version Compatibility", "## References", "## Related Skills"):
        if heading not in text:
            errors.append(f"{skill}: missing {heading}")
    if guide.exists():
        guide_text = guide.read_text(encoding="utf-8")
        for heading in ("## Overview", "## Prerequisites", "## Quick Start", "## Example Prompts", "## What the Agent Will Do", "## Tips", "## Related Skills"):
            if heading not in guide_text:
                errors.append(f"{guide}: missing {heading}")
    else:
        errors.append(f"{path}: missing usage-guide.md")
    if data.get("workflow") and (not data.get("depends_on") or not data.get("qc_checkpoints")):
        errors.append(f"{skill}: workflow metadata is incomplete")
    return errors


def validate_manifest() -> list[str]:
    path = ROOT / "openclaw.plugin.json"
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{path}: {exc}"]
    errors: list[str] = []
    if not manifest.get("id") or not manifest.get("name"):
        errors.append(f"{path}: id and name are required")
    for relative in manifest.get("skills", []):
        if not (ROOT / relative).is_dir():
            errors.append(f"{path}: missing skill path {relative}")
    return errors


def validate_metrics_fixture() -> list[str]:
    path = ROOT / "assets/test-data/metrics.fixture.tsv"
    try:
        header = path.read_text(encoding="utf-8").splitlines()[0].split("\t")
    except (OSError, IndexError) as exc:
        return [f"{path}: {exc}"]
    missing = METRIC_COLUMNS - set(header)
    return [f"{path}: missing metric columns {sorted(missing)}"] if missing else []


def validate_samplesheet() -> list[str]:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts/validate_samplesheet.py"), str(ROOT / "assets/test-data/samplesheet.csv"), "--check-paths"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return [result.stderr.strip()] if result.returncode else []


def main() -> int:
    errors: list[str] = []
    skill_dirs = sorted(path for path in (ROOT / "skills").iterdir() if path.is_dir())
    for path in skill_dirs:
        errors.extend(validate_skill(path))
    errors.extend(validate_manifest())
    errors.extend(validate_metrics_fixture())
    errors.extend(validate_samplesheet())
    for relative in ("main.nf", "nextflow.config", "modules/run_spades.nf", "modules/run_flye.nf", "modules/run_unicycler.nf", "modules/collect_report.nf", "modules/provenance.nf"):
        if not (ROOT / relative).exists():
            errors.append(f"missing required file: {relative}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Repository is valid: {len(skill_dirs)} skill(s), metric schema, sample sheet, and modules checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
