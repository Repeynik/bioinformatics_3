#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-SRR826444}"
THREADS="${THREADS:-4}"

REF="data/ref/ecoli.fa"
R1="data/raw/${RUN_ID}_1.fastq.gz"
R2="data/raw/${RUN_ID}_2.fastq.gz"

mkdir -p \
  results/qc \
  results/flagstat \
  results/alignment \
  results/variants \
  results/logs

echo "[1/8] FastQC"
fastqc -t "$THREADS" "$R1" "$R2" -o results/qc

echo "[2/8] Index reference with BWA"
bwa index "$REF"

echo "[3/8] Index reference with samtools faidx"
samtools faidx "$REF"

echo "[4/8] Align reads with bwa mem"
bwa mem -t "$THREADS" "$REF" "$R1" "$R2" \
  > "results/alignment/${RUN_ID}.sam"

echo "[5/8] Convert SAM to BAM"
samtools view -@ "$THREADS" -bS \
  "results/alignment/${RUN_ID}.sam" \
  > "results/alignment/${RUN_ID}.bam"

echo "[6/8] Run samtools flagstat"
samtools flagstat "results/alignment/${RUN_ID}.bam" \
  > "results/flagstat/${RUN_ID}.flagstat.txt"

MAPPED_PERCENT="$(scripts/parse_flagstat.sh "results/flagstat/${RUN_ID}.flagstat.txt")"

echo "$MAPPED_PERCENT" \
  > "results/flagstat/${RUN_ID}.mapped_percent.txt"

echo "[7/8] Check mapping quality"
if awk "BEGIN {exit !($MAPPED_PERCENT > 90)}"; then
    echo "OK" > "results/flagstat/${RUN_ID}.status.txt"
    echo "Mapping quality: OK (${MAPPED_PERCENT}%)"

    echo "[8/8] Sort BAM and call variants"
    samtools sort -@ "$THREADS" \
      -o "results/alignment/${RUN_ID}.sorted.bam" \
      "results/alignment/${RUN_ID}.bam"

    samtools index "results/alignment/${RUN_ID}.sorted.bam"

    freebayes \
      -f "$REF" \
      "results/alignment/${RUN_ID}.sorted.bam" \
      > "results/variants/${RUN_ID}.vcf"

    echo "Finished" > "results/flagstat/${RUN_ID}.finished.txt"
else
    echo "not OK" > "results/flagstat/${RUN_ID}.status.txt"
    echo "Mapping quality: not OK (${MAPPED_PERCENT}%)"
fi
