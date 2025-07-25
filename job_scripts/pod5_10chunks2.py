#!/usr/bin/env python3
"""
Filter pod5 file to keep only the first 4000 signal points per read.
Requires: pip install pod5
"""

import pod5
import argparse
import sys
import numpy as np
from pathlib import Path

def filter_pod5_signals(input_file, output_file, max_points=40000):
    """
    Filter pod5 file to keep only the first max_points signal points per read.
    
    Args:
        input_file (str): Path to input pod5 file
        output_file (str): Path to output pod5 file
        max_points (int): Maximum number of signal points to keep per read
    """
    
    print(f"Reading from: {input_file}")
    print(f"Writing to: {output_file}")
    print(f"Keeping first {max_points} signal points per read")
    
    # Read from input pod5 file
    with pod5.Reader(input_file) as reader:
        # Create output pod5 file
        with pod5.Writer(output_file) as writer:
            
            total_reads = 0
            filtered_reads = 0
            
            # Process each read
            for read_record in reader.reads():
                total_reads += 1
                
                # Get the signal data
                signal = read_record.signal
                
                # Filter signal to first max_points
                if len(signal) > max_points:
                    filtered_signal = signal[:max_points]
                    filtered_reads += 1
                else:
                    filtered_signal = signal
                
                # Convert ReadRecord to Read object and modify signal
                read_obj = read_record.to_read()
                
                # Create a new Read object with the filtered signal
                filtered_read = pod5.Read(
                    read_id=read_obj.read_id,
                    pore=read_obj.pore,
                    calibration=read_obj.calibration,
                    read_number=read_obj.read_number,
                    start_sample=read_obj.start_sample,
                    median_before=read_obj.median_before,
                    end_reason=read_obj.end_reason,
                    run_info=read_obj.run_info,
                    num_minknow_events=read_obj.num_minknow_events,
                    tracked_scaling=read_obj.tracked_scaling,
                    predicted_scaling=read_obj.predicted_scaling,
                    num_reads_since_mux_change=read_obj.num_reads_since_mux_change,
                    time_since_mux_change=read_obj.time_since_mux_change,
                    signal=filtered_signal
                )
                
                # Add the filtered read to the output file
                writer.add_read(filtered_read)
                
                if total_reads % 1000 == 0:
                    print(f"Processed {total_reads} reads...")
    
    print(f"\nCompleted!")
    print(f"Total reads processed: {total_reads}")
    print(f"Reads with signals > {max_points} points: {filtered_reads}")
    print(f"Output saved to: {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Filter pod5 file to keep only the first N signal points per read"
    )
    parser.add_argument(
        "input_file", 
        help="Input pod5 file path"
    )
    parser.add_argument(
        "output_file", 
        help="Output pod5 file path"
    )
    parser.add_argument(
        "--max-points", 
        type=int, 
        default=40000,
        help="Maximum number of signal points to keep per read (default: 4000)"
    )
    
    args = parser.parse_args()
    
    # Validate input file exists
    if not Path(args.input_file).exists():
        print(f"Error: Input file '{args.input_file}' does not exist")
        sys.exit(1)
    
    # Validate output directory exists
    output_dir = Path(args.output_file).parent
    if not output_dir.exists():
        print(f"Error: Output directory '{output_dir}' does not exist")
        sys.exit(1)
    
    try:
        filter_pod5_signals(args.input_file, args.output_file, args.max_points)
    except Exception as e:
        print(f"Error processing files: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
