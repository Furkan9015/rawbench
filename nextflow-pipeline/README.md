# RawBench Modular Nanopore Signal Analysis Pipeline

A modular Nextflow pipeline for systematic evaluation of nanopore signal analysis components extracted from RawHash2.

## Overview

This pipeline provides configurable evaluation of three core components:

1. **Reference Genome Encoding** - Convert FASTA to expected signals using different pore models
2. **Signal Segmentation** - Extract events from raw signals using various methods (t-test, etc.)
3. **Representation Matching** - Match segmented events to encoded references using different algorithms

## Quick Start

### Prerequisites

- Nextflow >=22.04.0
- Java 8 or later
- GCC/G++ compilers (for building binary components)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd nextflow-pipeline

# Build binary components
cd bin
make all
cd ..

# Test pipeline
nextflow run main.nf --help
```

### Basic Usage

```bash
# Run with RawHash2-equivalent settings
nextflow run main.nf \
  --reference_fasta refs/ecoli.fa \
  --signal_files "../pod5/ecoli.pod5" \
  --preset rawhash2

# Run with custom configuration
nextflow run main.nf \
  --reference_fasta refs/hsapiens.fa \
  --signal_files "../pod5/hsapiens.pod5" \
  --pore_model uncalled4_r1041 \
  --segmentation_method ttest \
  --matching_method hash
```

### Configuration Profiles

- `standard` - Local execution with default resources
- `cluster` - SLURM cluster execution  
- `rawhash2` - Exact RawHash2 replication settings

```bash
# Run on SLURM cluster with RawHash2 settings
nextflow run main.nf -profile cluster,rawhash2 \
  --reference_fasta refs/ecoli.fa \
  --signal_files "../pod5/ecoli.pod5"
```

## Pipeline Architecture

### Components

- `REFERENCE_ENCODING` - Extracts RawHash2's `ri_seq_to_sig()` functionality
- `SIGNAL_SEGMENTATION` - Extracts RawHash2's `detect_events()` functionality  
- `REPRESENTATION_MATCHING` - Extracts RawHash2's sketching + chaining logic
- `EVALUATE_RESULTS` - Integration with RawBench evaluation framework

### Modular Design

Each component can be configured independently:

```bash
# Different pore models
--pore_model uncalled4_r1041|ont_r1041|legacy_r94

# Different segmentation methods  
--segmentation_method ttest

# Different matching algorithms
--matching_method hash
```

## Validation

The pipeline is designed to produce **identical results** to RawHash2 when using:

```bash
nextflow run main.nf --preset rawhash2 \
  --reference_fasta <ref.fa> \
  --signal_files <signals>
```

This validation ensures component extraction is correct before enabling modular evaluation.

## Output Structure

```
results/
├── reference_encoding/     # Encoded reference signals
├── signal_segmentation/    # Segmented event streams  
├── representation_matching/ # PAF mapping results
├── evaluation/            # Performance metrics
├── timeline.html          # Execution timeline
├── report.html           # Pipeline report
└── trace.txt             # Resource usage trace
```

## Integration with RawBench

The pipeline integrates with the existing RawBench evaluation framework:

- Uses RawBench environment setup (`scripts/setup_env.sh`)
- Compatible with RawBench job scripts and evaluation tools
- Outputs results in formats compatible with RawBench metrics

## Development

### Adding New Components

1. Create new module in `modules/`
2. Add binary implementation in `bin/`
3. Update `main.nf` workflow
4. Add configuration in `conf/`

### Building Components

The binary components are extracted from RawHash2 source:

- `reference_encoder.c` - From `rawhash2/src/rsig.c`
- `signal_segmenter.c` - From `rawhash2/src/revent.c`  
- `hash_matcher.cpp` - From `rawhash2/src/rsketch.c`, `rseed.c`, `rmap.cpp`

Currently implemented as placeholders - requires linking against RawHash2 library for full functionality.

## Citation

If you use this pipeline in your research, please cite:

```
[RawBench Pipeline citation to be added]
[RawHash2 citation]
```
