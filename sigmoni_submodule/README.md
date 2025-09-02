# Sigmoni Tool Installation

This directory should contain the Sigmoni tool for nanopore signal analysis.

## Installation Options

### Option 1: Git Submodule (Recommended if repository is public)
```bash
# Remove this directory
rm -rf sigmoni_submodule

# Add as git submodule (replace URL with actual Sigmoni repository)
git submodule add https://github.com/YOUR_ORG/sigmoni.git sigmoni_submodule
git submodule update --init --recursive
```

### Option 2: Manual Installation
If Sigmoni is not available as a public git repository:

1. Download or clone Sigmoni source code
2. Place the following files in this directory:
   - `index.py` - Index building script
   - `main.py` - Main classification script
   - `example/` - Example data and configurations
   - Any other required source files

### Required Files Structure
```
sigmoni_submodule/
├── index.py          # Main indexing script
├── main.py           # Classification script
├── example/
│   └── zymo/         # Example data directory
└── [other source files]
```

## Dependencies

Sigmoni requires:
- Python 3.8+
- uncalled4 
- h5py
- numpy
- scipy
- SPUMONI (compiled and available in ../spumoni_submodule/build/)

Install Python dependencies using conda/mamba:
```bash
micromamba create -n sigmoni python=3.8
micromamba activate sigmoni  
micromamba install h5py numpy scipy
pip install uncalled4
```
