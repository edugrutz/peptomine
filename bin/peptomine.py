#!/usr/bin/env python3
import argparse
import subprocess
import os
import sys
from pathlib import Path

def get_script_dir():
    script_path = Path(os.path.realpath(__file__))
    return script_path.parent

def run_pipeline(input_dir, output_dir, k_min=21, k_max=121, threads=4):
    os.makedirs(output_dir, exist_ok=True)
    
    script_dir = get_script_dir()
    pipeline_path = script_dir.parent / "main_pipeline.nf"
    
    if not pipeline_path.exists():
        print(f"Erro: Arquivo do pipeline não encontrado em {pipeline_path}", file=sys.stderr)
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
    parser = argparse.ArgumentParser(description="PeptoMine: Pipeline para descoberta de peptídeos anticancerígenos")
    parser.add_argument("-i", "--input", required=True, help="Diretório com arquivos FASTQ")
    parser.add_argument("-o", "--output", required=True, help="Diretório de saída")
    parser.add_argument("--k_min", type=int, default=21, help="Tamanho mínimo de k-mer (default: 21)")
    parser.add_argument("--k_max", type=int, default=121, help="Tamanho máximo de k-mer (default: 121)")
    parser.add_argument("-t", "--threads", type=int, default=4, help="Número de threads (default: 4)")
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.input):
        print(f"Erro: Diretório de entrada não encontrado: {args.input}", file=sys.stderr)
        sys.exit(1)
        
    run_pipeline(args.input, args.output, args.k_min, args.k_max, args.threads)