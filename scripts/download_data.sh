#!/usr/bin/env bash
set -euo pipefail

RUN_ID="SRR826444"

mkdir -p data/raw data/ref results/logs

echo "[1/4] Download paired-end FASTQ from ENA"

wget -O data/raw/${RUN_ID}_1.fastq.gz \
  ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR826/SRR826444/SRR826444_1.fastq.gz

wget -O data/raw/${RUN_ID}_2.fastq.gz \
  ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR826/SRR826444/SRR826444_2.fastq.gz

echo "[2/4] Check FASTQ files"
gzip -t data/raw/${RUN_ID}_1.fastq.gz
gzip -t data/raw/${RUN_ID}_2.fastq.gz
ls -lh data/raw/${RUN_ID}_1.fastq.gz
ls -lh data/raw/${RUN_ID}_2.fastq.gz

echo "[3/4] Download E. coli reference genome"
wget -O data/ref/ecoli.fa.gz \
  https://raw.githubusercontent.com/iankorf/E.coli/main/GCF_000005845.2_ASM584v2_genomic.fna.gz

gunzip -c data/ref/ecoli.fa.gz > data/ref/ecoli.fa

gzip -t data/ref/ecoli.fa.gz
ls -lh data/ref/ecoli.fa
ls -lh data/ref/ecoli.fa.gz

echo "[4/4] Done"
