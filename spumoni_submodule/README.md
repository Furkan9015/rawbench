# SPUMONI Tool Installation

This directory should contain the compiled SPUMONI tool (BWT-based r-index implementation).

## Installation Options

### Option 1: Git Submodule (Recommended if repository is public)
```bash
# Remove this directory
rm -rf spumoni_submodule

# Add as git submodule (replace URL with actual SPUMONI repository)
git submodule add https://github.com/YOUR_ORG/SPUMONI.git spumoni_submodule
git submodule update --init --recursive

# Build SPUMONI
cd spumoni_submodule
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### Option 2: Manual Installation
If SPUMONI is not available as a public git repository:

1. Download or clone SPUMONI source code
2. Place the source in this directory
3. Compile the tool:
   ```bash
   cd spumoni_submodule
   mkdir build && cd build
   cmake .. 
   make -j$(nproc)
   ```

### Required Files Structure After Build
```
spumoni_submodule/
├── build/
│   ├── spumoni        # Main executable
│   └── [other build artifacts]
├── CMakeLists.txt     # CMake configuration
└── [source files]
```

## Dependencies

SPUMONI build requirements:
- CMake 3.10+
- C++14 compatible compiler (GCC 5+, Clang 3.4+)
- Make

Install on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install cmake build-essential
```

## Verification

After installation, verify SPUMONI is working:
```bash
cd spumoni_submodule/build
./spumoni --help
```

The compiled `spumoni` executable should be available in the `build/` directory.
