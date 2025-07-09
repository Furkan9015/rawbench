#!/bin/bash
#SBATCH --job-name=mm2_bam_hsapiens
#SBATCH --output=../../outputs/%x_%j.out
#SBATCH --error=../../outputs/%x_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --partition=cpu_part
#SBATCH --time=1-00:00:00
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]

cd
source .bashrc
micromamba activate blend

# Paths
REF="../../refs/hsapiens.fa"
READS="../../basecalled_reads/hsapiens.fastq"
OUT_BAM="../../outputs/true_mappings/hsapiens_sorted.bam"

# Align and convert to sorted BAM
minimap2 -ax map-ont -t 32 "$REF" "$READS" | \
    samtools view -@ 8 -b | \
    samtools sort -@ 8 -o "$OUT_BAM"

# Optional: index the BAM
samtools index "$OUT_BAM"

