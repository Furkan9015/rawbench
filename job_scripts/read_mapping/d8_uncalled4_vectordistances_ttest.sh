#!/bin/bash
#SBATCH --job-name=d8_uncalled4_vectordistances_ttest
#SBATCH --output=/home/furkane/rawbench/outputs/d8_uncalled4_vectordistances_ttest.out
#SBATCH --error=/home/furkane/rawbench/outputs/d8_uncalled4_vectordistances_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos15
#SBATCH --time=24:00:00
cd
source .bashrc
# Load any required modules or activate environment
# Example: source activate rawhash_env2
# source /home/furkane/micromamba/etc/profile.d/conda.sh
# conda activate rawhash_env2

# Set variables
OUTDIR="/home/furkane/rawbench/outputs/d8_uncalled4_vectordistances_ttest"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

REF="/mnt/batty/firtinac/rawhash_env2/rawhash2/test/data/d5_human_na12878_r94/ref.fa"

PROG="/home/furkane/sigmap/sigmap"
PORE="/home/furkane/9mer_levels_v1.txt"
FAST5="/mnt/galactica/umcconnell/rawhash2-env/rawhash2/test/data/d8_human_hg002_r1041/fast5_files_small_no_outliers"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_index_${PRESET}.time" ${PROG} -i -r ${REF} -p ${PORE} -o "${OUTDIR}/human_index"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/human_index" -s ${FAST5} -o "${OUTDIR}/human_mapping.paf" -t 64
