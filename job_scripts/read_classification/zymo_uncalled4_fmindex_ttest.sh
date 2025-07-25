#!/bin/bash
#SBATCH --job-name=zymo_fmindex
#SBATCH --output=../../outputs/zymo_fmindex.out
#SBATCH --error=../../outputs/zymo_fmindex.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

cd
source .bashrc

# Set variables
OUTDIR="../../outputs/zymo_fmindex"
mkdir -p ${OUTDIR}


REF="../../refs/combined_zymo_ref.fasta"

PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled4_r9.4.1.model"
FAST5="../../fast5/zymo"
# Set missing variables
PREFIX="zymo_fmindex"
PRESET="sensitive"

# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_index_${PRESET}.time" uncalled index -o "${OUTDIR}/uncalled_zymo" ${REF}

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_uncalled_map_${PRESET}.time" uncalled map -t 64 "${OUTDIR}/uncalled_zymo" ${FAST5} > "${OUTDIR}/uncalled_zymo.paf"

