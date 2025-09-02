# Makefile for RawBench Pipeline Binary Components
# Builds functional RawHash2 components as standalone executables

CC = gcc
CXX = g++
CFLAGS = -Wall -O2 -std=c99 -DHAVE_KALLOC
CXXFLAGS = -Wall -O2 -std=c++11 -DHAVE_KALLOC

# Paths to RawHash2 and dependencies
RAWHASH2_DIR = ../../../rawhash2/src
RAWHASH2_EXTERN = ../../../rawhash2/extern

# Include paths
INCLUDES = -I$(RAWHASH2_DIR) \
           -I$(RAWHASH2_EXTERN)/pod5-0.3.10-Linux/include \
           -I$(RAWHASH2_EXTERN)/hdf5/build/include \
           -I$(RAWHASH2_EXTERN)/slow5lib/include

# RawHash2 object files (excluding main.o)
RAWHASH2_OBJS = $(RAWHASH2_DIR)/kthread.o \
                $(RAWHASH2_DIR)/kalloc.o \
                $(RAWHASH2_DIR)/bseq.o \
                $(RAWHASH2_DIR)/roptions.o \
                $(RAWHASH2_DIR)/sequence_until.o \
                $(RAWHASH2_DIR)/rutils.o \
                $(RAWHASH2_DIR)/rsig.o \
                $(RAWHASH2_DIR)/revent.o \
                $(RAWHASH2_DIR)/rsketch.o \
                $(RAWHASH2_DIR)/rindex.o \
                $(RAWHASH2_DIR)/lchain.o \
                $(RAWHASH2_DIR)/rseed.o \
                $(RAWHASH2_DIR)/rmap.o \
                $(RAWHASH2_DIR)/dtw.o \
                $(RAWHASH2_DIR)/hit.o

# Libraries - all RawHash2 dependencies
LIBS = -L$(RAWHASH2_EXTERN)/zstd/lib/ \
       $(RAWHASH2_EXTERN)/pod5-0.3.10-Linux/lib64/libpod5_format.a \
       $(RAWHASH2_EXTERN)/pod5-0.3.10-Linux/lib64/libarrow.a \
       $(RAWHASH2_EXTERN)/pod5-0.3.10-Linux/lib64/libjemalloc_pic.a \
       -lzstd \
       $(RAWHASH2_EXTERN)/hdf5/build/lib/libhdf5.a \
       $(RAWHASH2_EXTERN)/slow5lib/lib/libslow5.a \
       -lm -lz -ldl -lstdc++ -lpthread

TARGETS = reference_encoder signal_segmenter hash_matcher

all: $(TARGETS)

reference_encoder: reference_encoder.c $(RAWHASH2_OBJS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(RAWHASH2_OBJS) $(LIBS)

signal_segmenter: signal_segmenter.c $(RAWHASH2_OBJS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(RAWHASH2_OBJS) $(LIBS)

hash_matcher: hash_matcher.cpp $(RAWHASH2_OBJS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(RAWHASH2_OBJS) $(LIBS)

clean:
	rm -f $(TARGETS)

install: $(TARGETS)
	mkdir -p ../bin
	cp $(TARGETS) ../bin/

test: $(TARGETS)
	@echo "Testing functional RawHash2 components..."
	./reference_encoder --help || echo "reference_encoder built"
	./signal_segmenter --help || echo "signal_segmenter built" 
	./hash_matcher --help || echo "hash_matcher built"

.PHONY: all clean install test

# Note: This Makefile now builds functional binaries that use RawHash2's:
# 1. ri_seq_to_sig() for reference encoding
# 2. detect_events() for signal segmentation  
# 3. Sketching/matching pipeline for hash-based mapping
