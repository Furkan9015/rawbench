#!/bin/bash
#SBATCH --job-name=mm2_d8_small_no_outliers
#SBATCH --output=/home/furkane/rawbench/d8_human/d8_small_mm2.out
#SBATCH --error=/home/furkane/rawbench/d8_human/d8_small_mm2.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --partition=cpu_part
#SBATCH --time=1-00:00:00
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]
cd
source .bashrc
micromamba activate mm2
minimap2 -x map-ont -t 32 -o "/home/furkane/rawbench/d8_human/true_mappings.paf" /mnt/batty/firtinac/rawhash_env2/rawhash2/test/data/d5_human_na12878_r94/ref.fa /home/furkane/rawbench/d8_human/calls_2025-05-14_T14-32-52.fastq
