#!/bin/bash
#SBATCH --job-name=d9_uncalled4_fmindex_ttest
#SBATCH --output=/home/furkane/rawbench/outputs/d9_uncalled4_fmindex_ttest.out
#SBATCH --error=/home/furkane/rawbench/outputs/d9_uncalled4_fmindex_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos16
#SBATCH --time=24:00:00

source .bashrc
# Load any required modules or activate environment
# Example: source activate rawhash_env2
# source /home/furkane/micromamba/etc/profile.d/conda.sh
# conda activate rawhash_env2

# Set variables
OUTDIR="/home/furkane/rawbench/outputs/d9_uncalled4_fmindex_ttest"
mkdir -p ${OUTDIR}
DATASET="d9" 
PREFIX="d9" 

# DATASET="d8_human" 
# PREFIX="d8_human" 
PARAMS="-w 0"
PRESET="sensitive"
REF="/home/furkane/d9_ecoli_r1041/ref.fa"

PROG="/mnt/batty/firtinac/rawhash_env2/rawhash2/bin/rawhash2"
PORE="/home/furkane/9mer_levels_v1.txt"
FAST5="/home/furkane/d9_ecoli_r1041/fast5_files"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_index_${PRESET}.time" uncalled index -o "${OUTDIR}/E.coli" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_map_${PRESET}.time" uncalled map -t 64 "${OUTDIR}/E.coli" ${FAST5} > "${OUTDIR}/E.coli.paf"
