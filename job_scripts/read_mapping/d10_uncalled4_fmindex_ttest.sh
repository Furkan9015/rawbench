#!/bin/bash
#SBATCH --job-name=d10_uncalled4_fmindex_ttest
#SBATCH --output=../../outputs/d10_uncalled4_fmindex_ttest.out
#SBATCH --error=../../outputs/d10_uncalled4_fmindex_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos14
#SBATCH --time=24:00:00

source .bashrc

# Set variables
OUTDIR="../../outputs/d10_uncalled4_fmindex_ttest"
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
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_index_${PRESET}.time" uncalled index -o "${OUTDIR}/D.melanogaster" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_map_${PRESET}.time" uncalled map -t 64 "${OUTDIR}/D.melanogaster" ${FAST5} > "${OUTDIR}/D.melanogaster.paf"
