#!/bin/bash
#SBATCH --job-name=sigmoni_ont_zymo_rerun
#SBATCH --output=./sigmoni_ont_zymo_rerun.out
#SBATCH --error=./sigmoni_ont_zymo_rerun.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-10]
#SBATCH --time=24:00:00

# Change to rawbench directory
cd "$(dirname "$0")"/../../../..

# Set variables
micromamba activate sigmoni
TIME_LOG="$(date +%Y%m%d_%H%M%S)_index_timing.log"
SPUMONI_BUILD_DIR=./spumoni_submodule/build \
PATH=./spumoni_submodule/build:$PATH \
/usr/bin/time -vpo "$TIME_LOG" python sigmoni_submodule/index.py -p sigmoni/example/zymo/ref_fastas/pos_class/*.fasta -n sigmoni/example/zymo/ref_fastas/neg_class/*.fasta -b 6 --shred 100000 -o ./sigmoni/example/zymo/ --ref-prefix zymo_ont
TIME_LOG="$(date +%Y%m%d_%H%M%S)_main_timing.log"
PATH=./spumoni_submodule/build:$PATH /usr/bin/time -vpo "$TIME_LOG" python sigmoni_submodule/main.py -i sigmoni/example/zymo/fast5/ -r sigmoni/example/zymo/refs/zymo_ont -b 6 -t 64 -o ./sigmoni/example/zymo/ --complexity --thresh 1.6666666666333334
