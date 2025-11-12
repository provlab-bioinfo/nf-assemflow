process GFATOOLS_GFA2FA {
    tag "$meta.id"
    label 'process_medium'


    conda "bioconda::gfatools=0.5.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gfatools:0.5.5--h577a1d6_0':
        'biocontainers/gfatools:0.5.5--h577a1d6_0' }"

    input:
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    gfatools gfa2fa ${gfa} > ${prefix}.gfa2fa.fasta


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":

    echo \$(gfatools version -V 2>&1)|  sed 's/ gfatools:/\\ngfatools:/'

    END_VERSIONS
    """
}
