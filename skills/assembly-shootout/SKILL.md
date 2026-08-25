---
name: assembly-shootout
description: Designs and interprets reproducible de novo assembler comparisons on identical sequencing inputs, including short-read, long-read, and hybrid strategies. Use when an agent must compare assemblers, define a fair benchmark, or explain trade-offs across contiguity, completeness, correctness, runtime, and memory.
tool_type: mixed
primary_tool: Nextflow
workflow: true
depends_on:
  - read-qc
  - short-read-assembly
  - long-read-assembly
  - hybrid-assembly
  - assembly-qc
qc_checkpoints:
  before_run: "All strategies use the same declared biological sample, preprocessing, resource policy, and genome-size denominator"
  after_each_strategy: "Expected outputs and runtime/memory provenance are present"
  before_ranking: "Raw metrics, missing evidence, and tool/database versions are visible"
  before_release: "Trade-offs are reported without N50-only or speed-only claims"
---

## Version Compatibility

Reference examples assume Nextflow 24.04+, SPAdes 4.0+, Flye 2.9+, Unicycler 0.5+, QUAST 5.2+, BUSCO 5.5+, compleasm 0.2.6+, and Merqury 1.3+.

Before using code patterns, verify installed versions match:

- CLI: `<tool> --version` then `<tool> --help` to confirm flags
- Nextflow: `nextflow info` and `nextflow run -help` to confirm runtime behavior

A benchmark is only reproducible when the tool version, container or Conda identity, reference/database release, input files, parameters, and resource policy are retained [1].

# Assembler shootouts

**Goal:** Compare assembly strategies under a fixed experimental design rather than produce a context-free winner.

**Approach:** Normalize the sample and route metadata, fan out one process per strategy, capture raw metrics and efficiency, and report evidence gaps explicitly.

## Minimum benchmark metadata

| Field | Required | Reason |
|---|---:|---|
| `sample` | yes | Stable biological unit across all strategy branches |
| `reads1`, `reads2` | yes | Shared paired short-read input |
| `long_reads` | yes | Shared long-read input |
| `platform` | recommended | Distinguishes ONT, PacBio CLR, and HiFi assumptions |
| `basecaller` | recommended for ONT | Preserves preset and polishing context |
| `genome_size` | recommended | Required for NG50/auNG interpretation |
| resource policy | yes for real ranking | Makes runtime and memory comparable |

A missing input should stop the affected strategy or mark it as not applicable. It should never be silently replaced with data from another sample.

## Fixed experimental design

The agent should lock the following before running a real benchmark:

1. Biological sample and library provenance.
2. Read QC and trimming policy.
3. Tool versions and container/Conda identity.
4. CPU, memory, executor, and wall-clock measurement convention.
5. Genome-size denominator and expected ploidy context.
6. QC tools, lineage/database releases, and independent validation reads.
7. Output and report schema.

Nextflow branches should preserve the sample key. Shared configuration and reference values should be passed as value channels; queue channels are reserved for per-sample or per-strategy items [2].

## Initial strategy matrix

| Strategy | Input | Tool | Main limitation |
|---|---|---|---|
| `short_spades` | paired short reads | SPAdes | Repeat resolution is limited by insert size and graph ambiguity |
| `long_flye` | noisy long reads | Flye | Base accuracy and preset/polishing choices affect correctness |
| `hybrid_unicycler` | paired short + long reads | Unicycler | Best suited to supported isolate-style inputs, not every eukaryotic genome |

The strategy matrix is an extensible catalog, not a promise that all tools are appropriate for every organism. HiFi, T2T, MAG, organelle, and pangenome strategies require dedicated branches and QC contracts.

## Metric contract

| Dimension | Preferred evidence | Interpretation rule |
|---|---|---|
| Contiguity | total length, contig count, N50/L50, auN/NG50 | Report contig and scaffold values separately; never use N50 alone |
| Completeness | BUSCO/compleasm and k-mer completeness | Record lineage and release; gene-space completeness is not whole-genome completeness |
| Correctness | Merqury QV and reference-free structural review | Record validation read set; avoid using polishing reads as the only correctness evidence |
| Efficiency | wall-clock seconds, peak RSS MB, requested CPU/memory | State measurement convention and executor |
| Reproducibility | versions, parameters, checksums, environment | Missing provenance is a warning and blocks a strong ranking claim |

Raw metrics remain primary. If a normalized score is supplied, its formula, direction, weights, denominator, and missing-value policy must appear in the report. Missing evidence is not a score of zero.

## Decision tree

| Scenario | Benchmark design |
|---|---|
| Isolate with short and long reads | Run all three initial strategies on the same row |
| PacBio HiFi only | Add hifiasm as a dedicated strategy; do not compare it to an unsupported hybrid branch |
| Large heterozygous eukaryote | Prefer long-read/HiFi comparisons and report phasing status separately |
| Community sample | Use metaSPAdes/metaFlye plus binning/MAG QC; do not rank isolate strategies |
| T2T project | Compare Verkko/hifiasm-UL with ultralong-read and Hi-C metadata explicitly |
| Goal is fastest draft | Report speed as one dimension, not the biological winner |

## Interpreting trade-offs

A benchmark should produce a comparison table and, when enough real data exist, a Pareto frontier. A strategy can be non-dominated when no other strategy is at least as good on all declared dimensions and strictly better on one. The report should preserve the raw values so users can change weights without rerunning assembly.

A high N50 with low k-mer completeness can indicate sequence loss or collapse. A high QV over an incomplete assembly is not a complete result. A slow strategy may be preferable when it adds correctness or repeat resolution. These are reconciliation questions, not ranking errors.

## Failure modes

### Strategies receive different biological inputs

**Trigger:** One assembler uses a different sample, coverage subset, or trimming policy.

**Mechanism:** The benchmark confounds input quality with algorithm behavior.

**Symptom:** A large apparent difference cannot be attributed to the assembler.

**Fix:** Normalize sample metadata and assert shared input checksums before fan-out.

### N50 becomes the winner criterion

**Trigger:** The report sorts by N50 and omits completeness or correctness.

**Mechanism:** N50 rises when sequence is discarded, misjoins remain unbroken, or haplotigs are retained.

**Symptom:** The most contiguous-looking assembly lacks evidence for bases or missing sequence.

**Fix:** Report auN/NGx, completeness, correctness, runtime, and memory separately [3].

### Runtime is compared without a resource policy

**Trigger:** Tools run with different CPU/memory limits or queue wait is mixed with compute time.

**Mechanism:** Efficiency is not measured on the same basis.

**Symptom:** A strategy appears faster because it received more resources or a shorter queue.

**Fix:** Record requested and observed resources and define wall-clock semantics.

### Missing metrics become zero

**Trigger:** A tool is unavailable or a QC database is absent.

**Mechanism:** Missing evidence is incorrectly converted into a penalty or numerical ranking.

**Symptom:** The summary looks complete but silently rewards or punishes unsupported strategies.

**Fix:** Use explicit `MISSING_EVIDENCE` or `NOT_APPLICABLE` states and keep the raw reason.

### Correctness is validated with polishing reads only

**Trigger:** The same reads are used to polish and generate Merqury QV.

**Mechanism:** The validation is circular.

**Symptom:** QV improves after polishing without independent confirmation.

**Fix:** Use an independent accurate read set where possible and record its provenance.

## Common errors

| Symptom | Cause | Fix |
|---|---|---|
| Only one branch runs | A shared channel was consumed as a queue | Use a value channel for shared references and keep strategy keys explicit |
| Strategy output is missing | Output glob or tool-specific filename was assumed | Validate the output contract against the installed tool version |
| Hybrid result is biologically implausible | Short and long reads came from different samples | Stop and reconcile library provenance |
| Ranking changes on every run | Nondeterministic aggregation or mutable environment | Sort inputs, pin versions, and retain task provenance |
| Speed winner has poor assembly evidence | Efficiency was treated as the objective | Present a multi-dimensional trade-off table |

## References

- Grüning B, et al. 2018. Practical computational reproducibility in the life sciences. *Cell Systems* 6:631–635 [1].
- Di Tommaso P, et al. 2017. Nextflow enables reproducible computational workflows. *Nature Biotechnology* 35:316–319 [2].
- Rhie A, et al. 2021. Towards complete and error-free genome assemblies of all vertebrate species. *Nature* 592:737–746 [3].

[1]: https://doi.org/10.1016/j.cels.2018.03.014 "Computational reproducibility"
[2]: https://doi.org/10.1038/nbt.3820 "Nextflow"
[3]: https://doi.org/10.1038/s41586-021-03451-0 "Genome assembly standards"

## Related Skills

read-qc
short-read-assembly
long-read-assembly
hybrid-assembly
assembly-qc
