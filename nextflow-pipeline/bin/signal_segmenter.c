/*
 * Signal Segmenter - Functional implementation using RawHash2's detect_events
 * 
 * This implements the signal segmentation stage by extracting and using
 * RawHash2's t-test based event detection functionality.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <assert.h>

// RawHash2 headers
#include "revent.h"
#include "rsig.h"
#include "rutils.h"
#include "rindex.h"

int main(int argc, char *argv[]) {
    char *signals_file = NULL;
    char *output_file = NULL;
    const char *method = "ttest";
    
    // T-test parameters
    int window_length1 = 9;
    int window_length2 = 6;
    double threshold1 = 8.5;
    double threshold2 = 4.0;
    double peak_height = 1.4;
    
    // Parse command line arguments
    static struct option long_options[] = {
        {"signals", required_argument, 0, 's'},
        {"method", required_argument, 0, 'm'},
        {"output", required_argument, 0, 'o'},
        {"window1", required_argument, 0, '1'},
        {"window2", required_argument, 0, '2'},
        {"threshold1", required_argument, 0, 't'},
        {"threshold2", required_argument, 0, 'T'},
        {"peak-height", required_argument, 0, 'p'},
        {0, 0, 0, 0}
    };
    
    int c;
    while ((c = getopt_long(argc, argv, "s:m:o:1:2:t:T:p:", long_options, NULL)) != -1) {
        switch (c) {
            case 's':
                signals_file = optarg;
                break;
            case 'm':
                method = optarg;
                break;
            case 'o':
                output_file = optarg;
                break;
            case '1':
                window_length1 = atoi(optarg);
                break;
            case '2':
                window_length2 = atoi(optarg);
                break;
            case 't':
                threshold1 = atof(optarg);
                break;
            case 'T':
                threshold2 = atof(optarg);
                break;
            case 'p':
                peak_height = atof(optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s --signals <file> --method <ttest> --output <out>\n", argv[0]);
                exit(1);
        }
    }
    
    if (!signals_file || !output_file) {
        fprintf(stderr, "Error: Both --signals and --output are required\n");
        return 1;
    }
    
    fprintf(stdout, "Signal Segmenter: Processing %s using %s method\n", signals_file, method);
    fprintf(stdout, "Parameters: w1=%d w2=%d t1=%.2f t2=%.2f peak=%.2f\n", 
            window_length1, window_length2, threshold1, threshold2, peak_height);
    
    // Open signal file using RawHash2's signal reading capability
    ri_char_v signal_files = {0, 0, NULL};
    find_sfiles(signals_file, &signal_files);
    
    if (signal_files.n == 0) {
        fprintf(stderr, "Error: No signal files found in %s\n", signals_file);
        return 1;
    }
    
    fprintf(stdout, "Found %d signal files\n", (int)signal_files.n);
    
    // Open signal files for reading
    ri_sig_file_t **sig_fps = open_sigs(signal_files.n, (const char**)signal_files.a, 1);
    if (!sig_fps) {
        fprintf(stderr, "Error: Failed to open signal files\n");
        return 1;
    }
    
    // Open output file
    FILE *out = fopen(output_file, "w");
    if (!out) {
        perror("Failed to open output file");
        return 1;
    }
    
    // Write header
    fprintf(out, "# Signal segmentation output from RawHash2 detect_events\n");
    fprintf(out, "# Signals: %s\n", signals_file);
    fprintf(out, "# Method: %s\n", method);
    fprintf(out, "# Parameters: w1=%d w2=%d t1=%.2f t2=%.2f peak=%.2f\n", 
            window_length1, window_length2, threshold1, threshold2, peak_height);
    fprintf(out, "# Files processed: %d\n", (int)signal_files.n);
    
    int total_reads = 0;
    int total_events = 0;
    
    // Process each signal file
    for (int f = 0; f < (int)signal_files.n; f++) {
        ri_sig_file_t *sfp = sig_fps[f];
        ri_sig_t sig = {0};
        
        fprintf(stdout, "Processing file %d/%d: %s\n", f+1, (int)signal_files.n, signal_files.a[f]);
        
        // Process each read in the file
        while (1) {
            ri_read_sig(sfp, &sig, 1);
            
            if (!sig.sig || sig.l_sig == 0) break;
            
            total_reads++;
            
            // Segment signals using RawHash2's detect_events with t-test
            double mean_sum = 0, std_sum = 0;
            uint32_t n_events_sum = 0, n_events = 0;
            
            float* events = detect_events(0, sig.l_sig, sig.sig, 
                                        window_length1, window_length2, 
                                        threshold1, threshold2, peak_height, 
                                        &mean_sum, &std_sum, &n_events_sum, &n_events);
            
            if (events && n_events > 0) {
                fprintf(out, ">%s\n", sig.name ? sig.name : "unknown");
                fprintf(out, "E\t%u", n_events);
                for (uint32_t i = 0; i < n_events; i++) {
                    fprintf(out, "\t%.6f", events[i]);
                }
                fprintf(out, "\n");
                
                total_events += n_events;
                free(events);
            }
            
            // Free signal memory
            if (sig.sig) { free(sig.sig); sig.sig = NULL; }
            if (sig.name) { free(sig.name); sig.name = NULL; }
            
            if (total_reads % 1000 == 0) {
                fprintf(stderr, "Processed %d reads, %d total events\n", total_reads, total_events);
            }
        }
        
        // Close signal file
        ri_sig_close(sfp);
    }
    
    // Cleanup
    fclose(out);
    free(sig_fps);
    
    // Free signal file names
    for (int i = 0; i < (int)signal_files.n; i++) {
        free(signal_files.a[i]);
    }
    free(signal_files.a);
    
    fprintf(stdout, "Signal segmentation completed: %d reads processed, %d events detected, output: %s\n", 
            total_reads, total_events, output_file);
    return 0;
}
