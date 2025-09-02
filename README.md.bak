# RawBench

A comprehensive benchmarking framework for raw nanopore signal analysis

## Overview

RawBench provides a standardized evaluation framework for comparing nanopore signal analysis tools. This repository contains:

1. **Sigmoni** - Signal-based read classification using compressed indexing (in `sigmoni_submodule/`)
2. **SPUMONI** - BWT-based r-index implementation for repetitive text matching (in `spumoni_submodule/`)
3. **Benchmarking scripts** - Evaluation scripts for various nanopore analysis tools (in `job_scripts/`)
4. **Reference data** - Genomes, basecalled reads, and k-mer models (in `refs/`, `basecalled_reads/`, `kmer_models/`)
5. **Signal data** - Fast5 and POD5 download scripts (in `fast5/`, `pod5/`)

## Quick Start

### Environment Setup

```bash
# Create conda environment for Sigmoni
conda create --name sigmoni python=3.8
conda activate sigmoni
pip install uncalled4 h5py numpy scipy

# Build SPUMONI
cd spumoni_submodule
mkdir build && cd build
cmake ..
make
export SPUMONI_BUILD_DIR=$(pwd)
cd ../..
```

### Basic Usage

#### 1. Sigmoni Index Building
```bash
cd sigmoni_submodule

# Binary classification example (positive vs negative references)
python index.py -p ../refs/pos_class/*.fasta -n ../refs/neg_class/*.fasta \
  --shred 100000 -o ./output_dir --ref-prefix reference_name

# Multi-class classification (positive references only)  
python index.py -p ../refs/*.fasta \
  --shred 100000 -o ./output_dir --ref-prefix reference_name
```

#### 2. Sigmoni Classification
```bash
# Binary classification with complexity correction
python main.py -i ../fast5/organism/ -r ./output_dir/reference_name \
  -o ./results -t 48 --complexity --sp

# Multi-class classification
python main.py -i ../fast5/organism/ -r ./output_dir/reference_name \
  -o ./results -t 48 --multi --complexity --sp
```

#### 3. SPUMONI Operations
```bash
cd spumoni_submodule

# Build index for matching statistics and pseudo-matching lengths
./build/spumoni build -r ../refs/reference.fa -M -P -m -o ./index_dir

# Run classification
./build/spumoni run -r ./index_dir -p ../basecalled_reads/reads.fa -P -c
```

## Evaluation with uncalled pafstats

The benchmarking framework uses `uncalled pafstats` for evaluation metrics:

```bash
# Annotate PAF files with evaluation metrics
uncalled pafstats -r ground_truth.paf --annotate tool_output.paf \
  > annotated_output.paf 2> throughput_metrics.txt
```

Example usage in scripts:
```bash
# For d9 dataset
uncalled pafstats -r d9_true_mappings.paf --annotate d9_rawhash2_sensitive_quant.paf \
  > d9_rawhash2_sensitive_quant_ann.paf 2> d9_rawhash2_sensitive_quant_ann.throughput

# For d10 dataset  
uncalled pafstats -r d10_true_mappings.paf --annotate d10_rawhash2_sensitive_quant.paf \
  > d10_rawhash2_sensitive_quant_ann.paf 2> d10_rawhash2_sensitive_quant_ann.throughput
```

## Repository Structure

```
rawbench/
├── README.md                 # This file
├── sigmoni_submodule/        # Sigmoni tool for signal-based classification
├── spumoni_submodule/        # SPUMONI tool for BWT-based indexing
├── job_scripts/              # Benchmarking and evaluation scripts
│   ├── basecalling/          # Basecalling benchmark scripts
│   ├── read_mapping/         # Read mapping evaluation scripts
│   ├── read_classification/  # Classification benchmark scripts
│   ├── extract_read_ids.py   # Utility for read ID extraction
│   └── pod5_*.py            # POD5 processing utilities
├── refs/                     # Reference genomes (FASTA format)
├── basecalled_reads/         # Pre-basecalled FASTQ files
├── kmer_models/             # K-mer models for nanopore chemistries
├── fast5/                   # Fast5 signal data download scripts
└── pod5/                    # POD5 signal data download scripts
```

## Data Organization

### Reference Genomes (refs/)
- `dmelanogaster.fa` - D. melanogaster reference
- `ecoli.fa` - E. coli reference  
- `hsapiens.fa` - Human reference

### Basecalled Reads (basecalled_reads/)
- `dmelanogaster.fastq` - D. melanogaster basecalled reads
- `ecoli.fastq` - E. coli basecalled reads
- `hsapiens.fastq` - Human basecalled reads

### K-mer Models (kmer_models/)
- `ont_r10.4.1.txt` - ONT R10.4.1 chemistry model
- `uncalled4_r10.4.1.txt` - UNCALLED4 compatible model

## Running Benchmarks

### Basecalling Benchmarks
```bash
cd job_scripts/basecalling
bash d8_basecall_sup.sh    # Human dataset basecalling
bash d9_basecall_sup.sh    # E. coli dataset basecalling
bash d10_basecall_sup.sh   # D. melanogaster dataset basecalling
```

### Read Mapping Benchmarks
```bash
cd job_scripts/read_mapping
bash d8_mm2.sh             # Human minimap2 mapping
bash d9_mm2.sh             # E. coli minimap2 mapping
bash d10_mm2.sh            # D. melanogaster minimap2 mapping
```

### Read Classification Benchmarks
```bash
cd job_scripts/read_classification
bash zymo_ont_rindex_ttest.sh          # ONT r-index classification
bash zymo_uncalled4_fmindex_ttest.sh   # UNCALLED4 FM-index classification
bash zymo_uncalled4_hashbased_ttest.sh # Hash-based classification
```

## Environment Variables

Set these environment variables for proper operation:

```bash
export SPUMONI_BUILD_DIR=/path/to/rawbench/spumoni_submodule/build
export PATH=$SPUMONI_BUILD_DIR:$PATH
```

## Signal Processing Pipeline

Sigmoni processes raw nanopore signals through:

1. **Signal Quantization** - Projects raw signal into discrete alphabet
2. **Binning** - Discretizes signal using configurable bins (default: 6)
3. **Reference Matching** - Exact matching against compressed r-index  
4. **Classification** - Binary or multi-class based on matching statistics

Key parameters:
- `--complexity`: Enable sequence complexity correction for complex genomes
- `--sp`: Filter sequencing stalls before classification
- `-b 6`: Use 6-bin quantization (recommended)
- `--shred 100000`: Shred references into 100kb chunks

## Output Formats

- `*.report` files: Classification results for each read
- `*.pseudo_lengths` files: PML (Pseudo-Matching Length) profiles  
- `*.paf` files: Alignment results in PAF format
- `*_ann.paf` files: Annotated PAF with evaluation metrics
- `*.throughput` files: Performance and accuracy metrics

## Citation

If you use RawBench in your research, please cite:

```
[Citation information to be added]
```

## License

[License information to be added]