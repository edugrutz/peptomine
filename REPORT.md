# Anotações do projeto

Ideia inicial: Rodar todos os passos fora de uma pipeline, e após isso incrementar no Nextflow

## 28-04-2025
- Repositório criado
- Ambiente conda criado "conda create -n map python=3.9"
    -- map = metagenomic_anticancer_peptides
    -- versão escolhida do python por aparentemente ser mais estável
- Dados serão extraidos do NCBI SRA
- Decidi que usarei dados de solo
- Pesquisei por "metagenome AND shotgun AND soil"
- Escolhi "Whole metagenome shotgun sequencing of soil: Tricholoma matsutake-associated forest" => SRX28351067
    -- WGS = whole genome shotgun
- Instalei o sra tools para baixar a sequencia "conda install bioconda::sra-tools"
- Baixei a sequencia na pasta raw_data "fasterq-dump SRR33086926 --split-files"
    -- "--split-files" porque a sequência é PAIRED-END, gerando dois arquivos ao invés de um intercalado
- Fastqc instalado "conda install bioconda::fastqc"
    -- Vai ser usado para analisar a qualidade do sequenciamento

- Criei uma pasta fastqc_reports para isolar os arquivos gerados pelo fastqc
- Rodei o FastQC no raw_data "fastqc SRR33086926_1.fastq SRR33086926_2.fastq"
- Movi os arquivos resultantes pra fastqc_reports/raw_reports
- Criei uma pasta fastqc_reports/trimmed_reports para futuro uso
Analisando o resultado do FASTQC:
- Foram gerados 1 arquivo HTML e um ZIP para cada sequência
- Aparentemente tudo certo com a qualidade, apenas o valor de gc que está em 62%, mas pesquisando vi que pode ser normal em amostras de solo devido a alta presença de bacterias com GC alto

- Instalei o MultiQC para analisar melhor os resultados e comparar eles brutos e trimmados "conda install bioconda::multiqc"
- Rodei o MultiQC na pasta fastqc_reports/raw_reports para comparar os 2 reports do fastqc "multiqc ."
- Após analisar os reports, tudo parece estar no conforme, seguindo com um valor alto de GC
- Os dados não serão trimmados, porque aparentemente estão sem adaptadores e sem leituras de baixa qualidade

- Optei de usar o MEGAHIT para montagem do genoma
    -- Futuros testes quero testar o SPAdes
- Instalei o MEGAHIT "conda install bioconda::megahit"
- Rodei o MEGAHIT "megahit -1 SRR33086926_1.FASTQ -2 SRR33086926_2.FASTQ -o ../megahit_output"
    -- Quero testar outros parametros, como "-t (N)" para usar múltiplos núcleos da CPU
    -- "--min-count (N)" número mínimo de leituras que um contigo deve ser lido para ser considerado
- Pelas minhas contas vai demorar umas 8 horas pra rodar no pc de casa, tentarei rodar no PC do laboratório amanhã
- Crei um arquivo environment.yml para automatizar a criação do ambiente conda "conda env create -f environment.yml"

Resumo para rodar amanhã:

conda env create -f environment.yml
fasterq-dump SRR33086926 --split-files
fastqc SRR33086926_1.fastq SRR33086926_2.fastq
multiqc .
megahit -1 SRR33086926_1.FASTQ -2 SRR33086926_2.FASTQ -o ../megahit_output

## 29-04-2025
- Baixando a sequencia no laboratório
- Testar Fastp (ferramenta que prepara a sequencia)
- Tentei rodar o comando normal do MEGAHIT, deu erro out of memory
- Agora rodando com -t 12 (usar apenas 12 nucleos do processador)

## 30-04-2025
- Rodei o megahit "megahit -1 SRR33086926_1.fastq -2 SRR33086926_2.fastq -o ../megahit_output --mem-flag 0 -t 12 --k-min 21 --k-max 23 --k-step 2"
    -- "--k-min 21" == tamanho mínimo do kmer
    -- "--k-max 23" == tamanho máximo do kmer
    -- "--k-step 2" == pular de 2 em 2 o tamanho do kmer
    -- Foram usados esses parâmetros apenas para teste
- Criei o diretório megahit_result para isolar o arquivo final.contigs.fa
- Instalei o prodigal para fazer a predição de genes "conda install bioconda::prodigal" e ja adicionei no arquivo de env
- Rodei o prodigal "prodigal -i final.contigs.fa -a genes.faa -d genes.fna -o genes.gff -p meta"
    -- "-a genes.faa" proteínas preditas (formato FASTA)
    -- "-d genes.fna" genes em DNA (formato FASTA)
    -- "-o genes.gff" anotação das ORFs (formato GFF)
    -- "-p meta" modo metagenômico, usado quando o input vem de amostras ambientais (sem genoma de referência) (desativa algumas heurísticas usadas em genomas únicos)
- "cat genes.faa | head -20 > genes_sample.faa" pega as primeiras 20 linhas para teste
- Rodei o anticp "anticp2 -i genes_sample.faa -o outfile.csv outfile.csv -t 0.0"
    -- "-t 0.0" threshhold com valor 0 para teste

## 05-05-2025
- Comecei a montar a pipeline
- Criei uma pasta Pipeline para isolar os arquivos enquanto testo, nela criarei as mesmas pastas que no procedimento anterior
- Escolhi a sequência ERR14828911 por ser mais curta e agilizar os testes da pipeline
- Criei o arquivo da pipeline "main_pipeline.nf"
- A pipeline rodou sem erros
- Agora vou tentar incrementar o fastp
- Rodou certo com o fastp
- Trocando do prodigal para o pyrodigal, pois neste é possível mudar o tamanho mínimo do ORF

