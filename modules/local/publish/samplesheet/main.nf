// Process to generate sample sheet
process PUBLISH_SAMPLESHEET {
    publishDir "${params.outdir}/samplesheets", mode: 'copy'

    input:
    val assembly_list

    output:
    path "*samplesheet.csv"

    exec:

    def assemblies_map = [:]
    def prefix = task.ext.prefix ?: ""
    outdir_abs_path = file(params.outdir).toAbsolutePath().toString() + "/assemblies"

    // Parse assembly list 
    if (assembly_list instanceof List) {
        assembly_list.each { item ->
            if (item instanceof List && item.size() >= 2) {
                def meta = item[0]
                def file = item[1]

                if (meta?.id && file) {
                    def filename = file instanceof List
                        ? new File(file[0].toString()).getName()
                        : new File(file.toString()).getName()

                    assemblies_map[meta.id] = [
                        contig_file: filename
                    ]
                }
            }
        }
    }

    // Combine samples with same meta.id
    def all_samples = assemblies_map.keySet()//.unique().sort()
    def rows = ["sample,contig_file"]

    all_samples.each { sample_id ->

        def assembly_data = assemblies_map[sample_id]

        def contig_file = assembly_data?.contig_file ?: "NA"

        def output_contig_file = contig_file != 'NA' ? "${outdir_abs_path}/${contig_file}" : 'NA'

        rows << "${sample_id},${output_contig_file}"
    }

    // Write samplesheet to output
    def samplesheet = task.workDir.resolve("${prefix}samplesheet.csv")
    samplesheet.text = rows.join('\n')
}
