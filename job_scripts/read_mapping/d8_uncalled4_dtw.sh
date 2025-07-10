#!/bin/bash
#SBATCH --job-name=d8_uncalled4_rerun
#SBATCH --output=../../rawbench/outputs/d8_uncalled4_rerun.out
#SBATCH --error=../../rawbench/outputs/d8_uncalled4_rerun.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos13
#SBATCH --time=24:00:00
cd
source .bashrc

# Set variables
#OUTDIR="../../d8_uncalled4/small_res_ont"
OUTDIR="../../rawbench/outputs/d8_uncalled4_rerun"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

# DATASET="d8_human" 
# PREFIX="d8_human" 
PARAMS="-w 0"
PRESET="sensitive"
REF="../../refs/hsapiens.fa"
PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled_r1041_model_only_means.txt"
FAST5="../../fast5/hsapiens/"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_index_${PRESET}_quant.time" \
${PROG} --bp-per-sec 400 --r10 -x ${PRESET} -t 64 --store-sig \
-p "${PORE}" -d "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.ind" \
${PARAMS} ${REF} \
> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.out" \
2> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.err"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_map_${PRESET}_quant_map.time" \
${PROG} --bp-per-sec 400 --r10 -x ${PRESET} -t 64 --dtw-evaluate-chains \
-o "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.paf" \
${PARAMS} "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.ind" ${FAST5} \
> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant_map.out" \
2> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant_map.err"
