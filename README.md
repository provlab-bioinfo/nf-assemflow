# 🧬 nf-assemflow: Genome & Metagenome Assembly Pipeline (Nextflow)

**nf-assemflow** is a modular and reproducible **Nextflow pipeline** for assembling **genome** or **metagenome** data from Illumina and/or long-read sequencing technologies.  
It integrates multiple assemblers — **SPAdes**, **SKESA**, **Unicycler**, **Shovill**, and **Flye** — with optional **reorientation** and **polishing** using **DNAapler**, **Medaka**, **Polypolish**, and **PyPolca**.

---

## 🚀 Features

- Supports **genome** and **metagenome** assembly workflows  
- Handles **Illumina-only**, **long-read-only**, or **hybrid (Illumina + long-read)** data  
- Assemblers:
  - [SPAdes](https://github.com/ablab/spades)
  - [SKESA](https://github.com/ncbi/SKESA)
  - [Unicycler](https://github.com/rrwick/Unicycler)
  - [Shovill](https://github.com/tseemann/shovill)
  - [Flye](https://github.com/fenderglass/Flye)
- **Post-assembly refinement:**
  - [DNAapler](https://github.com/widdowquinn/DNAAppler) — reorient circular genomes  
  - [Medaka](https://github.com/nanoporetech/medaka) — long-read polishing  
  - [Polypolish](https://github.com/rrwick/Polypolish) — short-read polishing  
  - [PyPolca](https://github.com/alekseyzimin/py-polca) — Illumina correction  
- Containerized (Docker / Singularity)
- Scalable for local, HPC, or cloud environments  
- Integrated **MultiQC** and **QUAST** reporting  

---

## 🧩 Pipeline Overview

```mermaid
flowchart TD
    A[Input Reads (FASTQ)] --> B[QC & Trimming]
    B --> C{Assembly Mode}
    C -->|Illumina| D[SPAdes / SKESA / Shovill]
    C -->|Hybrid| E[Unicycler]
    C -->|Long-read| F[Flye]
    E --> G[DNAapler: Reorient Circular Genomes]
    F --> G
    G --> H{Polishing}
    H -->|Long-read| I[Medaka]
    H -->|Short-read| J[Polypolish + PyPolca]
    D --> K[Assembly QC & Stats]
    I --> K
    J --> K
    K --> L[Reports: MultiQC / QUAST]


# nf-assemflow
nf-assemflow is a bioinformatics nextflow pipeline that can be used to annotate the assemblied genome
## Introduction

**ABPROVLAB/assemflow** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/guidelines/graphic_design/workflow_diagrams#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run ABPROVLAB/assemflow \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

ABPROVLAB/assemflow was originally written by Xiaoli Dong.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use ABPROVLAB/assemflow for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
# nf-assemflow
