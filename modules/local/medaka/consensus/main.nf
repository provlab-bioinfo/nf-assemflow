process MEDAKA_CONSENSUS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/medaka:2.1.1--py39h182ef57_0'
        : 'biocontainers/medaka:2.1.1--py39h182ef57_0'}"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("medaka/*.fasta.gz"), emit: assembly
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Create output directory
    mkdir -p medaka

    # Run medaka_consensus
    medaka_consensus \\
        -t ${task.cpus} \\
        -i ${reads} \\
        -d ${assembly} \\
        -o medaka \\
        ${args} > medaka.log 2>&1

    # Rename and compress output
    mv medaka/consensus.fasta medaka/${prefix}.contigs_medaka.fasta
    gzip -n medaka/${prefix}.contigs_medaka.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
