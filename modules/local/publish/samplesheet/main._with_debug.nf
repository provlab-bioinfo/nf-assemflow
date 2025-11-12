process PUBLISH_SAMPLESHEET {
    tag { "samplesheet" }
    publishDir "${params.outdir}/samplesheets", mode: 'copy'

    input:
    val assembly_list

    output:
    path "*samplesheet.csv"

    /*
     * The exec block runs Groovy directly inside Nextflow.
     * println() output will go to the terminal if you run:
     *     nextflow run main.nf -ansi-log false
     */
    exec:

    def assemblies_map = [:]
    def prefix = task.ext.prefix ?: ""
    def outdir_abs_path = file(params.outdir).toAbsolutePath().toString() + "/samplesheets"

    println "[DEBUG] Starting PUBLISH_SAMPLESHEET"
    println "[DEBUG] Output directory (absolute): ${outdir_abs_path}"
    println "[DEBUG] Received assembly list: ${assembly_list}"

    // Parse assembly list
    if (assembly_list instanceof List) {
        assembly_list.each { item ->
            println "[DEBUG] Processing item: ${item}"

            if (item instanceof List && item.size() >= 2) {
                def meta = item[0]
                def file = item[1]

                println "[DEBUG] Meta: ${meta}"
                println "[DEBUG] File: ${file}"

                if (meta?.id && file) {
                    def filename = file instanceof List
                        ? new File(file[0].toString()).getName()
                        : new File(file.toString()).getName()

                    assemblies_map[meta.id] = [ contig_file: filename]

                    println "[DEBUG] Added to assemblies_map: ${meta.id} -> ${filename}"
                } else {
                    println "[WARN] Missing meta.id or file for item: ${item}"
                }
            } else {
                println "[WARN] Unexpected item format: ${item}"
            }
        }
    } else {
        println "[WARN] assembly_list is not a List: ${assembly_list?.getClass()?.getName()}"
    }

    // Combine samples with same meta.id
    def all_samples = assemblies_map.keySet()
    println "[DEBUG] All samples found: ${all_samples}"

    def rows = ["sample,contig_file"]

    all_samples.each { sample_id ->
        def assembly_data = assemblies_map[sample_id]
        def contig_file = assembly_data?.contig_file ?: "NA"
        def output_contig_file = contig_file != 'NA' ? "${outdir_abs_path}/${contig_file}" : 'NA'

        println "[DEBUG] Row -> ${sample_id},${output_contig_file}"

        rows << "${sample_id},${output_contig_file}"
    }

    // Write samplesheet to output
    def samplesheet = task.workDir.resolve("${prefix}samplesheet.csv")
    samplesheet.text = rows.join('\n')

    println "[DEBUG] Samplesheet written to: ${samplesheet}"
}
