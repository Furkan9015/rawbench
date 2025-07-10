#!/bin/bash
#SBATCH --job-name=d10_uncalled4_hash_ttest
#SBATCH --output=../../outputs/d10_uncalled4_rerun.out
#SBATCH --error=../../outputs/d10_uncalled4_rerun.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos15
#SBATCH --time=24:00:00
cd
source .bashrc

# Set variables
#OUTDIR="../../d8_uncalled4/small_res_ont"
OUTDIR="../../outputs/d10_uncalled4_rerun"
mkdir -p ${OUTDIR}
DATASET="d10" 
PREFIX="d10" 

# DATASET="d8_human" 
# PREFIX="d8_human" 
PARAMS="-w 0"
PRESET="sensitive"
REF="../../refs/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fa"
PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled4_r10.4.1.txt"
FAST5="../../fast5/dmelanogaster"
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
