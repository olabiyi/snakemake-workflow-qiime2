#!/bin/bash
#$ -S /bin/bash
#$ -N Filter_samples 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 10

set -e 

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'

#OUT_PREFIX=('05.filter_table/dada2/indoors/se' '05.filter_table/dada2/indoors/pear-joined' '05.filter_table/deblur/indoors/se' '05.filter_table/deblur/indoors/pear-joined' '05.filter_table/dada2/outdoors/se' '05.filter_table/dada2/outdoors/pear-joined' '05.filter_table/deblur/outdoors/se' '05.filter_table/deblur/outdoors/pear-joined' '05.filter_table/dada2/mock/se' '05.filter_table/dada2/mock/pear-joined' '05.filter_table/deblur/mock/se' '05.filter_table/deblur/mock/pear-joined')

#OUT_PREFIX=('05.redo_filter_table/dada2/indoors/se' '05.redo_filter_table/dada2/indoors/pear-joined' '05.redo_filter_table/dada2/indoors/pe' '05.redo_filter_table/dada2/outdoors/se' '05.redo_filter_table/dada2/outdoors/pear-joined' '05.redo_filter_table/dada2/outdoors/pe' '05.redo_filter_table/dada2/mock/se' '05.redo_filter_table/dada2/mock/pear-joined' '05.redo_filter_table/dada2/mock/pe')


OUT_PREFIX=(05.{,redo_}filter_table/dada2/{indoors,outdoors,basins}/se)


#METADATA=('00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv'  '00.mapping/mock.tsv' '00.mapping/mock.tsv' '00.mapping/mock.tsv' '00.mapping/mock.tsv')

#METADATA=('00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/pe-dada2/indoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/pe-dada2/outdoors.tsv'  '00.mapping/mock.tsv' '00.mapping/mock.tsv' '00.mapping/pe-dada2/mock.tsv')

METADATA=($(for i in {1..2}; do echo 00.mapping/{indoors,outdoors,basins}.tsv;done))

#COMBINED_TABLE=('05.filter_table/dada2/se' '05.filter_table/dada2/pear-joined' '05.filter_table/deblur/se' '05.filter_table/deblur/pear-joined' '05.filter_table/dada2/se' '05.filter_table/dada2/pear-joined' '05.filter_table/deblur/se' '05.filter_table/deblur/pear-joined' '05.filter_table/dada2/se' '05.filter_table/dada2/pear-joined' '05.filter_table/deblur/se' '05.filter_table/deblur/pear-joined')

#COMBINED_TABLE=('05.redo_filter_table/dada2/se' '05.redo_filter_table/dada2/pear-joined' '05.redo_filter_table/dada2/pe' '05.redo_filter_table/dada2/se' '05.redo_filter_table/dada2/pear-joined' '05.redo_filter_table/dada2/pe' '05.redo_filter_table/dada2/se' '05.redo_filter_table/dada2/pear-joined' '05.redo_filter_table/dada2/pe')

#{,,} means to repeat the preceeding text 3 times
COMBINED_TABLE=(05.{,redo_}filter_table/dada2/se{,,})



parallel --jobs 0 --link qiime feature-table filter-samples \
				--i-table {1}-taxa_filtered_table.qza \
				--m-metadata-file {2} \
				--o-filtered-table {3}-taxa_filtered_table.qza ::: ${COMBINED_TABLE[*]} ::: ${METADATA[*]} ::: ${OUT_PREFIX[*]}


parallel --jobs 0 --link qiime feature-table summarize \
                		--i-table {}-taxa_filtered_table.qza \
                		--o-visualization {}-taxa_filtered_table.qzv ::: ${OUT_PREFIX[*]}
