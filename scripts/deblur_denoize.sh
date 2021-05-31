#!/bin/bash
#$ -S /bin/bash
#$ -N denoize_deblur
#$ -q bioinfo.q
#$ -V
#$ -cwd
#$ -notify
#$ -pe shared 40

set -e

source activate qiime2-2020.6

#PREFIX="se"
#TRUNC_LENGTH=280
PREFIX="pear-joined"
TRUNC_LENGTH=400 #587

# initial quality filtering process based on quality scores
qiime quality-filter q-score \
 --i-demux 01.import/${PREFIX}-reads.qza \
 --o-filtered-sequences 03.deblur_denoise/${PREFIX}-reads-filtered.qza \
 --o-filter-stats 03.deblur_denoise/${PREFIX}-reads-filter-stats.qza

qiime metadata tabulate \
	--m-input-file 03.deblur_denoise/${PREFIX}-reads-filter-stats.qza \
 	--o-visualization 03.deblur_denoise/${PREFIX}-reads-filter-stats.qzv

# Next, the Deblur workflow is applied using the qiime deblur denoise-16S method. This method requires one parameter that is used in quality filtering, --p-trim-length n which truncates the sequences at position n. In general, the Deblur developers recommend setting this value to a length where the median quality score begins to drop too low
qiime deblur denoise-16S \
  --i-demultiplexed-seqs 03.deblur_denoise/${PREFIX}-reads-filtered.qza \
  --p-trim-length ${TRUNC_LENGTH} \
  --o-representative-sequences 03.deblur_denoise/${PREFIX}-representative_sequences.qza \
  --o-table 03.deblur_denoise/${PREFIX}-table.qza \
  --p-sample-stats \
  --o-stats 03.deblur_denoise/${PREFIX}-denoise_stats.qza

qiime deblur visualize-stats \
  --i-deblur-stats 03.deblur_denoise/${PREFIX}-denoise_stats.qza \
  --o-visualization 03.deblur_denoise/${PREFIX}-denoise_stats.qzv


qiime feature-table summarize \
	--i-table 03.deblur_denoise/${PREFIX}-table.qza \
	--o-visualization 03.deblur_denoise/${PREFIX}-table_summary.qzv


qiime feature-table tabulate-seqs \
  --i-data 03.deblur_denoise/${PREFIX}-representative_sequences.qza \
  --o-visualization 03.deblur_denoise/${PREFIX}-representative_sequences.qzv
