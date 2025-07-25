#!/bin/bash
#SBATCH --job-name=rh2_zymo
#SBATCH --output=../../outputs/rh2_zymo.out
#SBATCH --error=../../outputs/rh2_zymo_mapping.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

cd
source .bashrc

# Set variables
OUTDIR="../../outputs/zymo_hashbased"
mkdir -p ${OUTDIR}


REF="../../refs/combined_zymo_ref.fasta"

PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled4_r9.4.1.model"
FAST5="../../fast5/zymo"

# Set missing variables
PREFIX="zymo_hashbased"
PRESET="sensitive"

# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_index_${PRESET}.time" ${PROG} -p ${PORE} -k 6 -d "${OUTDIR}/rawhash_zymo.idx" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_map_${PRESET}.time" ${PROG} -p ${PORE} -k 6 "${OUTDIR}/rawhash_zymo.idx" ${FAST5} -t 64 > "${OUTDIR}/rawhash_zymo.paf"

