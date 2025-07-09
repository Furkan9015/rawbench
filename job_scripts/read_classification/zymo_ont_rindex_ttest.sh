#!/bin/bash
#SBATCH --job-name=sigmoni_ont_zymo
#SBATCH --output=../../outputs/sigmoni_ont_zymo.out
#SBATCH --error=../../outputs/sigmoni_ont_zymo.err
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
TIME_LOG="$(date +%Y%m%d_%H%M%S)_index_timing.log"
SPUMONI_BUILD_DIR=../../spumoni/build \
PATH=../../spumoni/build:$PATH \
/usr/bin/time -vpo "$TIME_LOG" python ../../index.py -p ref_fastas/pos_class/*.fasta -n ref_fastas/neg_class/*.fasta -b 6 --shred 100000 -o ./ --ref-prefix zymo_ont
TIME_LOG="$(date +%Y%m%d_%H%M%S)_main_timing.log"
PATH=../../spumoni/build:$PATH /usr/bin/time -vpo "$TIME_LOG" python ../../main.py -i fast5/ -r refs/zymo_ont -b 6 -t 64 -o ./ --complexity --thresh 1.6666666666333334
