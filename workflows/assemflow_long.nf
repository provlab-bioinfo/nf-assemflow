/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { ASSEMBLE_NANOPORE } from '../subworkflows/local/assembly_nanopore'
include { PUBLISH_ASSEMBLIES } from '../modules/local/publish/assemblies'
include { PUBLISH_SAMPLESHEET } from '../modules/local/publish/samplesheet'
include { DEPTH_NANOPORE } from '../subworkflows/local/depth_nanopore'
include { CHECKM2_PREDICT } from '../modules/local/checkm2/predict.nf'
include { CSVTK_CONCAT } from '../modules/local/csvtk/concat'
include { ASSEMBLYSTATS } from '../modules/local/stats/assemblystats'
include { REFORMATASSEMBLYSTATS as REFORMATASSEMBLYSTATS_NANOPORE } from '../modules/local/stats/reformatassemblystats'
include { FASTA_REFORMATHEADER } from '../modules/local/fasta/reformatheader'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMFLOW_LONG {
    take:
    long_reads

    main:

    ch_versions = channel.empty()

    long_reads = long_reads.filter { _meta, myreads ->
        def readsList = myreads instanceof List ? myreads : [myreads]
        readsList.size() > 0 && readsList.every { it != null && it.exists() && it.size() > 0 }
    }

    //
    // assembly
    //
    if (!params.skip_nanopore_reads_assembly) {

        //flye with 4x iteration and 1x medaka
        ASSEMBLE_NANOPORE(long_reads)
        contigs = ASSEMBLE_NANOPORE.out.contigs.filter { _meta, contigs -> contigs.countFasta() > 0 }
        ch_versions = ch_versions.mix(ASSEMBLE_NANOPORE.out.versions)
        //stats = ASSEMBLE_NANOPORE.out.stats
        FASTA_REFORMATHEADER(contigs)
        contigs = FASTA_REFORMATHEADER.out.fasta
        contigs.view()
        ASSEMBLYSTATS(contigs)
        ch_software_versions = ch_versions.mix(ASSEMBLYSTATS.out.versions.first())
        REFORMATASSEMBLYSTATS_NANOPORE(ASSEMBLYSTATS.out.stats)
        ch_software_versions = ch_software_versions.mix(REFORMATASSEMBLYSTATS_NANOPORE.out.versions.first())
        stats = REFORMATASSEMBLYSTATS_NANOPORE.out.tsv


        CSVTK_CONCAT(
            stats.map {
                _meta, mystats -> mystats
            }.collect().map { files -> tuple([id: "assembly_nanopore_stats"], files) },
            'tsv',
            'tsv',
        )


        PUBLISH_ASSEMBLIES(contigs)
        assemblies_collected = PUBLISH_ASSEMBLIES.out.contigs.collect().ifEmpty([]).map { it.collate(2) }
        assemblies_collected.view()
        // Generate samplesheet
        PUBLISH_SAMPLESHEET(
            assemblies_collected
            //channel.value([])
        )

        if (!params.skip_depth_and_coverage_nanopore) {
            DEPTH_NANOPORE(long_reads, contigs)
            ch_versions = ch_versions.mix(DEPTH_NANOPORE.out.versions)
        }

        if (!params.skip_checkm2) {
            ch_input_checkm2 = contigs
                .map { _meta, mycontigs -> mycontigs}.collect()
                .map { files ->
                    tuple([id: "checkm2"], files)
                }
            //.view()
            CHECKM2_PREDICT(ch_input_checkm2, params.checkm2_db)
            ch_versions = ch_versions.mix(CHECKM2_PREDICT.out.versions)
        }
    }
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'assemflow_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}
