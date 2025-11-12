//https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8380430/
//https://peerj.com/articles/12446.pdf

include { SPADES } from '../../modules/nf-core/spades/main'
include { UNICYCLER } from '../../modules/nf-core/unicycler/main'
include { MEGAHIT } from '../../modules/nf-core/megahit/main'
include { SKESA } from '../../modules/local/skesa'
include { SHOVILL } from '../../modules/local/shovill/main'
include { ASSEMBLYSTATS } from '../../modules/local/stats/assemblystats'
include { REFORMATASSEMBLYSTATS as REFORMATASSEMBLYSTATS_ILLUMINA } from '../../modules/local/stats/reformatassemblystats'
include { CSVTK_CONCAT } from '../../modules/nf-core/csvtk/concat/main'
include { BBMAP_BBNORM } from '../../modules/nf-core/bbmap/bbnorm/main'
include { FASTA_REFORMATHEADER} from '../../modules/local/fasta/reformatheader'

workflow ASSEMBLE_ILLUMINA {

    take:
        reads
    main:
        ch_versions = Channel.empty()
        contigs = Channel.empty()
        stats = Channel.empty()
        assembly_report = Channel.empty()
        //https://help.geneious.com/hc/en-us/articles/360044626852-Best-practice-for-preprocessing-NGS-reads-in-Geneious-Prime
        BBMAP_BBNORM(reads)
        reads = BBMAP_BBNORM.out.fastq

        if ( params.illumina_reads_assembler == 'spades' ){
            reads
                .map { meta, myreads -> [ meta, myreads, [], []] }
                .set { input }
            SPADES (input, [], [])

            //get rid of zero size contig file and avoid the downstream crash
            SPADES.out.contigs
                .filter { meta, mycontigs -> mycontigs.countFasta() > 0 }
                .set { contigs }

            ch_versions = ch_versions.mix(SPADES.out.versions.first())
        }
        //default
        else if (params.illumina_reads_assembler == 'skesa' ) {
            SKESA ( reads )
            SKESA.out.contigs.filter { meta, mycontigs -> mycontigs.countFasta() > 0 }.set { contigs }
            ch_versions = ch_versions.mix(SKESA.out.versions.first())
        }
        else if (params.illumina_reads_assembler == 'unicycler' ) {
            reads.map { meta, myreads -> [ meta, myreads, [] ] }.set { input }
            UNICYCLER(input)
            UNICYCLER.out.scaffolds.filter { meta, scaffolds -> scaffolds.size() > 0 }.set { contigs }
            ch_versions = ch_versions.mix(UNICYCLER.out.versions.first())
        }
        else if (params.illumina_reads_assembler == 'megahit' ) {
            MEGAHIT ( reads )
            MEGAHIT.out.contigs.filter { meta, mycontigs -> mycontigs.countFasta() > 0 }.set { contigs }
            ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())
        }
        else if (params.illumina_reads_assembler == 'shovill' ) {
            SHOVILL ( reads )
            SHOVILL.out.contigs.filter { meta, mycontigs -> mycontigs.countFasta() > 0 }.set { contigs }
            ch_versions = ch_versions.mix(SHOVILL.out.versions.first())
        }

        FASTA_REFORMATHEADER(contigs)
        contigs = FASTA_REFORMATHEADER.out.fasta


        ASSEMBLYSTATS(contigs)
        ch_versions = ch_versions.mix(ASSEMBLYSTATS.out.versions.first())
        stats = ASSEMBLYSTATS.out.stats

        REFORMATASSEMBLYSTATS_ILLUMINA(stats)
        stats = REFORMATASSEMBLYSTATS_ILLUMINA.out.tsv
        ch_versions = ch_versions.mix(REFORMATASSEMBLYSTATS_ILLUMINA.out.versions.first())

        //assembly summary report
        CSVTK_CONCAT(
            stats.map { cfg, mystats -> mystats}.collect()
            .map { files -> tuple([id: "assembly_stats_illumina.${params.illumina_reads_assembler}"], files)},
            'tsv',
            'tsv'
        )
        assembly_report = CSVTK_CONCAT.out.csv

    emit:
        contigs
        stats
        assembly_report
        versions = ch_versions

}
