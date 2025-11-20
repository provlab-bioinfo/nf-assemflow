/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'


//
//local subworkflows
//
include { ASSEMBLE_ILLUMINA } from '../subworkflows/local/assembly_illumina'
include { PUBLISH_ASSEMBLIES } from '../modules/local/publish/assemblies'
include { PUBLISH_SAMPLESHEET } from '../modules/local/publish/samplesheet'
include { DEPTH_ILLUMINA } from '../subworkflows/local/depth_illumina'

//
// MODULE: local modules
//
include { CHECKM2_PREDICT } from '../modules/local/checkm2/predict.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMFLOW_SHORT {
    take:
    short_reads

    main:

    ch_versions = channel.empty()


    short_reads = short_reads.filter { _meta, reads ->
        def readsList = reads instanceof List ? reads : [reads]
        readsList.size() > 0 && readsList.every { it != null && it.exists() && it.size() > 0 }
    }

    // assembly
    ASSEMBLE_ILLUMINA(short_reads)
    // zero size contig can cause some of the program such as bakta, mobsuite file
    ASSEMBLE_ILLUMINA.out.contigs.filter { _meta, contigs -> contigs.countFasta() > 0 }.set { contigs }
    ch_versions = ch_versions.mix(ASSEMBLE_ILLUMINA.out.versions)

    PUBLISH_ASSEMBLIES(contigs)
    assemblies_collected = PUBLISH_ASSEMBLIES.out.contigs.collect().ifEmpty([]).map { it.collate(2) }
    assemblies_collected.view()
    // Generate samplesheet
    PUBLISH_SAMPLESHEET(assemblies_collected)

    //
    // depth report
    //
    if (!params.skip_depth_and_coverage_illumina) {
        short_reads.join(contigs)
            .multiMap { it ->
                reads: [it[0], it[1]]
                contigs: [it[0], it[2]]
            }
            .set {
                ch_input_depth
            }
        DEPTH_ILLUMINA(ch_input_depth.reads, ch_input_depth.contigs)
    }


    if (!params.skip_checkm2) {
        ch_input_checkm2 = contigs.map { _meta, mycontigs -> mycontigs }.collect()
        .map {
            files -> tuple([id: "checkm2"], files)
        }
        //.view()
        CHECKM2_PREDICT(ch_input_checkm2, params.checkm2_db)
        ch_versions = ch_versions.mix(CHECKM2_PREDICT.out.versions)
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
