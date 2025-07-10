#!/bin/bash
#SBATCH --job-name=sigmoni_unc4_zymo_rerun
#SBATCH --output=../../rawbench/outputs/sigmoni_unc4_zymo_rerun.out
#SBATCH --error=../../rawbench/outputs/sigmoni_unc4_zymo_rerun.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

cd
source .bashrc
cd rawbench/sigmoni/example/zymo
# Set variables
micromamba activate sigmoni
TIME_LOG="$(date +%Y%m%d_%H%M%S)_index_uncalled4_timing.log"
SPUMONI_BUILD_DIR=../../rawbench/spumoni/build \
PATH=../../rawbench/spumoni/build:$PATH \
/usr/bin/time -vpo "$TIME_LOG" python ../../index.py -p ref_fastas/pos_class/*.fasta -n ref_fastas/neg_class/*.fasta -b 6 --shred 100000 -o ./ --ref-prefix zymo_uncalled4
TIME_LOG="$(date +%Y%m%d_%H%M%S)_main_uncalled4_timing.log"
PATH=../../rawbench/spumoni/build:$PATH /usr/bin/time -vpo "$TIME_LOG" python ../../main.py -i fast5/ -r refs/zymo_test -b 6 -t 64 -o ./ --complexity --thresh 1.6666666666333334
