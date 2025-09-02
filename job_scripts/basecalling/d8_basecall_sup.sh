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

# Load RawBench environment
cd rawbench/
source scripts/setup_env.sh

cd job_scripts/basecalling

# Set required variables using environment
JOB_NAME="${SLURM_JOB_NAME}"
MODEL_NAME="dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
INPUT_FILE="${POD5_DATA_DIR}/hsapiens.pod5"
MODEL_PATH="${BASECALLING_MODELS_DIR}/${MODEL_NAME}"

# Set output BAM file and timing log
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BAM_FILE="${BASECALLED_READS_DIR}/${JOB_NAME}_${TIMESTAMP}.bam"
TIME_LOG="${BASECALLED_READS_DIR}/${JOB_NAME}_${TIMESTAMP}_timing.log"

# Validate required files exist
if [[ ! -x "${DORADO_PATH}" ]]; then
    echo "ERROR: Dorado not found at ${DORADO_PATH}" >&2
    exit 1
fi

if [[ ! -f "${MODEL_PATH}" ]] && [[ ! -d "${MODEL_PATH}" ]]; then
    echo "ERROR: Model not found at ${MODEL_PATH}" >&2
    exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "ERROR: Input POD5 file not found at ${INPUT_FILE}" >&2
    exit 1
fi

# Run basecalling with BAM output
echo "Starting basecalling with:"
echo "  Model: ${MODEL_PATH}"  
echo "  Input: ${INPUT_FILE}"
echo "  Output: ${BAM_FILE}"

/usr/bin/time -vpo "$TIME_LOG" "$DORADO_PATH" basecaller -x cuda:0 "$MODEL_PATH" "$INPUT_FILE" --emit-moves > "$BAM_FILE" 

# Convert BAM to FASTQ
FASTQ_FILE="${BASECALLED_READS_DIR}/${JOB_NAME}_${TIMESTAMP}.fastq"
echo "Converting BAM to FASTQ: ${FASTQ_FILE}"

micromamba activate bamtofastq
bamToFastq -i "$BAM_FILE" -fq "$FASTQ_FILE"

echo "Basecalling completed successfully"
