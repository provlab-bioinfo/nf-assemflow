#!/usr/bin/env python3

import argparse
import gzip
from Bio import SeqIO


def open_fasta(file_path, mode='rt'):
    """
    Open a FASTA file, supporting both uncompressed (.fasta)
    and gzipped (.fasta.gz) formats.
    mode:
      'rt' = read text
      'wt' = write text
    """
    if file_path.endswith(".gz"):
        return gzip.open(file_path, mode)
    else:
        return open(file_path, mode)


def reformat_fasta(fasta_file, output_file, runid, sort_by="length"):
    """
    Sort FASTA records, rename contigs sequentially, prepend runid,
    and preserve original headers. Supports gzipped files.
    """
    # --- Read all sequences ---
    with open_fasta(fasta_file, 'rt') as handle:
        records = list(SeqIO.parse(handle, "fasta"))

    print(f"Read {len(records)} sequences from {fasta_file}")

    # --- Sort records ---
    if sort_by == "length":
        records.sort(key=lambda r: len(r.seq), reverse=True)
    elif sort_by == "name":
        records.sort(key=lambda r: r.id)

    # --- Write reformatted sequences ---
    count = 0
    with open_fasta(output_file, 'wt') as out_f:
        for i, record in enumerate(records, start=1):
            original_desc = record.description  # the full original header
            new_contig_id = f"{runid}|Contig_{i}"

            # Update record fields
            record.id = new_contig_id
            record.name = new_contig_id
            record.description = f"{new_contig_id} /orginal_id={original_desc}"

            SeqIO.write(record, out_f, "fasta")
            count += 1

    print(f"Processed {count} sequences.")
    print(f"Output written to: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=(
            "Sort FASTA (or FASTA.GZ), rename contigs sequentially, "
            "prepend runid, and preserve original headers."
        )
    )
    parser.add_argument(
        "-f", "--fasta", required=True,
        help="Input FASTA file (.fasta or .fasta.gz)"
    )
    parser.add_argument(
        "-o", "--output", required=True,
        help="Output FASTA file (.fasta or .fasta.gz)"
    )
    parser.add_argument(
        "-r", "--runid", required=True,
        help="Run ID to prepend (e.g. 25PS-151M00028)"
    )
    parser.add_argument(
        "-s", "--sortby", choices=["length", "name"], default="length",
        help="Sort method for contigs: 'length' (default) or 'name'"
    )

    args = parser.parse_args()
    reformat_fasta(args.fasta, args.output, args.runid, args.sortby)
