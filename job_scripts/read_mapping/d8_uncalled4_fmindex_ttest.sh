#!/bin/bash
#SBATCH --job-name=d8_uncalled4_fmindex_ttest
#SBATCH --output=/home/furkane/rawbench/outputs/d8_uncalled4_fmindex_ttest.out
#SBATCH --error=/home/furkane/rawbench/outputs/d8_uncalled4_fmindex_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos17
#SBATCH --time=24:00:00

source .bashrc
# Load any required modules or activate environment
# Example: source activate rawhash_env2
# source /home/furkane/micromamba/etc/profile.d/conda.sh
# conda activate rawhash_env2

# Set variables
OUTDIR="/home/furkane/rawbench/outputs/d8_uncalled4_fmindex_ttest"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

REF="/mnt/batty/firtinac/rawhash_env2/rawhash2/test/data/d5_human_na12878_r94/ref.fa"

PROG="/mnt/batty/firtinac/rawhash_env2/rawhash2/bin/rawhash2"
PORE="/home/furkane/9mer_levels_v1.txt"
FAST5="/mnt/galactica/umcconnell/rawhash2-env/rawhash2/test/data/d8_human_hg002_r1041/fast5_files_small_no_outliers"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_index_${PRESET}.time" uncalled index -o "${OUTDIR}/Human" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_map_${PRESET}.time" uncalled map -t 64 "${OUTDIR}/Human" ${FAST5} > "${OUTDIR}/Human.paf"
