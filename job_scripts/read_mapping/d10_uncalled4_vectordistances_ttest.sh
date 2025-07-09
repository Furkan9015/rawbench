#!/bin/bash
#SBATCH --job-name=d10_uncalled4_vectordistances_ttest
#SBATCH --output=../../outputs/%x_%j.out
#SBATCH --error=../../outputs/%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos19
#SBATCH --time=24:00:00

source /mnt/galactica/furkane/.bashrc

# Set variables
OUTDIR="../../outputs/d10_uncalled4_vectordistances_ttest"
mkdir -p ${OUTDIR}
PARAMS="-w 0"
PRESET="sensitive"

REF="../../refs/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fa"
PROG="../../bin/rawhash2"
PORE="../../kmer_models/uncalled4_r10.4.1.txt"
FAST5="../../fast5/dmelanogaster"

# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_index_${PRESET}.time" ${PROG} -i -r ${REF} -p ${PORE} -o "${OUTDIR}/dmelanogaster_index"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/dmelanogaster_index" -s ${FAST5} -o "${OUTDIR}/dmelanogaster_mapping.paf" -t 64
