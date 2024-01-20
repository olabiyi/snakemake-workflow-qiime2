#!/usr/bin/env bash

SAMPLES=($(ls -1 01.raw_data/ | grep -Ev "MANIFEST|seq" - |sort -V))

# Creating MANIFEST FILE
(echo "sample-id,absolute-filepath,direction"; for SAMPLE in ${SAMPLES[*]}; \
 do echo -ne "${SAMPLE},$PWD/01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz,forward\n${SAMPLE},$PWD/01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz,reverse\n";done) \
	> 01.raw_data/MANIFEST

# Creating the samples.tsv file"
(echo -ne "SampleID\tType\tOld_name\tNew_name\n"; \
 for SAMPLE in ${SAMPLES[*]}; \
  do echo -ne \
	"${SAMPLE}\tForward\t01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz\t01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz\n${SAMPLE}\tReverse\t01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz\t01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz\n";done) \
 > sample.tsv
