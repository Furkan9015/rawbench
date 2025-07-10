#!/bin/bash
#SBATCH --job-name=d8_uncalled4_vectordistances_ttest_map
#SBATCH --output=../../rawbench/outputs/d8_uncalled4_vectordistances_ttest_map.out
#SBATCH --error=../../rawbench/outputs/d8_uncalled4_vectordistances_ttest_map.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]
#SBATCH --time=24:00:00
cd
source .bashrc

# Set variables
OUTDIR="../../rawbench/outputs/d8_uncalled4_vectordistances_ttest"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

REF="../../refs/hsapiens.fa"

PROG="../../sigmap/sigmap"
PORE="../../9mer_levels_v1.txt"
FAST5="../../fast5/hsapiens"
# Indexing step

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/human_index" -s ${FAST5} -o "${OUTDIR}/human_mapping.paf" -t 64
