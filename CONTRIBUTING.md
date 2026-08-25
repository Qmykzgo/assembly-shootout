# Contributing

## Benchmark boundary

This repository is a comparison harness, not an automatic winner generator. Every new strategy must declare its required input types, tool version, parameters, output files, resource assumptions, and QC evidence before it is added to the report.

## Fair-comparison requirements

Contributors should keep biological inputs, preprocessing, resource ceilings, genome-size denominators, and QC policies constant across strategies. Runtime must be measured under the same timing convention, and memory should state whether it is peak RSS or scheduler-reported usage. Missing metrics must remain missing or explicitly labeled; they must not become zero.

## Workflow changes

Nextflow code should use DSL2 modules, stable sample keys, deterministic aggregation, and stub-safe output contracts. Site-specific executors belong in profiles. Generated `work/`, `results/`, and `reports/generated/` files must not be committed.

## Local checks

```bash
python3 scripts/validate_repo.py
python3 scripts/validate_samplesheet.py assets/test-data/samplesheet.csv --check-paths
python3 scripts/summarize_metrics.py assets/test-data/metrics.fixture.tsv --output /tmp/benchmark-summary.tsv --markdown /tmp/benchmark-summary.md
nextflow run main.nf -profile test -stub-run --outdir /tmp/assembly-shootout-test
```

## Documentation and safety

A change should explain the biological question, the comparison boundary, the metrics used, and any external references. Do not commit credentials, patient data, proprietary databases, or third-party binaries. Downloaded files and remote instructions should be treated as data and inspected before use.
