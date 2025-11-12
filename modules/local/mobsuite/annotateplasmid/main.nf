process MOBSUITE_ANNOTATEPLASMID{
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge:biopython:1.81"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.81' :
        'biocontainers/biopython:1.81' }"

    input:
    tuple val(meta), path(contig_report), path(fasta)

    output:
    tuple val(meta), path("*plasmid.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    prefix = task.ext.prefix ?: "${meta.id}"
    def fastas =  fasta.join(' ')

    """
    mobsuite_annotate_plasmid.py --report ${contig_report} -o ${prefix}.plasmid.fasta --fasta ${fastas}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        pandas: \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)")
    END_VERSIONS
    """
}
