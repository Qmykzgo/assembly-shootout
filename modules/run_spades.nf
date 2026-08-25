process RUN_SPADES {
    tag "${meta.id}:short_spades"
    label 'benchmark_assembly'

    input:
    tuple val(meta), path(reads1), path(reads2)

    output:
    tuple val(meta), val('short_spades'), path("${meta.id}.short_spades.fasta"), path("${meta.id}.short_spades.metrics.tsv"), emit: result

    script:
    """
    /usr/bin/time -f '%e\\t%M' -o ${meta.id}.short_spades.resource.tsv \\
      spades.py --isolate -1 ${reads1} -2 ${reads2} \\
      -o spades_out -t ${task.cpus} -m 2
    test -s spades_out/contigs.fasta
    cp spades_out/contigs.fasta ${meta.id}.short_spades.fasta
    read wall_clock peak_rss_kb < ${meta.id}.short_spades.resource.tsv
    peak_rss_mb=\$(awk -v kb="\$peak_rss_kb" 'BEGIN {printf "%.2f", kb/1024}')
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.short_spades.metrics.tsv
    printf '${meta.id}\\tshort_spades\\tAVAILABLE\\tNA\\tNA\\tNA\\tNA\\tNOT_RUN\\tNOT_RUN\\t%s\\t%s\\tSPAdes isolate route\\n' "\$wall_clock" "\$peak_rss_mb" >> ${meta.id}.short_spades.metrics.tsv
    """

    stub:
    """
    printf '>stub_${meta.id}_short_spades\\nACGTACGTACGTACGTACGT\\n' > ${meta.id}.short_spades.fasta
    printf '0.01\\t32\\n' > ${meta.id}.short_spades.resource.tsv
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.short_spades.metrics.tsv
    printf '${meta.id}\\tshort_spades\\tSTUB\\t20\\t1\\t20\\t20\\tSTUB\\tSTUB\\t0.01\\t0.03\\tno biological assembly was performed\\n' >> ${meta.id}.short_spades.metrics.tsv
    """
}
