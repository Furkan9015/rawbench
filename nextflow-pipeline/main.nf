#!/usr/bin/env nextflow

/*
==============================================================================
RawBench Modular Nanopore Signal Analysis Pipeline
==============================================================================

A modular Nextflow pipeline for evaluating different combinations of:
1. Reference genome encoding (using different pore models)
2. Signal segmentation methods (t-test, etc.)  
3. Representation matching algorithms (hash-based, etc.)

Started by extracting components from RawHash2 for validation.
==============================================================================
*/

nextflow.enable.dsl = 2

// Import modules
include { REFERENCE_ENCODING } from './modules/reference_encoding.nf'
include { SIGNAL_SEGMENTATION } from './modules/signal_segmentation.nf'  
include { REPRESENTATION_MATCHING } from './modules/representation_matching.nf'
include { EVALUATE_RESULTS } from './modules/evaluation.nf'

// Parameter definitions
params.reference_fasta = null
params.signal_files = null
params.pore_model = 'uncalled4_r1041'
params.segmentation_method = 'ttest'
params.matching_method = 'hash'
params.output_dir = 'results'

// Pore model configurations
params.pore_models = [
    uncalled4_r1041: [
        model_file: "../rawhash2/extern/local_kmer_models/uncalled_r1041_model_only_means.txt",
        kmer_size: 9,
        level_column: 1
    ],
    ont_r1041: [
        model_file: "../rawhash2/extern/kmer_models/dna_r10.4.1_e8.2_400bps/",
        kmer_size: 9,
        level_column: 1  
    ]
]

// Apply preset configurations
if (params.preset == 'rawhash2') {
    params.pore_model = 'uncalled4_r1041'
    params.segmentation_method = 'ttest' 
    params.matching_method = 'hash'
    log.info "Applied RawHash2 preset: uncalled4_r1041 + ttest + hash"
}

workflow {
    // Input channels
    reference_ch = Channel.fromPath(params.reference_fasta, checkIfExists: true)
    signals_ch = Channel.fromPath(params.signal_files, checkIfExists: true)
    
    // Get configuration
    pore_config = params.pore_models[params.pore_model]
    
    // Stage 1: Reference genome encoding
    REFERENCE_ENCODING(reference_ch, pore_config.model_file, pore_config.kmer_size)
    
    // Stage 2: Signal segmentation
    SIGNAL_SEGMENTATION(signals_ch, params.segmentation_method)
    
    // Stage 3: Representation matching
    REPRESENTATION_MATCHING(
        REFERENCE_ENCODING.out.encoded_reference,
        SIGNAL_SEGMENTATION.out.segmented_events,
        params.matching_method
    )
    
    // Evaluation
    EVALUATE_RESULTS(REPRESENTATION_MATCHING.out.mappings)
}
