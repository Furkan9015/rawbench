## H. sapiens

cd hsapiens
# pip install pod5
#make sure pod5 files are downloaded first
pod5 convert to_fast5 ../pod5/hsapiens/2264ba8c_afee3a87_1.0_275.pod5 --output ./
pod5 convert to_fast5 ../pod5/hsapiens/2264ba8c_afee3a87_26.0_418.pod5 --output ./
pod5 convert to_fast5 ../pod5/hsapiens/2264ba8c_afee3a87_32.0_225.pod5 --output ./
pod5 convert to_fast5 ../pod5/hsapiens/2264ba8c_afee3a87_9.0_207.pod5 --output ./

## E. coli

cd ..

URL="https://42basepairs.com/download/s3/human-pangenomics/submissions/5b73fa0e-658a-4248-b2b8-cd16155bc157--UCSC_GIAB_R1041_nanopore/Ecoli_R1041_Duplex_Control/1_3_23_R1041_Duplex_Ecoli_Control.fast5.tar"
ARCHIVE="1_3_23_R1041_Duplex_Ecoli_Control.fast5.tar"
EXTRACT_DIR="1_3_23_R1041_Duplex_Ecoli_Control"
DEST_DIR="./ecoli"
FILELIST="files_to_extract.txt"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Step 1: Download archive with resume support
echo "Downloading archive..."
wget -c "$URL" -O "$ARCHIVE"

echo "Extracting selected fast5 files..."
tar -xvf "$ARCHIVE" -T "$FILELIST"

# Step 4: Move to destination and clean up
echo "Moving files to $DEST_DIR"
find "$EXTRACT_DIR" -name "*.fast5" -exec mv {} "$DEST_DIR/" \;

echo "Cleaning up..."
rm -rf "$EXTRACT_DIR" "$FILELIST"

echo "Done. Extracted files are in $DEST_DIR"

## D. melanogaster

#!/bin/bash

BASE_URL="https://42basepairs.com/download/s3/ont-open-data/contrib/melanogaster_bkim_2023.01/flowcells/D.melanogaster.R1041.400bps/D_melanogaster_1/20221217_1251_MN20261_FAV70669_117da01a/fast5"

# Path to the cleaned filename list
FILENAME_LIST="dmelanogaster_filenames.txt"

# Output directory (optional)
OUTPUT_DIR="dmelanogaster"
mkdir -p "$OUTPUT_DIR"

# Download each file
while read -r fname; do
    url="${BASE_URL}/${fname}"
    echo "Downloading $fname"
    wget -q --show-progress -O "${OUTPUT_DIR}/${fname}" "$url"
done < "$FILENAME_LIST"


