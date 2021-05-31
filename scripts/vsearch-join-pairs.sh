#!/bin/bash
#$ -S /bin/bash
#$ -N join_vsearch 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e

source activate qiime2-2020.6

# Stitch the fowards and reverse reads together using vsearch
qiime vsearch join-pairs \
	 --i-demultiplexed-seqs 01.import/reads.qza \
	 --p-truncqual 20 \
	 --p-minlen  400 \
	 --p-maxns 20 \
	 --p-minmergelen 400 \
	 --p-maxmergelen 600 \
	 --o-joined-sequences 02.Join/vsearch-joined-reads.qza

# view the joined reads
qiime demux summarize \
  --i-data 02.Join/vsearch-joined-reads.qza \
  --o-visualization 02.QC/vsearch-joined-reads.qzv
