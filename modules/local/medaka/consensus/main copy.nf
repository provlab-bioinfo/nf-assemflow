process MEDAKA_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:2.1.1--py39h182ef57_0' :
        'biocontainers/medaka:2.1.1--py39h182ef57_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)
    path(medaka_models_dir)

    output:
    tuple val(meta), path("medaka/*.fasta.gz"), emit: assembly
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def model_name = meta.basecaller_mode
    // Resolve symlink to absolute path in Nextflow
    def model_dir_abs = medaka_models_dir.toRealPath().toString()
    def m_option = meta.basecaller_mode != "NA" ? "-m ${model_dir_abs}/${model_name}_model_pt.tar.gz" : '--bacteria'

    """
    # Verify directory exists
    if [ ! -d "${model_dir_abs}" ]; then
        echo "ERROR: Directory ${model_dir_abs} does not exist"
        echo "Checking what's in current directory:"
        ls -la
        exit 1
    fi

    # Verify the specific model file exists if using custom model
    if [ "${meta.basecaller_mode}" != "NA" ]; then
        MODEL_PATH="${model_dir_abs}/${model_name}_model_pt.tar.gz"

        if [ -f "\$MODEL_PATH" ]; then
            echo "✓ Model found at: \$MODEL_PATH"
        else
            echo "Model not found. Attempting to download..."

            # Try to download the model
            wget -P "${model_dir_abs}" https://github.com/nanoporetech/medaka/raw/master/medaka/data/${model_name}_model_pt.tar.gz

            # Check if download was successful
            if [ -f "\$MODEL_PATH" ]; then
                echo "✓ Model downloaded successfully"
            else
                echo "ERROR: Failed to download model: ${model_name}"
                echo "Available models in directory:"
                ls -lah "${model_dir_abs}"
                exit 1
            fi
        fi

        echo "✓ Using custom model: \$MODEL_PATH"
    fi

    # Create output directory
    mkdir -p medaka

    # Run medaka_consensus
    medaka_consensus \\
        -t $task.cpus \\
        -i $reads \\
        -d $assembly \\
        -o medaka \\
        ${m_option} \\
        $args > medaka.log 2>&1

    # Rename and compress output
    mv medaka/consensus.fasta medaka/${prefix}.fasta
    gzip -n medaka/${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
