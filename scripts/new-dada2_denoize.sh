#!/bin/bash
#$ -S /bin/bash
#$ -N denoize_dada2 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e

source activate qiime2-2020.6
PAIRED="false"
#PAIRED="true"
TRIM_LEFT=0
TRIM_RIGHT=0
TRUNC_LENGTH=400
#TRUNC_LENGTH=260
TRUNC_LENGTH_LEFT=297
TRUNC_LENGTH_RIGHT=290
maxE_f=4
maxE_r=7

OUT_DIR="03.redo_dada_denoise"
IMPORT_DIR="01.import"
#PREFIX="se"
#PREFIX="pe"
PREFIX="pear-joined"

if [ "${PAIRED}" != "true" ]; then
	echo "running dada single"
	# Denoise, truncate and assign ASVs
	qiime dada2 denoise-single \
  		--i-demultiplexed-seqs ${IMPORT_DIR}/${PREFIX}-reads.qza \
  		--p-trim-left ${TRIM_LEFT} \
  		--p-trunc-len ${TRUNC_LENGTH} \
		--p-max-ee ${maxE_f} \
  		--o-representative-sequences ${OUT_DIR}/${PREFIX}-representative_sequences.qza \
  		--o-table ${OUT_DIR}/${PREFIX}-table.qza \
  		--o-denoising-stats  ${OUT_DIR}/${PREFIX}-denoise_stats.qza


	qiime feature-table summarize \
		--i-table ${OUT_DIR}/${PREFIX}-table.qza \
		--o-visualization ${OUT_DIR}/${PREFIX}-table_summary.qzv


	qiime feature-table tabulate-seqs \
  		--i-data ${OUT_DIR}/${PREFIX}-representative_sequences.qza \
  		--o-visualization ${OUT_DIR}/${PREFIX}-representative_sequences.qzv



	qiime metadata tabulate \
		--m-input-file ${OUT_DIR}/${PREFIX}-denoise_stats.qza \
 		--o-visualization ${OUT_DIR}/${PREFIX}-denoise_stats.qzv

else
		echo "running dada paired"
	qiime dada2 denoise-paired \
		--i-demultiplexed-seqs 01.import/${PREFIX}-reads.qza \
		--o-table ${OUT_DIR}/${PREFIX}-table.qza \
		--o-representative-sequences ${OUT_DIR}/${PREFIX}-representative_sequences.qza \
		--o-denoising-stats ${OUT_DIR}/${PREFIX}-denoise_stats.qza \
		--p-trunc-len-f ${TRUNC_LENGTH_LEFT} \
		--p-trunc-len-r ${TRUNC_LENGTH_RIGHT} \
		--p-trim-left-f ${TRIM_LEFT} \
		--p-trim-left-r ${TRIM_RIGHT} \
		--p-max-ee-f ${maxE_f} \
		--p-max-ee-r ${maxE_r} \
		--p-n-threads 30


	# This visualization shows us the sequences per sample spread - to determine minimum number for rarefaction
	# and sequences per feature (OTU or ASV)
	qiime feature-table summarize \
		--i-table ${OUT_DIR}/${PREFIX}-table.qza \
		--o-visualization ${OUT_DIR}/${PREFIX}-table_summary.qzv


	qiime feature-table tabulate-seqs \
  		--i-data ${OUT_DIR}/${PREFIX}-representative_sequences.qza \
  		--o-visualization ${OUT_DIR}/${PREFIX}-representative_sequences.qzv


	qiime metadata tabulate \
		--m-input-file ${OUT_DIR}/${PREFIX}-denoise_stats.qza \
		--o-visualization ${OUT_DIR}/${PREFIX}-denoise_stats.qzv

fi
