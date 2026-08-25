process RUN_FLYE {
    tag "${meta.id}:long_flye"
    label 'benchmark_assembly'

    input:
    tuple val(meta), path(long_reads)

    output:
    tuple val(meta), val('long_flye'), path("${meta.id}.long_flye.fasta"), path("${meta.id}.long_flye.metrics.tsv"), emit: result

    script:
    def preset = meta.platform.toLowerCase() == 'pacbio-clr' ? '--pacbio-raw' : '--nano-hq'
    def size_arg = meta.genome_size ? "--genome-size ${meta.genome_size}" : ''
    """
    /usr/bin/time -f '%e\\t%M' -o ${meta.id}.long_flye.resource.tsv \\
      flye ${preset} ${long_reads} ${size_arg} \\
      --out-dir flye_out --threads ${task.cpus}
    test -s flye_out/assembly.fasta
    cp flye_out/assembly.fasta ${meta.id}.long_flye.fasta
    read wall_clock peak_rss_kb < ${meta.id}.long_flye.resource.tsv
    peak_rss_mb=\$(awk -v kb="\$peak_rss_kb" 'BEGIN {printf "%.2f", kb/1024}')
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.long_flye.metrics.tsv
    printf '${meta.id}\\tlong_flye\\tAVAILABLE\\tNA\\tNA\\tNA\\tNA\\tNOT_RUN\\tNOT_RUN\\t%s\\t%s\\tFlye platform-aware long-read route\\n' "\$wall_clock" "\$peak_rss_mb" >> ${meta.id}.long_flye.metrics.tsv
    """

    stub:
    """
    printf '>stub_${meta.id}_long_flye\\nACGTACGTACGTACGTACGTACGTACGTACGT\\n' > ${meta.id}.long_flye.fasta
    printf '0.02\\t48\\n' > ${meta.id}.long_flye.resource.tsv
    printf 'sample\\tstrategy\\tstatus\\ttotal_length_bp\\tcontig_count\\tn50\\tauN\\tcompleteness_qc\\tcorrectness_qv\\twall_clock_seconds\\tpeak_rss_mb\\tnote\\n' > ${meta.id}.long_flye.metrics.tsv
    printf '${meta.id}\\tlong_flye\\tSTUB\\t32\\t1\\t32\\t32\\tSTUB\\tSTUB\\t0.02\\t0.05\\tno biological assembly was performed\\n' >> ${meta.id}.long_flye.metrics.tsv
    """
}
