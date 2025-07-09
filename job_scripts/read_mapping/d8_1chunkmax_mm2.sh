#!/bin/bash
#SBATCH --job-name=mm2_hsapiens_1chunkmax
#SBATCH --output=../../outputs/d8_small_mm2_1chunkmax.out
#SBATCH --error=../../outputs/d8_small_mm2_1chunkmax.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=cpu_part
#SBATCH --time=1-00:00:00
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]
cd
source .bashrc
micromamba activate mm2
minimap2 -x map-ont -t 32 -o "/home/furkane/rawbench/d8_human/true_mappings_1chunkmax.paf" /mnt/batty/firtinac/rawhash_env2/rawhash2/test/data/d5_human_na12878_r94/ref.fa /home/furkane/rawbench/d8_human/calls_2025-06-13_T22-20-35.fastq
