#!/bin/bash
#SBATCH --job-name=mm2_dmelanogaster_1chunkmax
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
minimap2 -x map-ont -t 64 -o "../../outputs/true_mappings/dmelanogaster_1chunkmax.paf" ../../refs/dmelanogaster.fa ../../basecalled_reads/dmelanogaster.fastq
