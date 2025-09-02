#!/bin/bash
#SBATCH --job-name=basecall_hsapiens
#SBATCH --output=../../outputs/%x_%j.out
#SBATCH --error=../../outputs/%x_%j.err
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1  
#SBATCH --partition=gpu_part
#SBATCH --time=3-00:00:00
#SBATCH --exclude=fury0

cd 
source .bashrc

cd rawbench/job_scripts/basecalling

# Set required variables
JOB_NAME="${SLURM_JOB_NAME}"
TARGET_DIR="../../basecalled_reads/"
DORADO_PATH="../../bin/dorado"
MODEL_PATH="../../basecalling_models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
INPUT_FILE="../../pod5/hsapiens.pod5"

# Set output BAM file and timing log
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BAM_FILE="${TARGET_DIR}/${JOB_NAME}_${TIMESTAMP}.bam"
TIME_LOG="${TARGET_DIR}/${JOB_NAME}_${TIMESTAMP}_timing.log"

# Run basecalling with BAM output
/usr/bin/time -vpo "$TIME_LOG" "$DORADO_PATH" basecaller -x cuda:0 "$MODEL_PATH" "$INPUT_FILE" --emit-moves > "$BAM_FILE" 
# Convert BAM to FASTQ
FASTQ_FILE="${TARGET_DIR}/${JOB_NAME}_${TIMESTAMP}.fastq"
micromamba activate bamtofastq
bamToFastq -i "$BAM_FILE" -fq "$FASTQ_FILE"