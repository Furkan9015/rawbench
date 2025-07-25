#!/bin/bash

# RawBench Setup Script
# This script helps set up the RawBench environment

echo "Setting up RawBench environment..."

# Check if conda/micromamba is available
if command -v micromamba &> /dev/null; then
    CONDA_CMD="micromamba"
elif command -v conda &> /dev/null; then
    CONDA_CMD="conda"
else
    echo "Error: conda or micromamba not found. Please install conda or micromamba first."
    exit 1
fi

# Create sigmoni environment
echo "Creating sigmoni conda environment..."
$CONDA_CMD create --name sigmoni python=3.8 -y
$CONDA_CMD run -n sigmoni pip install uncalled4 h5py numpy scipy

# Build SPUMONI
echo "Building SPUMONI..."
cd spumoni_submodule
mkdir -p build
cd build
cmake ..
make -j$(nproc)
cd ../..

# Set environment variables
echo "Setting environment variables..."
export SPUMONI_BUILD_DIR=$(pwd)/spumoni_submodule/build
export PATH=$SPUMONI_BUILD_DIR:$PATH

echo "Setup complete!"
echo ""
echo "To use RawBench:"
echo "1. Activate the environment: $CONDA_CMD activate sigmoni"
echo "2. Set environment variables:"
echo "   export SPUMONI_BUILD_DIR=$(pwd)/spumoni_submodule/build"
echo "   export PATH=\$SPUMONI_BUILD_DIR:\$PATH"
echo "3. See README.md for usage examples"