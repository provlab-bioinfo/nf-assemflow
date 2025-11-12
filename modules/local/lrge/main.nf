process LRGE {
    tag "$meta.id"
    label 'process_medium'


    conda "bioconda::Lrge=0.2.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lrge:0.2.1--h9f13da3_0':
        'biocontainers/lrge:0.2.1--h9f13da3_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*gsize.txt"), emit: gsize
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    lrge -t ${task.cpus} $args -o ${prefix}.lrge_gsize.txt $reads


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lrge: \$(echo \$(lrge -V 2>&1) | sed 's/^lrge //;')
    END_VERSIONS
    """
}
