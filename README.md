# assembly-shootout

A reproducible, agent-compatible **de novo assembler benchmark harness** for comparing short-read, long-read, and hybrid assembly strategies on identical inputs.

> **Benchmark principle:** there is no universal “best assembler.” A fair comparison preserves the same biological inputs, resource policy, preprocessing, QC contract, and provenance for every strategy.

## What this repository does

The first release compares three practical isolate strategies:

| Strategy | Inputs | Tool | Question |
|---|---|---|---|
| `short_spades` | paired short reads | SPAdes | What does a short-read-only graph recover? |
| `long_flye` | noisy long reads | Flye | How much continuity do long reads add? |
| `hybrid_unicycler` | paired short + long reads | Unicycler | Does hybrid evidence improve the trade-off? |

The harness creates one Nextflow branch per strategy, captures runtime and peak memory, normalizes assembly summaries, and writes a comparison report. It keeps raw metrics primary; an optional score is transparent and never converts missing evidence to zero.

## Why a separate shootout repository

The earlier `denovo-assembly-kit` repository routes one project to an appropriate assembly path. This repository answers a different question: **how do multiple assembly strategies compare when they receive the same sample and are judged by the same evidence?** The distinction prevents a benchmark from quietly mixing route selection with ranking.

The architecture follows the layered skill, progressive-disclosure, and validation patterns learned from GPTomics `bioSkills`, Bioclaw Skills Hub, OpenClaw Medical Skills, and the earlier assembly kit [1] [2] [3] [4].

## Quick start

### Validate the repository

```bash
python3 scripts/validate_repo.py
python3 scripts/validate_samplesheet.py assets/test-data/samplesheet.csv --check-paths
```

### Run the benchmark wiring test

The test profile uses tiny synthetic fixtures and Nextflow stub mode. It validates channel routing, strategy fan-out, resource capture, and report generation without requiring assemblers or QC databases.

```bash
nextflow run main.nf -profile test -stub-run --outdir results/test
```

### Run a real benchmark

1. Copy `assets/samplesheet.example.csv` and replace the paths with reads from one biological sample.
2. Validate the sample sheet and confirm short/long libraries have matching provenance.
3. Select a site-approved Docker or Singularity environment with the declared assemblers and QC tools.
4. Run with `-resume`, preserve `work/`, and archive the report plus provenance files.

```bash
python3 scripts/validate_samplesheet.py path/to/samplesheet.csv --check-paths
nextflow run main.nf \
  -profile docker \
  --input path/to/samplesheet.csv \
  --outdir results/my_benchmark \
  --genome_size 5000000 \
  -resume
```

## Sample-sheet contract

Each row represents one sample to be compared across the available strategies. The required fields are `sample`, `reads1`, `reads2`, and `long_reads`. The optional `platform`, `basecaller`, `genome_size`, and `ploidy` fields are carried into provenance and interpretation.

```csv
sample,reads1,reads2,long_reads,platform,basecaller,genome_size,ploidy
isolate_fixture,assets/test-data/short_R1.fastq,assets/test-data/short_R2.fastq,assets/test-data/long.fastq,ont,dorado-sup,5000000,1
```

The short-read, long-read, and hybrid strategies are expected to receive the same row. The benchmark validator rejects duplicate sample IDs, missing route-specific inputs, and a hybrid row without both library types.

## Metric contract

| Dimension | Preferred evidence | Benchmark handling |
|---|---|---|
| Contiguity | contig count, total length, N50/L50, auN/NG50 when genome size is known | Report contig and scaffold values separately |
| Completeness | BUSCO/compleasm and k-mer completeness when available | Record lineage and database release |
| Correctness | Merqury QV and reference-free structural review when available | Record the exact validation read set |
| Efficiency | wall-clock seconds and peak RSS MB | Compare under the same resource ceiling |
| Reproducibility | tool version, container/Conda identity, parameters, input checksums | Missing provenance remains a warning |

The summary includes `status` values such as `STUB`, `AVAILABLE`, and `MISSING_EVIDENCE`. Raw metrics are not synthesized from the stub fixtures. A benchmark report that lacks correctness or completeness evidence is incomplete, even if it has a high N50.

## Fairness rules

The benchmark keeps the sample, preprocessing policy, expected genome size, CPU/memory ceiling, output naming, and final QC contract constant across strategies. A strategy-specific input requirement is declared rather than silently filled from another sample. Runtime comparisons must distinguish process time from queue wait time, and memory comparisons should state whether peak RSS came from the process or the scheduler.

Assemblers are not interchangeable across genome size, ploidy, read chemistry, or community complexity. The report should therefore present a decision matrix and a Pareto view rather than a single winner. A real benchmark should use biological data supplied by the user; the repository’s tiny fixtures are only for structural tests.

## Output layout

```text
results/<benchmark>/
├── 01_runs/<strategy>/<sample>/
├── 02_qc/<strategy>/<sample>/
├── 03_reports/
│   ├── benchmark_summary.tsv
│   └── benchmark_summary.md
└── provenance/
    ├── params.json
    ├── samplesheet.normalized.csv
    ├── software_versions.yml
    └── execution_trace.txt
```

## Planned extensions

The next strategies are hifiasm for PacBio HiFi, Raven and wtdbg2 for long-read diversity, and explicit Flye/metaSPAdes branches for community samples. Later versions can add independent polishing, Merqury/QUAST/BUSCO aggregation, Pareto-frontier plots, T2T/Verkko, MAG evaluation, and annotation or assembly-based structural-variant handoffs.

## Safety and limitations

This repository contains workflow logic and reporting code, not large datasets, clinical interpretation, or third-party binaries. It does not claim that a faster assembler is more accurate. It does not use a divergent reference as an automatic correctness oracle, and it does not treat a missing metric as a failing score.

## References

[1]: https://github.com/GPTomics/bioSkills "GPTomics bioSkills"
[2]: https://github.com/zongtingwei/Bioclaw_Skills_Hub "Bioclaw Skills Hub"
[3]: https://github.com/FreedomIntelligence/OpenClaw-Medical-Skills "OpenClaw Medical Skills"
[4]: https://github.com/Qmykzgo/denovo-assembly-kit "Qmykzgo denovo-assembly-kit"
