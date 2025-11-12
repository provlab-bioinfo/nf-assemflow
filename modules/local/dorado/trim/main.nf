process DORADO_TRIM {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ontresearch/dorado:latest' :
        'ontresearch/dorado:latest' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.trimmed.bam"), emit: bam
    path "*.trimmed.fastq.gz"           , emit: fastq, optional: true
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def emit_fastq = args.contains('--emit-fastq')
    def output = emit_fastq ? "| gzip > ${prefix}.trimmed.fastq.gz" : "> ${prefix}.trimmed.bam"
    """
    dorado trim \\
        ${args} \\
        ${bam} \\
        ${output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    def emit_fastq = args.contains('--emit-fastq')
    """
    touch ${prefix}.trimmed.bam
    ${emit_fastq ? "touch ${prefix}.trimmed.fastq.gz" : ""}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """
}

process DORADO_TRIM_PRIMERS {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ontresearch/dorado:latest' :
        'ontresearch/dorado:latest' }"

    input:
    tuple val(meta), path(bam)
    path primer_file

    output:
    tuple val(meta), path("*.trimmed.bam"), emit: bam
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dorado trim \\
        --primer-sequences ${primer_file} \\
        ${args} \\
        ${bam} \\
        > ${prefix}.trimmed.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.trimmed.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """
}
