process CIRCULARRECENTER_DNAAPLER {
    tag "$meta.id"
    label 'process_medium'
    errorStrategy 'ignore'

    conda "bioconda::dnaapler=1.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dnaapler:1.3.0--pyhdfd78af_0' :
        'biocontainers/dnaapler:1.3.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path("output.dnaapler/*reoriented.gfa"), emit: gfa
    tuple val(meta), path("output.dnaapler/*all_reorientation_summary.tsv"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    #!/usr/bin/env bash
    set -euo pipefail

    input="${gfa}"

    # Decompress if input is gzipped
    if [[ "\$input" == *.gz ]]; then
        echo "Decompressing input file..."
        gunzip -c "\$input" > input.gfa
        gfa="input.gfa"
    else
        gfa="\$input"
    fi

    echo "Running DNAapler..."
    dnaapler all -i "\$gfa" -p "${prefix}" -t ${task.cpus} ${args}

    # Record version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dnaapler: "\$(dnaapler --version 2>&1 | sed 's/^.*version //')"
    END_VERSIONS
    """
}
