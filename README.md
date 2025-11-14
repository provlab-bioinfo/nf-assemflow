# nf-assemflow

A modular and reproducible Nextflow pipeline for assembling genomes and metagenomes from Illumina and/or long-read sequencing data. nf-assemflow processes quality-controlled, host-removed reads (generated from pipelines like **[nf-qcflow](https://github.com/xiaoli-dong/nf-qcflow)**) and integrates multiple state-of-the-art assemblers with optional post-assembly refinement tools.

---

## Pipeline Summary

### Assembly Modes

- **Genome assembly** — bacterial, archaeal, viral, or eukaryotic genomes
- **Metagenome assembly** — complex microbial communities
- **Data flexibility** — Illumina-only, long-read-only, or hybrid (Illumina + long-read) workflows

### Supported Assemblers

- [SPAdes](https://github.com/ablab/spades) — versatile de Bruijn graph assembler
- [SKESA](https://github.com/ncbi/SKESA) — strategic k-mer extension assembler
- [Unicycler](https://github.com/rrwick/Unicycler) — hybrid assembly pipeline
- [Shovill](https://github.com/tseemann/shovill) — faster SPAdes wrapper
- [Flye](https://github.com/fenderglass/Flye) — long-read assembler for genomes and metagenomes

### Post-Assembly Refinement

- [DNAapler](https://github.com/gbouras13/dnaapler) — reorient circular genomes to start at *dnaA* or *repA*
- [Medaka](https://github.com/nanoporetech/medaka) — consensus and polishing for Nanopore data
- [Polypolish](https://github.com/rrwick/Polypolish) — short-read polishing for long-read assemblies
- [PyPolca](https://github.com/gbouras13/pypolca) — Python wrapper for POLCA Illumina correction

### Additional Features

- Containerized with Docker/Singularity for reproducibility
- Scalable deployment on local, HPC, or cloud environments
- Intelligent read downsampling strategies:
  - **Long reads**: rasusa or lrge for coverage-based downsampling
  - **Short reads**: bbnorm for k-mer-based normalization (Shovill uses built-in downsampling)
- Optional quality assessment with CheckM2
- Coverage and depth statistics for both Illumina and Nanopore reads

---

## Quick Start

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

### Check Workflow Options

You can clone or download nf-assemflow from GitHub to your local computer, or run the pipeline directly from GitHub. To check the pipeline command-line options:

```bash
# Running directly from GitHub without downloading or cloning
nextflow run xiaoli-dong/nf-assemflow -r <revision_number> --help

# Example with specific revision
nextflow run xiaoli-dong/nf-assemflow -r 04b8745 --help
```

### Prepare Required Samplesheet Input

The nf-assemflow pipeline requires a CSV format samplesheet containing sequence information for each sample. See below for what the samplesheet looks like:

**samplesheet.csv**

```csv
sample,fastq_1,fastq_2,long_fastq
sample1,shortreads_1.fastq.gz,shortreads_2.fastq.gz,longreads.fastq.gz
sample2,shortreads.fastq,NA,longreads.fastq.gz
sample3,NA,NA,longreads.fastq.gz
sample4,shortreads_1.fastq.gz,shortreads_2.fastq.gz,NA
```

**Samplesheet Format Requirements:**

- The first row of the CSV file is the header describing the columns
- Each row represents a unique sample to be processed; the first column is the unique sample ID
- When information for a particular column is missing, fill the column with `NA`
- The `fastq_1` and `fastq_2` columns are reserved for supplying short read sequence files
- The `long_fastq` column is reserved for supplying long read sequence files

### Run the Pipeline

```bash
nextflow run xiaoli-dong/nf-assemflow \
  -profile singularity \
  --input samplesheet.csv \
  --outdir results \
  -resume
```

**Common profiles:** `docker`, `singularity`, `podman`, `conda`, or your institute-specific profile

> [!IMPORTANT]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration **except for parameters**. See [documentation](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files) for more details.

---

## nf-assemflow Command-Line Options

### Input/Output Options

| Parameter | Type | Description |
|-----------|------|-------------|
| `--input` | string | Path to a CSV file containing sample information |
| `--outdir` | string | Output directory for results (must be an absolute path for cloud storage) |

### General Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--platform` | string | `illumina` | Sequencing platform (`illumina`, `nanopore`, or `hybrid`) |
| `--rasusa_coverage` | integer | `100` | Target coverage for long read downsampling with rasusa |

### Assembly Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--skip_short_reads_assembly` | boolean | `false` | Skip short read assembly |
| `--short_read_assembly` | string | `shovill` | Short read assembler (`shovill`, `spades`, `skesa`, or `unicycler`) |
| `--skip_nanopore_reads_assembly` | boolean | `false` | Skip Nanopore read assembly |
| `--long_read_assembly` | string | `flye` | Long read assembler (`flye` or `unicycler`) |

### Genome Reorientation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--skip_recenter_genome` | boolean | `false` | Skip genome reorientation step |
| `--recenter_method` | string | `dnaapler` | Method for reorienting circular genomes |

### Polishing Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--skip_nanopore_reads_polish` | boolean | `false` | Skip Nanopore read polishing |
| `--nanopore_reads_polisher` | string | `medaka` | Nanopore read polisher tool |
| `--medaka_models` | string | `/your_path_to/singularity_home/.medaka/data` | Path to Medaka models directory |
| `--skip_illumina_reads_polish` | boolean | `false` | Skip Illumina read polishing |
| `--skip_polypolish` | boolean | `false` | Skip Polypolish polishing step |
| `--skip_polca` | boolean | `false` | Skip POLCA polishing step |
| `--skip_pypolca` | boolean | `false` | Skip PyPolca polishing step |

### Quality Assessment Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--skip_checkm2` | boolean | `false` | Skip CheckM2 quality assessment |
| `--checkm2_db` | string | `/your_path_to/CheckM2_database/uniref100.KO.1.dmnd` | Path to CheckM2 database |

### Coverage and Depth Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--skip_depth_and_coverage_illumina` | boolean | `false` | Skip depth and coverage calculation for Illumina reads |
| `--skip_depth_and_coverage_nanopore` | boolean | `false` | Skip depth and coverage calculation for Nanopore reads |

### Help Options

| Parameter | Description |
|-----------|-------------|
| `--help` | Show help for all top-level parameters (can specify a parameter for detailed help) |
| `--help_full` | Show help for all non-hidden parameters |
| `--show_hidden` | Show hidden parameters (use with `--help` or `--help_full`) |

---

## Workflow Overview

```
Input Reads
    ↓
Read Downsampling
  • Long reads: rasusa/lrge (coverage-based)
  • Short reads: bbnorm (k-mer normalization) or Shovill built-in
    ↓
Assembly (SPAdes/SKESA/Unicycler/Shovill/Flye)
    ↓
Reorientation (DNAapler) [optional, long-read/hybrid assembly only]
    ↓
Polishing (Medaka/Polypolish/PyPolca) [optional, long-read/hybrid assembly only]
    ↓
Quality Assessment (CheckM2)
    ↓
Coverage Statistics
    ↓
Final Assembly
```

---

## Credits

nf-assemflow was originally written by Xiaoli Dong.

## Support

For issues, questions, or feature requests, please [open an issue](https://github.com/xiaoli-dong/nf-assemflow/issues) on GitHub.
