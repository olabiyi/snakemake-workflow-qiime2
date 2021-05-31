#!/bin/bash
#$ -S /bin/bash
#$ -N Filter_features 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 10

set -e 

# STEPS
#1. Filter-out singletons and non-target ASVs in the combined table by setting REMOVE_RARE_FEATURES="false"
#2. Run filter-sample.sh to subset the filtered table by analysis type e.g. indoors, outdoors e.t.c.
#3. View qsv summary files for each analysis to determine the "Total number of sequences" that will be used to estimate the rare ASVs and also rarefaction depth
#3. Remove rare ASVs from the feature tables by setting REMOVE_RARE_FEATURES="true"

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'
#IN_PREFIX=('03.dada_denoise/se' '03.dada_denoise/pear-joined' '03.deblur_denoise/se' '03.deblur_denoise/pear-joined')
IN_PREFIX=('03.redo_dada_denoise/se' '03.redo_dada_denoise/pear-joined' '03.redo_dada_denoise/pe')


# For Combined table i.e the original table with indoors, outdoors and mock tables combined
#OUT_PREFIX=('05.filter_table/dada2/se' '05.filter_table/dada2/pear-joined' '05.filter_table/deblur/se' '05.filter_table/deblur/pear-joined')
#TAXONOMY_PREFIX=('04.assign_taxonomy/dada2/se' '04.assign_taxonomy/dada2/pear-joined' '04.assign_taxonomy/deblur/se' '04.assign_taxonomy/deblur/pear-joined')

TAXONOMY_PREFIX=('04.redo_assign_taxonomy/dada2/se' '04.redo_assign_taxonomy/dada2/pear-joined' '04.redo_assign_taxonomy/dada2/pe' )



#TOTAL_SEQUENCES=(994346 415117 243487 58268) multiply each number by 0.00005 to get the minimum number for filtering rare otus below
#MIN_FREQUENCY=(50 21 12 3)

# For the tables that have been split by metadata
#OUT_PREFIX=('05.filter_table/dada2/indoors/se' '05.filter_table/dada2/indoors/pear-joined' '05.filter_table/deblur/indoors/se' '05.filter_table/deblur/indoors/pear-joined' '05.filter_table/dada2/outdoors/se' '05.filter_table/dada2/outdoors/pear-joined' '05.filter_table/deblur/outdoors/se' '05.filter_table/deblur/outdoors/pear-joined' '05.filter_table/dada2/mock/se' '05.filter_table/dada2/mock/pear-joined' '05.filter_table/deblur/mock/se' '05.filter_table/deblur/mock/pear-joined')


# All filtered tables
#OUT_PREFIX=('05.redo_filter_table/dada2/indoors/se' '05.redo_filter_table/dada2/indoors/pear-joined' '05.redo_filter_table/dada2/indoors/pe' '05.redo_filter_table/dada2/outdoors/se' '05.redo_filter_table/dada2/outdoors/pear-joined' '05.redo_filter_table/dada2/outdoors/pe' '05.redo_filter_table/dada2/mock/se' '05.redo_filter_table/dada2/mock/pear-joined' '05.redo_filter_table/dada2/mock/pe' '05.redo_filter_table/dada2/se' '05.redo_filter_table/dada2/pear-joined' '05.redo_filter_table/dada2/pe')
# combined table
#OUT_PREFIX=('05.redo_filter_table/dada2/se' '05.redo_filter_table/dada2/pear-joined' '05.redo_filter_table/dada2/pe')
OUT_PREFIX=(05.{,redo_}filter_table/dada2/{indoors,outdoors,basins}/se)

#MIN_FREQUENCY=(18 7 5 1 29 10 7 2 3 4 1 1)
#MIN_FREQUENCY=(26 14 9 41 22 8 4 4 1 71 40 18)

MIN_FREQUENCY=(4 25 14 5 36 21)

REMOVE_RARE_FEATURES="true"

function filter_table(){
	
	local in_prefix=$1
	local out_prefix=$2
	local taxonomy_prefix=$3

	# Remove singletons
	qiime feature-table filter-features \
			--i-table ${in_prefix}-table.qza \
			--p-min-frequency 2 \
			--o-filtered-table ${out_prefix}-noSingleton_filtered_table.qza

	qiime feature-table summarize \
			--i-table ${out_prefix}-noSingleton_filtered_table.qza \
			--o-visualization ${out_prefix}-noSingleton_filtered_table.qzv


	# Remove unassigned, archaea, eukaryota, chloroplast and mitochondria taxa
	qiime taxa filter-table \
		--i-table ${out_prefix}-noSingleton_filtered_table.qza \
		--i-taxonomy ${taxonomy_prefix}-taxonomy.qza \
		--p-exclude "Unassigned,Chloroplast,Mitochondria,Archaea,Eukaryota" \
		--o-filtered-table ${out_prefix}-taxa_filtered_table.qza

	# To figure out the total number of sequences ("Total freqency") here equals ${TOTAL_SEQUENCES} e.g. 8,053,326
	qiime feature-table summarize \
		--i-table ${out_prefix}-taxa_filtered_table.qza \
		--o-visualization ${out_prefix}-taxa_filtered_table.qzv

}

if [ "${REMOVE_RARE_FEATURES}" == "false" ]; then
	# Filter-out singletons and non-target ASVs from the combined table
	export -f filter_table
	parallel  --jobs 0 --link filter_table {1} {2} {3} ::: ${IN_PREFIX[*]} ::: ${OUT_PREFIX[*]} ::: ${TAXONOMY_PREFIX[*]}

else
	##### Removing rare otus / features with abundance less the 0.005%
	parallel --jobs 0 --link qiime feature-table filter-features \
  				--i-table {1}-taxa_filtered_table.qza \
  				--p-min-frequency {2} \
  				--o-filtered-table {1}-filtered_table.qza ::: ${OUT_PREFIX[*]} ::: ${MIN_FREQUENCY[*]}

	parallel --jobs 0 --link qiime feature-table summarize \
                --i-table {}-filtered_table.qza \
                --o-visualization {}-filtered_table.qzv ::: ${OUT_PREFIX[*]}

fi
