// Process to publish long reads
process PUBLISH_ASSEMBLIES {
    tag "$meta.id"
    //publishDir "${params.outdir}/qc_reads/${meta.id}", mode: 'copy'

    input:
    tuple val(meta), path(contigs)

    output:
    tuple val(meta), path(contigs), emit: contigs


    script:
    """
    # Files are automatically published by publishDir
    """
}
