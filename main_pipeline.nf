// Pipeline para análise de dados de sequenciamento de RNA por shotgun

process trim_fastp {
    conda "envs/environment.yml"

    input:
    path input

    output:
    path "fastp_results"

    publishDir "./Results/", mode: 'copy'

    script:
    """
    mkdir -p Results
    mkdir -p fastp_results
    fastp -i ${input[0]} -I ${input[1]} -o fastp_results/clean_R1.fastq -O fastp_results/clean_R2.fastq --detect_adapter_for_pe --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 --length_required 50 --trim_front1 10 --trim_front2 10
    """
}

process quality_check_fastqc {
    conda "envs/environment.yml"

    input:
    path fastp_results

    output:
    path "fastqc_results"

    publishDir "./Results/", mode: 'copy'

    script:
    """
    mkdir -p fastqc_results
    fastqc ${fastp_results}/*.fastq -o fastqc_results
    """
}

process report_multiqc {
    conda "envs/environment.yml"

    input:
    path fastqc_results

    output:
    path "multiqc_report.html"

    publishDir "./Results/multiqc_results", mode: 'copy'

    script:
    """
    multiqc $fastqc_results -o .
    """
}

process assembly_megahit {
    conda "envs/environment.yml"

    input:
    path input

    output:
    path "megahit_results"

    publishDir "./Results/", mode: 'copy'

    script:
    """
    megahit -1 ${input[0]} -2 ${input[1]} -o megahit_results --mem-flag 0 -t 12 --k-min 21 --k-max 23 --k-step 2
    """
}

process orf_prediction_pyrodigal {
    conda "envs/environment.yml"

    input:
    path megahit_results

    output:
    path "pyrodigal_results"

    publishDir "./Results/pyrodigal_results", mode: 'copy'

    script:
    """
    mkdir -p pyrodigal_results
    pyrodigal -i ${megahit_results}/final.contigs.fa -a pyrodigal_results/proteins.faa --min-gene 30 --max-overlap 30 -p meta
    """
}

process peptide_prediction_anticp {
    conda "envs/environment_anticp.yml"

    input:
    path pyrodigal_results

    output:
    path "anticp_results"

    publishDir "./Results/", mode: 'copy'

    script:
    """
    mkdir -p anticp_results
    anticp2 -i ${pyrodigal_results}/proteins.faa -o anticp_results/anticodon.csv
    """
}

workflow {
    input = file("${params.input}/*.fastq")

    // Processos
    trim_fastp(input)
    quality_check_fastqc(trim_fastp.out)
    report_multiqc(quality_check_fastqc.out)
    assembly_megahit(input)
    orf_prediction_pyrodigal(assembly_megahit.out)
    peptide_prediction_anticp(orf_prediction_pyrodigal.out)
}