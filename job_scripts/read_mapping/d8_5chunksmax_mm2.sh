#!/bin/bash
#SBATCH --job-name=mm2_hsapiens_5chunkmax
#SBATCH --output=../../outputs/%x_%j.out
#SBATCH --error=../../outputs/%x_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --partition=cpu_part
#SBATCH --time=1-00:00:00
#SBATCH --exclude=kratos0,kratos1,kratos3,kratos[5-13]
cd
source .bashrc
micromamba activate mm2
minimap2 -x map-ont -t 64 -o "../../outputs/true_mappings/hsapiens_5chunkmax.paf" ../../refs/hsapiens.fa ../../basecalled_reads/hsapiens.fastq
