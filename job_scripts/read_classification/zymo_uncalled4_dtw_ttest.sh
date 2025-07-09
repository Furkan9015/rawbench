#!/bin/bash
#SBATCH --job-name=rh2_zymo_dtw
#SBATCH --output=../../outputs/rh2_zymo_dtw.out
#SBATCH --error=../../outputs/rh2_zymo_dtw.err
#SBATCH --noes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclue=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

c
source .bashrc

# Set variables
OUTDIR="../../outputs/zymo_hashbased_dtw"
mkir -p ${OUTDIR}


REF="../../refs/combined_zymo_ref.fasta"

PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled4_r9.4.1.model"
FAST5="../../fast5/zymo"

/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_index_${PRESET}.time" ${PROG} -p ${PORE} -k 6 --store-sig - "${OUTDIR}/rawhash_zymo.idx" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_rawhash2_map_${PRESET}.time" ${PROG} -p ${PORE} -k 6 "${OUTDIR}/rawhash_zymo.idx" ${FAST5} -t 64 --dtw-evaluate-chains > "${OUTDIR}/rawhash_zymo.paf"

