#!/bin/bash
#SBATCH --job-name=zymo_vectordist
#SBATCH --output=../../outputs/zymo_vectordist.out
#SBATCH --error=../../outputs/zymo_vectordist.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

cd
source .bashrc

# Set variables
OUTDIR="../../outputs/zymo_vectordist"
mkdir -p ${OUTDIR}


REF="../../refs/combined_zymo_ref.fasta"

PROG="../../bin/sigmap"
PORE="../../kmer_models/uncalled4_r9.4.1.model"
FAST5="../../fast5/zymo"

/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_index_${PRESET}.time" ${PROG} -i -r ${REF} -p ${PORE} -o "${OUTDIR}/sigmap_zymo"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/sigmap_zymo" -s ${FAST5} -o "${OUTDIR}/sigmap_zymo.paf" -t 64

