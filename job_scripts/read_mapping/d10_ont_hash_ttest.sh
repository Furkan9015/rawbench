#!/bin/bash
#SBATCH --job-name=d10_ont_hash_ttest
#SBATCH --output=../../outputs/d10_ont_hash_ttest.out
#SBATCH --error=../../outputs/d10_ont_hash_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

source .bashrc

# Set variables
#OUTDIR="/home/furkane/d8_uncalled4/small_res_ont"
OUTDIR="../../outputs/d10_ont_hash_ttest"
mkdir -p ${OUTDIR}
DATASET="d10" 
PREFIX="d10" 

# DATASET="d8_human" 
# PREFIX="d8_human" 
PARAMS="-w 0"
PRESET="sensitive"
REF="../../refs/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fa"
PROG="../../bin/rawhash2"
PORE="../../kmer_models/ont_r10.4.1.txt"
FAST5="../../fast5/dmelanogaster"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_index_${PRESET}_quant.time" \
${PROG} --bp-per-sec 400 --r10 -x ${PRESET} -t 64 \
-p "${PORE}" -d "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.ind" \
${PARAMS} ${REF} \
> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.out" \
2> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.err"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_map_${PRESET}_quant_map.time" \
${PROG} --bp-per-sec 400 --r10 -x ${PRESET} -t 64 \
-o "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.paf" \
${PARAMS} "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant.ind" ${FAST5} \
> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant_map.out" \
2> "${OUTDIR}/${PREFIX}_rawhash2_${PRESET}_quant_map.err"
