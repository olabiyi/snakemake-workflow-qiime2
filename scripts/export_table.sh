#!/usr/bin/env bash

set -eo pipefail

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'


# Dada2 Reanalysis after splitting indoor samples and dropping some outdoor samples
TAXONOMY_DIR=(04.redo_assign_taxonomy/dada2{,,})
FEATURE_TABLE_DIR=(05.redo_filter_table/dada2/{indoors,outdoors,basins}/)
PREFIX=($( for i in {1..3}; do echo 'se'; done))
OUT_DIR=(10.exports/dada2/{indoors,outdoors,basins})


##### Export feature table with taxonomy assignment in biom format
# https://forum.qiime2.org/t/exporting-and-modifying-biom-tables-e-g-adding-taxonomy-annotations/3630
 

function export_feature_table(){

	local PREFIX=$1
	local FEATURE_DIR=$2
	local OUT_DIR=$3
	local TAXONOMY_DIR=$4

	##### Creating a BIOM table with taxonomy annotations
	qiime tools export --input-path ${FEATURE_DIR}/${PREFIX}-filtered_table.qza  --output-path ${OUT_DIR}/
	# Creating a TSV BIOM table
	biom convert -i ${OUT_DIR}/feature-table.biom -o ${OUT_DIR}/feature-table.tsv --to-tsv
	# Export taxonomy
	qiime tools export --input-path ${TAXONOMY_DIR}/${PREFIX}-taxonomy.qza --output-path ${OUT_DIR}/

	#Next, we’ll need to modify the exported taxonomy file’s header before using it with BIOM software.

	# Before modifying that file, make a copy:
	cp ${OUT_DIR}/taxonomy.tsv ${OUT_DIR}/biom-taxonomy.tsv

	# Change the first line of biom-taxonomy.tsv (i.e. the header) to this:
	# Note that you’ll need to use tab characters in the header since this is a TSV file.
	#OTUID	taxonomy	confidence

	# programatsically
	(echo "#OTUID	taxonomy	confidence"; sed -e '1d' ${OUT_DIR}/biom-taxonomy.tsv) \
	> ${OUT_DIR}/tmp.tsv && rm -rf ${OUT_DIR}/biom-taxonomy.tsv && mv ${OUT_DIR}/tmp.tsv ${OUT_DIR}/biom-taxonomy.tsv 

	# Finally, add the taxonomy data to your .biom file:
	biom add-metadata \
		-i ${OUT_DIR}/feature-table.biom \
		-o ${OUT_DIR}/table-with-taxonomy.biom \
		--observation-metadata-fp ${OUT_DIR}/biom-taxonomy.tsv \
		--sc-separated taxonomy

	# Creating a TSV BIOM table
        #biom convert -i  ${OUT_DIR}/table-with-taxonomy.biom  -o  ${OUT_DIR}/table-with-taxonomy.biom.tsv --to-tsv


}


export -f export_feature_table

# Export tables
parallel --jobs 0 --link export_feature_table  {1} {2} {3} {4}  ::: ${PREFIX[*]}  ::: ${FEATURE_TABLE_DIR[*]} ::: ${OUT_DIR[*]} ::: ${TAXONOMY_DIR[*]}

#Test
#export_feature_table ${PREFIX[0]} ${FEATURE_TABLE_DIR[0]} ${OUT_DIR[0]} ${TAXONOMY_DIR[0]}
