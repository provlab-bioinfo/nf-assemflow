 process AUTOCYCLER_SUBSAMPLE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/autocycler:0.5.2--h3ab6199_0':
        'biocontainers/autocycler:0.5.2--h3ab6199_0' }"

    input:
    path genome_size from ESTIMATE_GENOME_SIZE.out
    path subsampled_reads from SUBSAMPLE_READS.out.collect()
    val assembler from Channel.fromList(params.assemblers)
    val sample_id from Channel.fromList(params.coverage_subsamples)

    output:
    path "assemblies/${assembler}_${sample_id}"

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"


    """
    mkdir -p assemblies
    genome_size=\$(cat ${genome_size})
    autocycler helper ${assembler} \\
        --reads subsampled_reads/sample_${sample_id}.fastq \\
        --out_prefix assemblies/${assembler}_${sample_id} \\
        --threads ${task.cpus} \\
        --genome_size "\$genome_size"
    """
