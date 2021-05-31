from os import path

rule count_sequences:
    input: expand("01.raw_data/{sample}.fastq.gz", sample=config['samples'])
    output: "sequence_stats/reads_stats.tsv"
    log: "log/count_sequences/count_sequences.log"
    threads: 10
    params:
        in_dir=lambda w, input: path.dirname(input[0])
    shell:
      "seqkit stats {params.in_dir}/*.fastq.gz > {output} "
   
