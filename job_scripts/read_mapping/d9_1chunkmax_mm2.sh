#!/bin/bash
#SBATCH --job-name=mm2_d9_1chunkmax
#SBATCH --output=/home/furkane/d9_ecoli_r1041/d9_mm2_1chunkmax.out
#SBATCH --error=/home/furkane/d9_ecoli_r1041/d9_mm2_1chunkmax.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --partition=cpu_part
#SBATCH --time=1-00:00:00
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]
cd
source .bashrc
micromamba activate mm2
minimap2 -x map-ont -t 32 -o "/home/furkane/d9_ecoli_r1041/true_mappings_1chunkmax.paf" /home/furkane/d9_ecoli_r1041/ref.fa /home/furkane/d9_ecoli_r1041/calls_2025-06-13_T22-16-28.fastq
