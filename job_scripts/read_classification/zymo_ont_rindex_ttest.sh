#!/bin/bash
#SBATCH --job-name=sigmoni_ont_zymo
#SBATCH --output=../../outputs/sigmoni_ont_zymo.out
#SBATCH --error=../../outputs/sigmoni_ont_zymo.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

cd
source .bashrc

# Load RawBench environment
cd rawbench/
source scripts/setup_env.sh

# Navigate to sigmoni example directory
cd "${SIGMONI_DIR}/example/zymo"

# Activate sigmoni conda environment
micromamba activate sigmoni

# Validate required files exist
if [[ ! -f "${SIGMONI_DIR}/index.py" ]]; then
    echo "ERROR: Sigmoni index.py not found at ${SIGMONI_DIR}/index.py" >&2
    echo "Please install Sigmoni tools according to sigmoni_submodule/README.md" >&2
    exit 1
fi

if [[ ! -x "${SPUMONI_BUILD_DIR}/spumoni" ]]; then
    echo "ERROR: SPUMONI executable not found at ${SPUMONI_BUILD_DIR}/spumoni" >&2
    echo "Please build SPUMONI according to spumoni_submodule/README.md" >&2
    exit 1
fi

# Build index
echo "Building Sigmoni index for zymo dataset..."
TIME_LOG="$(date +%Y%m%d_%H%M%S)_index_timing.log"
SPUMONI_BUILD_DIR="${SPUMONI_BUILD_DIR}" \
PATH="${SPUMONI_BUILD_DIR}:$PATH" \
/usr/bin/time -vpo "$TIME_LOG" python "${SIGMONI_DIR}/index.py" \
    -p ref_fastas/pos_class/*.fasta \
    -n ref_fastas/neg_class/*.fasta \
    -b 6 \
    --shred 100000 \
    -o ./ \
    --ref-prefix zymo_ont

# Run classification
echo "Running Sigmoni classification..."
TIME_LOG="$(date +%Y%m%d_%H%M%S)_main_timing.log"
PATH="${SPUMONI_BUILD_DIR}:$PATH" /usr/bin/time -vpo "$TIME_LOG" python "${SIGMONI_DIR}/main.py" \
    -i fast5/ \
    -r refs/zymo_ont \
    -b 6 \
    -t 64 \
    -o ./ \
    --complexity \
    --thresh 1.6666666666333334

echo "Sigmoni classification completed successfully"
