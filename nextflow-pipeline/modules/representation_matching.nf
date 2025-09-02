// Representation Matching Module - Extracts RawHash2's hash-based matching

process REPRESENTATION_MATCHING {
    tag "matching_${encoded_reference.baseName}_${segmented_events.baseName}"
    publishDir "${params.output_dir}/representation_matching", mode: 'copy'

    input:
    path encoded_reference
    path segmented_events  
    val matching_method

    output:
    path "mappings.paf", emit: mappings
    path "matching_log.txt", emit: log

    script:
    def match_params = ""
    if (matching_method == 'hash') {
        match_params = "--events-per-hash 8 --quantization-bits 4 --signal-diff 0.4 --chain-gap-scale 1.0 --bandwidth 500"
    }
    
    """
    # Extract hash-based representation matching from RawHash2
    hash_matcher \\
        --encoded-reference ${encoded_reference} \\
        --segmented-events ${segmented_events} \\
        --method ${matching_method} \\
        ${match_params} \\
        --output mappings.paf \\
        > matching_log.txt 2>&1
    """
}
