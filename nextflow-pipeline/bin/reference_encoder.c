/*
 * Reference Encoder - Functional implementation using RawHash2's ri_seq_to_sig 
 * 
 * This implements the reference encoding stage by extracting and using
 * RawHash2's sequence-to-signal conversion functionality.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <assert.h>
#include <zlib.h>

// RawHash2 headers
#include "rsig.h"
#include "rutils.h"
#include "rindex.h"
#include "kseq.h"

KSEQ_INIT(gzFile, gzread)

int main(int argc, char *argv[]) {
    char *reference_file = NULL;
    char *pore_model_file = NULL;
    char *output_file = NULL;
    int kmer_size = 9;
    int level_column = 1;
    
    // Parse command line arguments
    static struct option long_options[] = {
        {"reference", required_argument, 0, 'r'},
        {"pore-model", required_argument, 0, 'p'},
        {"output", required_argument, 0, 'o'},
        {"kmer-size", required_argument, 0, 'k'},
        {"level-column", required_argument, 0, 'l'},
        {0, 0, 0, 0}
    };
    
    int c;
    while ((c = getopt_long(argc, argv, "r:p:o:k:l:", long_options, NULL)) != -1) {
        switch (c) {
            case 'r':
                reference_file = optarg;
                break;
            case 'p':
                pore_model_file = optarg;
                break;
            case 'o':
                output_file = optarg;
                break;
            case 'k':
                kmer_size = atoi(optarg);
                break;
            case 'l':
                level_column = atoi(optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s --reference <fasta> --pore-model <model> --output <out> [--kmer-size K] [--level-column L]\n", argv[0]);
                exit(1);
        }
    }
    
    if (!reference_file || !pore_model_file || !output_file) {
        fprintf(stderr, "Error: All arguments (reference, pore-model, output) are required\n");
        return 1;
    }
    
    fprintf(stdout, "Reference Encoder: Processing %s with pore model %s (k=%d, level_col=%d)\n", 
            reference_file, pore_model_file, kmer_size, level_column);
    
    // Load pore model using RawHash2's load_pore function
    ri_pore_t pore;
    memset(&pore, 0, sizeof(ri_pore_t));
    load_pore(pore_model_file, kmer_size, level_column, &pore);
    
    if (!pore.pore_vals) {
        fprintf(stderr, "Error: Failed to load pore model %s\n", pore_model_file);
        return 1;
    }
    
    fprintf(stdout, "Loaded pore model: %u k-mers, k=%d, range=[%.3f, %.3f]\n", 
            pore.n_pore_vals, pore.k, pore.min_val, pore.max_val);
    
    // Open output file
    FILE *out = fopen(output_file, "w");
    if (!out) {
        perror("Failed to open output file");
        if (pore.pore_vals) free(pore.pore_vals);
        if (pore.pore_inds) free(pore.pore_inds);
        return 1;
    }
    
    // Write header
    fprintf(out, "# Reference encoding output from RawHash2 ri_seq_to_sig\n");
    fprintf(out, "# Reference: %s\n", reference_file);
    fprintf(out, "# Pore model: %s\n", pore_model_file);
    fprintf(out, "# K-mer size: %d\n", kmer_size);
    fprintf(out, "# Level column: %d\n", level_column);
    fprintf(out, "# Pore model loaded: %u k-mers, range=[%.3f, %.3f]\n", 
            pore.n_pore_vals, pore.min_val, pore.max_val);
    
    // Read and process reference sequences
    gzFile fp = gzopen(reference_file, "r");
    if (!fp) {
        fprintf(stderr, "Error: Failed to open reference file %s\n", reference_file);
        fclose(out);
        if (pore.pore_vals) free(pore.pore_vals);
        if (pore.pore_inds) free(pore.pore_inds);
        return 1;
    }
    
    kseq_t *seq = kseq_init(fp);
    int l;
    int seq_count = 0;
    
    while ((l = kseq_read(seq)) >= 0) {
        if ((int)seq->seq.l < kmer_size) {
            fprintf(stderr, "Warning: Sequence %s too short (len=%d, k=%d), skipping\n", 
                    seq->name.s, (int)seq->seq.l, kmer_size);
            continue;
        }
        
        fprintf(out, ">%s\n", seq->name.s);
        seq_count++;
        
        // Allocate signal buffer - maximum size is sequence length 
        float *signals = (float*)malloc(seq->seq.l * sizeof(float));
        if (!signals) {
            fprintf(stderr, "Error: Failed to allocate signal buffer\n");
            break;
        }
        
        // Encode forward strand using RawHash2's ri_seq_to_sig
        uint32_t sig_len_f;
        ri_seq_to_sig(seq->seq.s, seq->seq.l, &pore, kmer_size, 0, &sig_len_f, signals);
        
        fprintf(out, "F\t%u", sig_len_f);
        for (uint32_t i = 0; i < sig_len_f; i++) {
            fprintf(out, "\t%.6f", signals[i]);
        }
        fprintf(out, "\n");
        
        // Encode reverse strand
        uint32_t sig_len_r; 
        ri_seq_to_sig(seq->seq.s, seq->seq.l, &pore, kmer_size, 1, &sig_len_r, signals);
        
        fprintf(out, "R\t%u", sig_len_r);
        for (uint32_t i = 0; i < sig_len_r; i++) {
            fprintf(out, "\t%.6f", signals[i]);
        }
        fprintf(out, "\n");
        
        free(signals);
        
        if (seq_count % 1000 == 0) {
            fprintf(stderr, "Processed %d sequences\n", seq_count);
        }
    }
    
    // Cleanup
    kseq_destroy(seq);
    gzclose(fp);
    fclose(out);
    
    // Free pore model memory
    if (pore.pore_vals) free(pore.pore_vals);
    if (pore.pore_inds) free(pore.pore_inds);
    
    fprintf(stdout, "Reference encoding completed: %d sequences processed, output: %s\n", 
            seq_count, output_file);
    return 0;
}
