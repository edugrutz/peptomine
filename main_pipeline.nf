// Pipeline para análise de dados de sequenciamento de RNA por shotgun

process trim_fastp {
    conda "envs/environment.yml"

    input:
    path input

    output:
    path "fastp_results/*.fastq"

    //publishDir "${params.output}/", mode: 'copy'

    script:
    if (params.mode == 'single') 
        """
        mkdir -p fastp_results
        fastp -i ${input} -o fastp_results/clean.fastq --detect_adapter_for_pe --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 --length_required 50 --trim_front1 10
        """
    else
        """
        mkdir -p ${params.output}
        mkdir -p fastp_results
        fastp -i ${input[0]} -I ${input[1]} -o fastp_results/clean_R1.fastq -O fastp_results/clean_R2.fastq --detect_adapter_for_pe --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 --length_required 50 --trim_front1 10 --trim_front2 10
        """
}

process kraken2_classification {
    conda "envs/environment.yml"

    input:
    path fastp_results

    output:
    path "kraken2_results"

    publishDir "${params.output}/", mode: 'copy'

    script:
    if (params.mode == 'single') 
        """
        mkdir -p kraken2_results
        kraken2 --db ${params.kraken_db} --threads ${params.threads} --report kraken2_results/report.txt --output kraken2_results/output.kraken2 ${fastp_results[0]}
        """
    else
        """
        mkdir -p kraken2_results
        kraken2 --db ${params.kraken_db} --threads ${params.threads} --report kraken2_results/report.txt --output kraken2_results/output.kraken2 --paired ${fastp_results[0]} ${fastp_results[1]}
        """
}

process quality_check_fastqc {
    conda "envs/environment.yml"

    input:
    path fastp_results

    output:
    path "fastqc_results"

    publishDir "${params.output}/", mode: 'copy'

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

    publishDir "${params.output}/multiqc_results", mode: 'copy'

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
    path "./megahit_contigs.fa"

    publishDir "${params.output}/", mode: 'copy', pattern: "*.fa" 

    script:
    if (params.mode == 'single') 
        """
        megahit -r ${input} -o megahit_results --mem-flag 0 -t ${params.threads} --k-min ${params.k_min} --k-max ${params.k_max} --k-step 2
        cp megahit_results/final.contigs.fa ./megahit_contigs.fa
        """
    else
        """
        megahit -1 ${input[0]} -2 ${input[1]} -o megahit_results --mem-flag 0 -t ${params.threads} --k-min ${params.k_min} --k-max ${params.k_max} --k-step 2
        cp megahit_results/final.contigs.fa ./megahit_contigs.fa
        """
}

process orf_prediction_pyrodigal {
    conda "envs/environment.yml"

    input:
    path megahit_results

    output:
    path "./proteins.faa"

    publishDir "${params.output}/", mode: 'copy'

    script:
    """
    pyrodigal -i ${megahit_results} -a proteins.faa --min-gene 30 --max-overlap 30 -p meta
    """
}

process peptide_prediction_anticp {
    conda "envs/environment_anticp.yml"

    input:
    path pyrodigal_results

    output:
    path "./anticp.csv"

    publishDir "${params.output}/", mode: 'copy'

    script:
    """
    anticp2 -i ${pyrodigal_results} -o anticp.csv
    """
}

workflow {
    input = file("${params.input}/*.fastq")

    // Processos
    trim_fastp(input)
    //quality_check_fastqc(trim_fastp.out)
    //report_multiqc(quality_check_fastqc.out)
    if (params.use_kraken) 
        kraken2_classification(trim_fastp.out.collect{ it })
    assembly_megahit(trim_fastp.out.collect{ it })
    orf_prediction_pyrodigal(assembly_megahit.out)
    peptide_prediction_anticp(orf_prediction_pyrodigal.out)
}