#!/usr/bin/env python3
import argparse
import subprocess
import os
import sys
from pathlib import Path

def get_script_dir():
    script_path = Path(os.path.realpath(__file__))
    return script_path.parent

def run_pipeline(input_dir, output_dir, k_min=21, k_max=25, threads=12):
    if output_dir is None:
        output_dir = os.path.join(input_dir, "output")
    
    script_dir = get_script_dir()
    pipeline_path = script_dir.parent / "main_pipeline.nf"
    
    if not pipeline_path.exists():
        print(f"Error: Pipeline file not found at {pipeline_path}", file=sys.stderr)
        sys.exit(1)

    command = [
        "nextflow", "run", str(pipeline_path),
        "--input", input_dir,
        "--output", output_dir,
        "--k_min", str(k_min),
        "--k_max", str(k_max),
        "--threads", str(threads),
        "-resume"
    ]
    subprocess.run(command)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PeptoMine: Pipeline for therapeutic peptide discovery")
    parser.add_argument("-i", "--input", required=True, help="Directory containing FASTQ files")
    parser.add_argument("-o", "--output", help="Output directory")
    parser.add_argument("--k_min", type=int, default=21, help="Minimum k-mer size (default: 21)")
    parser.add_argument("--k_max", type=int, default=25, help="Maximum k-mer size (default: 25)")
    parser.add_argument("-t", "--threads", type=int, default=8, help="Number of threads (default: 12)")
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.input):
        print(f"Error: Input directory not found: {args.input}", file=sys.stderr)
        sys.exit(1)
        
    run_pipeline(args.input, args.output, args.k_min, args.k_max, args.threads)