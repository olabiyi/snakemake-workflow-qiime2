#!/usr/bin/env bash


awk 'BEGIN{FS=","; OFS="\n"} NR>1{print $18,$19}' 00.mapping/Sample_Detail.csv > files2download.txt && \
	parallel -j 20 aws s3 cp {} 01.raw_data/ :::: files2download.txt
