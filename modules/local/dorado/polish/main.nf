process DORADO_POLISH {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ontresearch/dorado:latest' :
        'ontresearch/dorado:latest' }"

    input:
    tuple val(meta), path(bam), path(bam_bai), path(draft_contigs)

    output:
    tuple val(meta), path("*.dorado_polished_assembly.fasta"), emit: assembly
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Call consensus
    dorado polish ${bam} ${draft_contigs} > ${prefix}.dorado_polished_assembly.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    touch  ${prefix}.dorado_polished_assembly.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """
}
