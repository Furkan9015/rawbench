#!/bin/bash
#SBATCH --job-name=basecall_d10_dmelanogaster_5chunksmax
#SBATCH --output=../../d10_dmelanogaster/%x_%j.out
#SBATCH --error=../../d10_dmelanogaster/%x_%j.err
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1  
#SBATCH --partition=gpu_part
#SBATCH --time=3-00:00:00
#SBATCH --exclude=fury0

# Set required variables
TARGET_DIR="../../d10_dmelanogaster/"
DORADO_PATH="../../dorado_bin/dorado-0.9.6-linux-x64/bin/dorado"
MODEL_PATH="/mnt/batty/firtinac/rawhash_env2/dorado/dorado-0.9.6-linux-x64/bin/dna_r10.4.1_e8.2_400bps_sup@v4.1.0"
INPUT_FILE="../../d10_dmelanogaster/merged_10X_5chunksmax.pod5"

# Create output directory if not exists
mkdir -p "$TARGET_DIR"

# Timing log
TIME_LOG="$TARGET_DIR/$(date +%Y%m%d_%H%M%S)_timing.log"

# Run basecalling with timing
/usr/bin/time -vpo "$TIME_LOG" "$DORADO_PATH" basecaller -x cuda:0 "$MODEL_PATH" "$INPUT_FILE" --output-dir "$TARGET_DIR" --emit-fastq
