## Overview

This skill designs fair de novo assembler comparisons on identical sequencing inputs. It separates assembly quality from efficiency and keeps raw metrics visible so users can change ranking preferences without rerunning the workflow.

## Prerequisites

- One biological sample with paired short reads and long reads for the initial three strategies.
- A validated sample sheet and a declared resource policy.
- Nextflow 24.04+ and site-approved assembler/QC environments for real execution.

## Quick Start

- "Design a fair SPAdes versus Flye versus Unicycler benchmark for this sample."
- "Run the benchmark in stub mode and verify that all strategy branches are represented."
- "Compare these assemblies without ranking by N50 alone."
- "Explain which missing QC evidence prevents a strong winner claim."

## Example Prompts

> "The hybrid assembly has the highest N50. Check whether it also has stronger completeness and correctness evidence."

> "These strategies used different CPU limits. Redesign the benchmark so runtime and memory are comparable."

> "Add hifiasm to this shootout only if the input and phasing contract is appropriate."

## What the Agent Will Do

The agent will validate sample identity, normalize the comparison contract, fan out strategies with stable keys, capture runtime and memory provenance, preserve missing evidence states, and produce a raw-metric report plus transparent interpretation notes.

## Tips

Treat the first report as a decision aid, not a universal leaderboard. Keep `work/` for resume support, archive tool/database versions, and use an independent read set for correctness QC when possible. Add new assemblers only after declaring their input and output contracts.

## Related Skills

read-qc
short-read-assembly
long-read-assembly
hybrid-assembly
assembly-qc
