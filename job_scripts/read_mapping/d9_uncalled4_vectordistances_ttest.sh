#!/bin/bash
#SBATCH --job-name=d9_uncalled4_vectordistances_ttest
#SBATCH --output=../../rawbench/outputs/d9_uncalled4_vectordistances_ttest.out
#SBATCH --error=../../rawbench/outputs/d9_uncalled4_vectordistances_ttest.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --nodelist=kratos16
#SBATCH --time=24:00:00

source /mnt/galactica/furkane/.bashrc

# Set variables
OUTDIR="../../rawbench/outputs/d9_uncalled4_vectordistances_ttest"
mkdir -p ${OUTDIR}
PARAMS="-w 0"
PRESET="sensitive"
REF="../../d9_ecoli_r1041/ref.fa"

PROG="../../sigmap/sigmap"
PORE="../../9mer_levels_v1.txt"
FAST5="../../d9_ecoli_r1041/fast5_files"
# Indexing step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_index_${PRESET}.time" ${PROG} -i -r ${REF} -p ${PORE} -o "${OUTDIR}/ecoli_index"

# Mapping step
/usr/bin/time -vpo "${OUTDIR}/${PREFIX}_sigmap_map_${PRESET}.time" ${PROG} -m -r ${REF} -p ${PORE} -x "${OUTDIR}/ecoli_index" -s ${FAST5} -o "${OUTDIR}/ecoli_mapping.paf" -t 64
