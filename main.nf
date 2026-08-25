nextflow.enable.dsl=2

include { RUN_SPADES } from './modules/run_spades'
include { RUN_FLYE } from './modules/run_flye'
include { RUN_UNICYCLER } from './modules/run_unicycler'
include { COLLECT_REPORT } from './modules/collect_report'
include { PROVENANCE } from './modules/provenance'

workflow {
    samplesheet = Channel.fromPath(params.input, checkIfExists: true)
    rows = samplesheet.splitCsv(header: true)

    inputs = rows.map { row ->
        def meta = [
            id: row.sample.toString().trim(),
            platform: (row.platform ?: '').toString().trim(),
            basecaller: (row.basecaller ?: '').toString().trim(),
            genome_size: (row.genome_size ?: '').toString().trim(),
            ploidy: (row.ploidy ?: '').toString().trim()
        ]
        tuple(meta, file(row.reads1), file(row.reads2), file(row.long_reads))
    }

    // DSL2 broadcasts a channel safely to independent consumers; every strategy receives the same row.
    spades = inputs.map { meta, reads1, reads2, long_reads -> tuple(meta, reads1, reads2) }
    flye = inputs.map { meta, reads1, reads2, long_reads -> tuple(meta, long_reads) }
    unicycler = inputs.map { meta, reads1, reads2, long_reads -> tuple(meta, reads1, reads2, long_reads) }

    spades_result = RUN_SPADES(spades)
    flye_result = RUN_FLYE(flye)
    unicycler_result = RUN_UNICYCLER(unicycler)

    metrics = spades_result.result.map { it[3] }
        .mix(flye_result.result.map { it[3] })
        .mix(unicycler_result.result.map { it[3] })
        .collect()

    COLLECT_REPORT(metrics)
    PROVENANCE(samplesheet)
}
