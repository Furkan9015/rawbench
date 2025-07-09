#!/bin/bash
#SBATCH --job-name=d9_uncalled4_vectordistances_ttest
#SBATCH --output=/home/furkane/rawbench/outputs/d9_uncalled4_vectordistances_ttest.out
#SBATCH --error=/home/furkane/rawbench/outputs/d9_uncalled4_vectordistances_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos16
#SBATCH --time=24:00:00

source /mnt/galactica/furkane/.bashrc
# Load any required modules or activate environment
# Example: source activate rawhash_env2
# source /home/furkane/micromamba/etc/profile.d/conda.sh
# conda activate rawhash_env2

# Set variables
OUTDIR="/home/furkane/rawbench/outputs/d9_uncalled4_vectordistances_ttest"
mkdir -p ${OUTDIR}
PARAMS="-w 0"
PRESET="sensitive"
REF="/home/furkane/d9_ecoli_r1041/ref.fa"

PROG="/home/furkane/sigmap/sigmap"
PORE="/home/furkane/9mer_levels_v1.txt"
FAST5="/home/furkane/d9_ecoli_r1041/fast5_files"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_index_${PRESET}.time" ${PROG} -i -r ${REF} -p ${PORE} -o "${OUTDIR}/ecoli_index"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/ecoli_index" -s ${FAST5} -o "${OUTDIR}/ecoli_mapping.paf" -t 64
