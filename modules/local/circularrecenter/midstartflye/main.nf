process CIRCULARRECENTER_MIDSTARTFLYE {

    tag "$meta.id"
    label 'process_medium'


    conda "conda-forge::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2':
        'biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(fasta), path(assembly_info)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    circular_midstart_flye.pl \\
        -f $fasta \\
        -i $assembly_info \\
        > ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(echo \$(perl -v 2>&1) | sed -n \'2 p\' | sed 's/^.*?(v//g; s/^).*//g;' ))
    END_VERSIONS
    """
}
