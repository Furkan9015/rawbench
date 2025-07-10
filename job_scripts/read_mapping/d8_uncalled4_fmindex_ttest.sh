#!/bin/bash
#SBATCH --job-name=d8_uncalled4_fmindex_ttest
#SBATCH --output=../../rawbench/outputs/d8_uncalled4_fmindex_ttest.out
#SBATCH --error=../../rawbench/outputs/d8_uncalled4_fmindex_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos17
#SBATCH --time=24:00:00

source .bashrc

# Set variables
OUTDIR="../../rawbench/outputs/d8_uncalled4_fmindex_ttest"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

REF="../../refs/hsapiens.fa"

PROG="../../bin/rawhash2"
PORE="../../9mer_levels_v1.txt"
FAST5="../../fast5/hsapiens"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_index_${PRESET}.time" uncalled index -o "${OUTDIR}/Human" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_map_${PRESET}.time" uncalled map -t 64 "${OUTDIR}/Human" ${FAST5} > "${OUTDIR}/Human.paf"
