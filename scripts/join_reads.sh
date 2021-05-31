#!/bin/bash
#$ -S /bin/bash
#$ -N join_reads 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e

run_pear.pl -o stitched_reads/  sequence_data/*.fastq.gz 

#cleaned the folder containg the assembeled reads
rm -rf stitched_reads/*.unassembled* stitched_reads/*discarded*

# gzip to save memory
gzip stitched_reads/*.fastq
