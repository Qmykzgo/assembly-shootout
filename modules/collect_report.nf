process COLLECT_REPORT {
    tag 'benchmark-report'
    label 'benchmark_report'
    publishDir "${params.outdir}/03_reports", mode: 'copy', overwrite: true

    input:
    path metrics

    output:
    path 'benchmark_summary.tsv', emit: tsv
    path 'benchmark_summary.md', emit: markdown

    script:
    """
    python3 ${projectDir}/scripts/summarize_metrics.py ${metrics} \\
      --output benchmark_summary.tsv --markdown benchmark_summary.md
    """

    stub:
    """
    python3 ${projectDir}/scripts/summarize_metrics.py ${metrics} \\
      --output benchmark_summary.tsv --markdown benchmark_summary.md
    """
}
