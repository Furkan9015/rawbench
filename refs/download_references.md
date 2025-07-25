# Reference Genome Downloads

This document provides instructions for downloading reference genomes used in RawBench benchmarking.

## Setup

```bash
# Navigate to the refs directory
cd rawbench/refs
```

## E. coli Reference Genomes

### E. coli CFT073 (Primary - used in rawhash2 benchmarks d2, d6, d9)
```bash
# Download E. coli CFT073 complete genome
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/007/445/GCA_000007445.1_ASM744v1/GCA_000007445.1_ASM744v1_genomic.fna.gz
gunzip GCA_000007445.1_ASM744v1_genomic.fna.gz
mv GCA_000007445.1_ASM744v1_genomic.fna ecoli_cft073.fasta
```

### E. coli K-12 MG1655 (Alternative)
```bash
# Download E. coli K-12 MG1655 reference genome
wget -O ecoli_k12.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/825/GCF_000005825.2_ASM582v2/GCF_000005825.2_ASM582v2_genomic.fna.gz"
gunzip ecoli_k12.fasta.gz
```

## Human Reference Genomes

### Human CHM13v2 (hs1) (Primary - used in rawhash2 benchmarks d5, d8)
```bash
# Download CHM13v2 (hs1) Human reference genome
wget https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz
gunzip hs1.fa.gz
mv hs1.fa human_chm13v2.fasta
```

### Human GRCh38/hg38 (Alternative)
```bash
# Download Human GRCh38/hg38 reference genome
wget -O hsapiens_grch38.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.fna.gz"
gunzip hsapiens_grch38.fasta.gz
```

## Additional Reference Genomes

### Drosophila melanogaster
```bash
# Download Drosophila melanogaster reference genome (BDGP6.32)
wget -O dmelanogaster.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/215/GCF_000001215.4_Release_6_plus_ISO1_MT/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.gz"
gunzip dmelanogaster.fasta.gz
```

## Verification

```bash
# Verify downloads
ls -lh *.fasta

# Check file integrity (optional)
file *.fasta
```

## Notes

- **E. coli CFT073** and **Human CHM13v2** are the primary references used in the rawhash2 benchmarking framework
- The alternative references (K-12 MG1655, GRCh38) can be used for comparison studies
- All reference files are saved with descriptive names for easy identification
- Ensure sufficient disk space before downloading (human references are several GB)