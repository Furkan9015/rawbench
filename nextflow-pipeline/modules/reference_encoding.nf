// Reference Encoding Module - Extracts RawHash2's ri_seq_to_sig functionality

process REFERENCE_ENCODING {
    tag "$reference.baseName"
    publishDir "${params.output_dir}/reference_encoding", mode: 'copy'

    input:
    path reference
    val model_file
    val kmer_size

    output:
    path "encoded_reference.txt", emit: encoded_reference
    path "encoding_log.txt", emit: log

    script:
    """
    # Extract reference encoding using RawHash2's ri_seq_to_sig logic
    reference_encoder \\
        --reference ${reference} \\
        --pore-model ${model_file} \\
        --kmer-size ${kmer_size} \\
        --output encoded_reference.txt \\
        > encoding_log.txt 2>&1
    """
}
