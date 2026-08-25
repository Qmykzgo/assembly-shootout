process RUN_UNICYCLER {
    tag "${meta.id}:hybrid_unicycler"
    label 'benchmark_assembly'

    input:
    tuple val(meta), path(reads1), path(reads2), path(long_reads)

    output:
    tuple val(meta), val('hybrid_unicycler'), path("${meta.id}.hybrid_unicycler.fasta"), path("${meta.id}.hybrid_unicycler.metrics.tsv"), emit: result

    script:
    """
    /usr/bin/time -f '%e\\t%M' -o ${meta.id}.hybrid_unicycler.resource.tsv \\
      unicycler -1 ${reads1} -2 ${reads2} -l ${long_reads} \\
      -o unicycler_out --mode conservative --threads ${task.cpus}
    test -s unicycler_out/assembly.fasta
    cp unicycler_out/assembly.fasta ${meta.id}.hybrid_unicycler.fasta
    read wall_clock peak_rss_kb < ${meta.id}.hybrid_unicycler.resource.tsv
    peak_rss_mb=\$(awk -v kb="\$peak_rss_kb" 'BEGIN {printf "%.2f", kb/1024}')
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.hybrid_unicycler.metrics.tsv
    printf '${meta.id}\\thybrid_unicycler\\tAVAILABLE\\tNA\\tNA\\tNA\\tNA\\tNOT_RUN\\tNOT_RUN\\t%s\\t%s\\tUnicycler conservative hybrid route\\n' "\$wall_clock" "\$peak_rss_mb" >> ${meta.id}.hybrid_unicycler.metrics.tsv
    """

    stub:
    """
    printf '>stub_${meta.id}_hybrid_unicycler\\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\\n' > ${meta.id}.hybrid_unicycler.fasta
    printf '0.03\\t64\\n' > ${meta.id}.hybrid_unicycler.resource.tsv
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.hybrid_unicycler.metrics.tsv
    printf '${meta.id}\\thybrid_unicycler\\tSTUB\\t40\\t1\\t40\\t40\\tSTUB\\tSTUB\\t0.03\\t0.06\\tno biological assembly was performed\\n' >> ${meta.id}.hybrid_unicycler.metrics.tsv
    """
}
