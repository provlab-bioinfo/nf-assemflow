process DORADO_BASECALLER {
    tag "$meta.id"
    label 'process_high'
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ontresearch/dorado:latest' :
        'ontresearch/dorado:latest' }"
    
    input:
    tuple val(meta), path(pod5)
    path model
    
    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dorado basecaller \\
        ${model} \\
        ${pod5} \\
        ${args} \\
        > ${prefix}.bam
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """
    
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
    END_VERSIONS
    """
}