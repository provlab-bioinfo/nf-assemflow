process DORADO_ALIGNER {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ontresearch/dorado:latest' :
        'ontresearch/dorado:latest' }"

    input:
    tuple val(meta), path(reads), path(draft_contigs)

    output:
    tuple val(meta), path("*.dorado_aligned_sorted.bam"), emit: bam
    tuple val(meta), path("*.dorado_aligned_sorted.bam.bai"), emit: bai
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """

    dorado aligner  --add-fastq-rg ${draft_contigs} ${reads} -o ${prefix}.bam
    samtools sort --threads ${task.cpus} ${prefix}.bam -o ${prefix}.dorado_aligned_sorted.bam
    samtools index ${prefix}.dorado_aligned_sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch   ${prefix}.dorado_aligned_sorted_reads.bam
    touch ${prefix}.dorado_aligned_sorted_reads.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | sed 's/^.*dorado //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')

    END_VERSIONS
    """
}
