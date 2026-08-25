process PROVENANCE {
    tag 'benchmark-provenance'
    label 'benchmark_report'
    publishDir "${params.outdir}/provenance", mode: 'copy', overwrite: true

    input:
    path samplesheet

    output:
    path 'samplesheet.normalized.csv', emit: normalized
    path 'params.json', emit: parameters
    path 'software_versions.yml', emit: versions

    script:
    """
    cp ${samplesheet} samplesheet.normalized.csv
    cat > params.json <<'JSON'
{
  "input": "${params.input}",
  "outdir": "${params.outdir}",
  "resource_policy": "benchmark_assembly label from nextflow.config"
}
JSON
    printf 'nextflow: %s\\n' "\${NXF_VER:-unknown}" > software_versions.yml
    for tool in spades.py flye unicycler quast.py compleasm busco merqury.sh; do
      if command -v "\$tool" >/dev/null 2>&1; then
        printf '%s: available\\n' "\$tool" >> software_versions.yml
      else
        printf '%s: unavailable\\n' "\$tool" >> software_versions.yml
      fi
    done
    """

    stub:
    """
    cp ${samplesheet} samplesheet.normalized.csv
    printf '{"stub": true, "input": "${params.input}", "outdir": "${params.outdir}"}\\n' > params.json
    printf 'nextflow: stub\\n' > software_versions.yml
    """
}
