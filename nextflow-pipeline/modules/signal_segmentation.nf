// Signal Segmentation Module - Extracts RawHash2's detect_events functionality

process SIGNAL_SEGMENTATION {
    tag "$signals.baseName"
    publishDir "${params.output_dir}/signal_segmentation", mode: 'copy'

    input:
    path signals
    val segmentation_method

    output:
    path "segmented_events.txt", emit: segmented_events
    path "segmentation_log.txt", emit: log

    script:
    def seg_params = ""
    if (segmentation_method == 'ttest') {
        if (params.pore_model.contains('r1041')) {
            seg_params = "--window1 3 --window2 6 --threshold1 6.5 --threshold2 4.0 --peak-height 0.2"
        } else {
            seg_params = "--window1 9 --window2 6 --threshold1 8.5 --threshold2 4.0 --peak-height 1.4"
        }
    }
    
    """
    # Extract t-test based event detection from RawHash2's detect_events
    signal_segmenter \\
        --signals ${signals} \\
        --method ${segmentation_method} \\
        ${seg_params} \\
        --output segmented_events.txt \\
        > segmentation_log.txt 2>&1
    """
}
