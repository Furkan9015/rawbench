# RawBench Dependencies and Requirements

## Missing External Tools Required

The job scripts in this repository reference several external tools that need to be installed separately:

### 1. Basecalling Tools
- **dorado**: Referenced in `job_scripts/basecalling/*.sh`
  - Expected location: `../bin/dorado`
  - Download from: https://github.com/nanoporetech/dorado
  - Models needed: Place in `../basecalling_models/`
  - **Note**: Results were generated with Dorado read-splitting enabled by default, which splits a small portion of ultra-long reads into two

### 2. Signal Analysis Tools
- **rawhash2**: Referenced in classification scripts
  - Expected location: `../bin/rawhash2`
  - Repository: https://github.com/CMU-SAFARI/RawHash2

- **uncalled**: For FM-index based analysis
  - Install via: `pip install uncalled4`
  - Used in: `job_scripts/read_classification/zymo_uncalled4_*.sh`

### 3. Read Mapping Tools
- **minimap2**: For ONT read mapping
  - Install via conda: `conda install minimap2`
  - Used in: `job_scripts/read_mapping/*.sh`

### 4. Utility Tools
- **bamToFastq**: For BAM to FASTQ conversion
  - Install via conda: `conda install -c bioconda bamtofastq`

### 5. Data Dependencies
- **POD5 files**: Signal data files
  - Expected in: `../pod5/` directory
  - Download scripts provided in `pod5/download.sh`

- **Reference genomes**: Extended reference sets
  - `../refs/combined_zymo_ref.fasta` (for Zymo classification)
  - Available references: `refs/dmelanogaster.fa`, `refs/ecoli.fa`, `refs/hsapiens.fa`

### 6. K-mer Models
- **uncalled4_r9.4.1.model**: For signal analysis
  - Expected in: `../kmer_models/`
  - Already included: `kmer_models/uncalled4_r10.4.1.txt`

## Directory Structure Requirements

The scripts expect this directory structure:
```
rawbench/
├── bin/                    # External tool binaries (NOT INCLUDED)
│   ├── dorado
│   └── rawhash2
├── basecalling_models/     # Dorado models (NOT INCLUDED)
├── pod5/                   # POD5 signal files (NOT INCLUDED)
├── outputs/                # Output directory (created automatically)
│   └── true_mappings/
└── [existing directories]
```

## Conda Environments Expected

The scripts assume these conda environments exist:
- `sigmoni`: For Sigmoni analysis
- `mm2`: For minimap2 mapping  
- `bamtofastq`: For BAM conversion

## SLURM Configuration

All scripts are configured for SLURM job scheduler with:
- Specific partition names (`gpu_part`, `cpu_part`)
- Node exclusions (adjust for your cluster)
- Resource requirements (GPU/CPU)

## Setup Recommendations

1. **Install external tools** in `../bin/` directory
2. **Download models** to `../basecalling_models/`
3. **Download signal data** using scripts in `fast5/` and `pod5/`
4. **Create conda environments** as needed
5. **Adjust SLURM parameters** for your cluster
6. **Update paths** in scripts if needed

## Known Issues Fixed

- ✅ Typo in d8_mm2.sh (`hspaiens` → `hsapiens`)
- ✅ Missing variable definitions ($PREFIX, $PRESET)
- ✅ Created missing output directories
- ❌ External tool dependencies still need manual installation
- ❌ Missing reference files need to be obtained separately
- ❌ POD5/signal data files need to be downloaded