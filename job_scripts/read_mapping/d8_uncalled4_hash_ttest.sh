#!/bin/bash
#SBATCH --job-name=d8_uncalled4_hash_ttest
#SBATCH --output=/home/furkane/rawbench/outputs/d8_uncalled4_hash_ttest.out
#SBATCH --error=/home/furkane/rawbench/outputs/d8_uncalled4_hash_ttest.err
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
#OUTDIR="/home/furkane/d8_uncalled4/small_res_ont"
OUTDIR="/home/furkane/rawbench/outputs/d8_uncalled4_hash_ttest"
mkdir -p ${OUTDIR}
DATASET="d8" 
PREFIX="d8" 

# DATASET="d8_human" 
# PREFIX="d8_human" 
PARAMS="-w 0"
PRESET="sensitive"
REF="/mnt/galactica/umcconnell/rawhash2-env/rawhash2/test/data/d8_human_hg002_r1041/ref.fa"
#PROG="/home/furkane/rawhash2_vanilla/bin/rawhash2"
PROG="/mnt/batty/firtinac/rawhash_env2/bin/rawhash2"
PORE="/home/furkane/uncalled_r1041_model_only_means.txt"
FAST5="/mnt/galactica/umcconnell/rawhash2-env/rawhash2/test/data/d8_human_hg002_r1041/fast5_files_small_no_outliers/"
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
