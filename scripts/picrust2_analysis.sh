#!/bin/bash
#$ -S /bin/bash
#$ -N function_analysis
#$ -q bioinfo.q
#$ -V
#$ -cwd
#$ -notify
#$ -pe shared 40


set -e

# Edit the headers of rep_set.fna to contain only OTU names
#sed -i -E 's/(>.+) .+$/\1/g' rep_set.fna

# make annotation directory
#mkdir /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/12.function_annotation/

##################### Export and rename feature tables and representative sequences from qiime2 artifact

###### copy and rename the artifacts to the function annotation directory
# Feature Tables
#cp /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/05.filter_table/dada2/se-taxa_filtered_table.qza \
#  12.function_annotation/
#mv 12.function_annotation/se-taxa_filtered_table.qza 12.function_annotation/_se-taxa_filtered_table.qza  
 
#cp /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/05.redo_filter_table/dada2/se-taxa_filtered_table.qza \
#  12.function_annotation/  
#mv 12.function_annotation/se-taxa_filtered_table.qza 12.function_annotation/redo-se-taxa_filtered_table.qza

# Representative sequences
#cp /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/03.dada_denoise/se-representative_sequences.qza \
# 12.function_annotation/ 
#mv 12.function_annotation/se-representative_sequences.qza 12.function_annotation/_se-representative_sequences.qza

#cp /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/03.redo_dada_denoise/se-representative_sequences.qza \
# 12.function_annotation/
#mv 12.function_annotation/se-representative_sequences.qza 12.function_annotation/redo-se-representative_sequences.qza

#cd  /gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/12.function_annotation/
#source activate qiime2-2020.6
#qiime tools export --input-path _se-taxa_filtered_table.qza --output-path ./
#mv feature-table.biom _se-feature-table.biom

#qiime tools export --input-path redo-se-taxa_filtered_table.qza --output-path ./
#mv feature-table.biom redo-se-feature-table.biom

#qiime tools export --input-path _se-representative_sequences.qza --output-path ./
#mv dna-sequences.fasta _se-rep_set.fna

#qiime tools export --input-path redo-se-representative_sequences.qza --output-path ./
#mv dna-sequences.fasta redo-se-rep_set.fna


source activate picrust2
PREFIX=("_se" "redo-se")
REP_SET=("rep_set.fna" "rep_set.fna")
FEATURE_TABLE=("feature-table.biom" "feature-table.biom")


function run_picrust(){

	local PREFIX=$1
	local REP_SET=$2
	local FEATURE_TABLE=$3
	# Run PICRUST2 pipeline 
	picrust2_pipeline.py \
		-s ${PREFIX}-${REP_SET} \
		-i ${PREFIX}-${FEATURE_TABLE} \
		-o ${PREFIX}-picrust2_out_pipeline \
		-p 40

	# Annotate you enzymes / pathways by adding a description column
	add_descriptions.py -i ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat.tsv.gz -m EC \
                	    -o ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz

	add_descriptions.py -i ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat.tsv.gz -m METACYC \
        	            -o ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat_descrip.tsv.gz

	add_descriptions.py -i ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat.tsv.gz -m KO \
        	            -o ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz

	# Unzip the prediction files
	gunzip ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz
	gunzip ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz
	gunzip ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat_descrip.tsv.gz

	gunzip ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat.tsv.gz
	gunzip ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat.tsv.gz
	gunzip ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat.tsv.gz

	# Convert to biom
	biom convert \
		-i ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat.tsv \
		-o ${PREFIX}-picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat.biom \
		--table-type="OTU table" \
		--to-hdf5

	biom convert \
		-i ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat.tsv \
		-o ${PREFIX}-picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat.biom \
		--table-type="OTU table" \
		--to-hdf5

	biom convert \
		-i ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat.tsv \
		-o ${PREFIX}-picrust2_out_pipeline/pathways_out/path_abun_unstrat.biom \
		--table-type="OTU table" \
		--to-hdf5

}


export -f run_picrust

parallel --jobs 0 --link run_picrust {1} {2} {3} ::: ${PREFIX[*]} ::: ${REP_SET[*]} ::: ${FEATURE_TABLE[*]}
