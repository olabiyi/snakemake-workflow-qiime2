#!/bin/bash
#$ -S /bin/bash
#$ -N ASV_classify 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'
export TEMPDIR='/gpfs0/bioinfo/users/obayomi/hinuman_analysis/18S_illumina/tmp/' TMPDIR='/gpfs0/bioinfo/users/obayomi/hinuman_analysis/18S_illumina/tmp/'

#IN_PREFIX=('03.dada_denoise/se' '03.dada_denoise/pear-joined' '03.deblur_denoise/se' '03.deblur_denoise/pear-joined')
IN_PREFIX=('03.redo_dada_denoise/se' '03.redo_dada_denoise/pear-joined' '03.redo_dada_denoise/pe')

#OUT_PREFIX=('04.assign_taxonomy/dada2/se' '04.assign_taxonomy/dada2/pear-joined' '04.assign_taxonomy/deblur/se' '04.assign_taxonomy/deblur/pear-joined')
OUT_PREFIX=('04.redo_assign_taxonomy/dada2/se' '04.redo_assign_taxonomy/dada2/pear-joined' '04.redo_assign_taxonomy/dada2/pe' )

# Classify representative ASV sequences against a pre-trained SILVA database with Naive Bayes
parallel --jobs 0 --link qiime feature-classifier classify-sklearn \
			--i-classifier /gpfs0/bioinfo/users/obayomi/databases/q2_database/silva-138-99-nb-classifier.qza \
			--i-reads {1}-representative_sequences.qza \
			--o-classification {2}-taxonomy.qza ::: ${IN_PREFIX[*]} :::  ${OUT_PREFIX[*]}

parallel --jobs 0  qiime metadata tabulate \
  			--m-input-file {}-taxonomy.qza \
  			--o-visualization {}-taxonomy.qzv ::: ${OUT_PREFIX[*]}
