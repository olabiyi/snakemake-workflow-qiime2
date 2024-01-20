.PHONY: install snakemake fastqc multiqc pear qiime run copy manifest samples rename silva complete import denoise plot assign_taxonomy

help:
	@echo "A pipeline to perform 16S microbiome analysis on aws "

install: update snakemake fastqc multiqc pear qiime silva

update:
	@echo "updating the shell"
	#sudo apt update && apt upgrade

fastqc: update
	@echo "Downloading fastqc"
	docker pull staphb/fastqc:0.12.1

multiqc: update
	@echo "Downloading Multiqc"
	docker pull staphb/multiqc:1.8

pear: update
	@echo "Downloading pear read merger"
	docker pull olabiyi/pear:0.92

qiime: update
	@echo "Downloading qiime and picrust"
	# For functions analysis using picrust
	docker pull kubor/qiime2-picrust2:2019.10
	# Core qiime
	docker pull quay.io/qiime2/amplicon:2023.9

snakemake: update
	@echo "Download snakemake"
	#docker pull snakemake/snakemake:stable
	conda install -c bioconda snakemake

silva: update
	@echo "Dowloading Silva database"
	#Full
	wget https://data.qiime2.org/2023.9/common/silva-138-99-nb-classifier.qza
	# V4 specific
	wget https://data.qiime2.org/2023.9/common/silva-138-99-515-806-nb-classifier.qza

run:
	#@echo "Running snakemake in a docker container"
	$(shell docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v ${PWD}:${PWD} -w ${PWD} -u $(id -u):$(id -g) snakemake/snakemake:stable; snakemake -pr --cores 30 --keep-going --rerun-incomplete)

	
copy:
	@echo "Copying files from S3"
	@echo "Configure aws first by running: sudo apt install awscli -y && aws configure"
	#aws s3 cp --recursive s3://biodsa-sequencing-data/SEQ44XXX/SEQ44733/Reads/ 01.raw_data/
	bash download_seqs.sh
 
rename:
	@echo "Renaming the files so that the filename replect the sample names in individual directory"
	bash rename_files.sh
 
samples:
	@echo "Get sample names for config.yaml"
	bash get_samples.sh

manifest:
	@echo "Creating a MANIFEST file"
	bash make_manifest.sh
 
complete:
	@echo "Running the complete pipeline. Quality reports, Corediversity analysis, statistics and functional analysis"
	snakemake -pr --cores 50 --keep-going --rerun-incomplete

import:
	@echo "Importing, trimming primers and adapters, and performing initial quality checks"
	@echo "Inspect the plots generated in 04.QC/trimmed_reads_qual_viz.qzv at https://view.qiime2.org/"
	snakemake -pr --cores 50 --keep-going --rerun-incomplete "04.QC/trimmed_reads_qual_viz.qzv" "04.QC/raw_reads_qual_viz.qzv"

denoise:
	@echo "Denoising your imported sequences"
	@echo "Inspect the table 05.Denoise_reads/denoise_stats.qzv at https://view.qiime2.org/"
	@echo "Edit the config/config.yaml file appropriately and re-run if many were lost after denoising."
	snakemake -pr --cores 50 --keep-going --rerun-incomplete "05.Denoise_reads/denoise_stats.qzv" "05.Denoise_reads/table_summary.qzv" "05.Denoise_reads/representative_sequences.qzv"

assign_taxonomy:
	@echo "Assigning taxonomy and filtering out non-target taxa"
	@echo "After this run completes"
	@echo "Examine 08.Filter_feature_table/taxa_filtered_table.qzv"
	@echo "To figure out the total number of sequences ('Total freqency') to be used to determine the minuminum frequency for filtering out rare taxa"
	@echo  "Simply multiply the total number of sequences by your threshold for example 0.00005 (0.005 percent)"
	@echo "python -c print(1298206 * 0.00005) = 64.9103"
	@echo "Set the 'minimum_frequency' parmeter in config/config.yaml with the result of this calculation rounded up like so:"
	@echo "minimum_frequency: 65"
	snakemake -pr --cores 50 --keep-going  --rerun-incomplete "06.Assign_taxonomy/taxonomy.qzv" "07.Build_phylogenetic_tree/rooted-tree.qza" "08.Filter_feature_table/taxa_filtered_table.qzv"

plot:
	@echo "Filtering out rare ASV and generating taxonomy plots"
	snakemake -pr --cores 10 --keep-going --rerun-incomplete  "08.Filter_feature_table/filtered_table.qzv" "09.Taxa_bar_plots/group-bar-plot.qzv" "09.Taxa_bar_plots/samples-bar-plots.qzv"
