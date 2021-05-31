from os import path

rule Get_sequence_length:
    input: "01.raw_data/{sample}.fastq.gz"
    output: "02.Get_sequence_length/{sample}_sequence_length.tsv"
    log: "logs/Get_sequence_length/Get_sequence_length.log"
    threads: 10
    params:
        in_dir=lambda w, input: path.dirname(input[0])
    shell:
        "bioawk -c fastx 'BEGIN{{OFS="\\t"}} {{print $name,length($seq)}}' {input} {output}" 
