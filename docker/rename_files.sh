#!/usr/bin/env bash

awk 'BEGIN{FS=","; OFS="\t"} NR>1{ gsub("s3://biodsa-sequencing-data/SEQ44XXX/SEQ44733/Reads/", "", $18); \
	gsub("s3://biodsa-sequencing-data/SEQ44XXX/SEQ44733/Reads/", "", $19); \
	print $1,$18,$19}' 00.mapping/Sample_Detail.csv > 00.mapping/reads_mapping.txt

SAMPLES=($(awk 'BEGIN{FS=OFS="\t"} {print $1}' 00.mapping/reads_mapping.txt))
FORWARD=($(awk 'BEGIN{FS=OFS="\t"} {print $2}' 00.mapping/reads_mapping.txt))
REVERSE=($(awk 'BEGIN{FS=OFS="\t"} {print $3}' 00.mapping/reads_mapping.txt))


parallel -j 10 --link \
     "[ -d 01.raw_data/{3}/ ] || mkdir 01.raw_data/{3}/ && mv 01.raw_data/{1} 01.raw_data/{3}/{3}_R1.fastq.gz && mv 01.raw_data/{2} 01.raw_data/{3}/{3}_R2.fastq.gz" \
     :::  ${FORWARD[*]} ::: ${REVERSE[*]} ::: ${SAMPLES[*]}
