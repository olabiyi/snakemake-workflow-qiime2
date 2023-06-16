.PHONY: import denoise assign_taxonomy plot complete clean upload download

complete:
	@echo "Running the complete pipeline. Quality reports, Corediversity analysis, statistics and functional analysis"
	snakemake -pr --cores 10 --keep-going --rerun-incomplete

import:
	@echo "Importing, trimming primers and adapters, and performing initial quality checks"
	@echo "Inspect the plots generated in 04.QC/trimmed_reads_qual_viz.qzv at https://view.qiime2.org/"
	snakemake -pr --cores 10 --keep-going --rerun-incomplete "04.QC/trimmed_reads_qual_viz.qzv" "04.QC/raw_reads_qual_viz.qzv"

denoise:
	@echo "Denoising your imported sequences"
	@echo "Inspect the table 05.Denoise_reads/denoise_stats.qzv at https://view.qiime2.org/"
	@echo "Edit the config/config.yaml file appropriately and re-run if many were lost after denoising."
	snakemake -pr --cores 10 --keep-going --rerun-incomplete "05.Denoise_reads/denoise_stats.qzv" "05.Denoise_reads/table_summary.qzv" "05.Denoise_reads/representative_sequences.qzv"

assign_taxonomy:
	@echo "Assigning taxonomy and filtering out non-target taxa"
	@echo "After this run completes"
	@echo "Examine 08.Filter_feature_table/taxa_filtered_table.qzv"
	@echo "To figure out the total number of sequences ('Total freqency') to be used to determine the minuminum frequency for filtering out rare taxa"
	@echo  "Simply multiply the total number of sequences by your threshold for example 0.00005 (0.005 percent)"
	@echo "python -c print(1298206 * 0.00005) = 64.9103"
	@echo "Set the 'minimum_frequency' parmeter in config/config.yaml with the result of this calculation rounded up like so:"
	@echo "minimum_frequency: 65"
	snakemake -pr --cores 10 --keep-going  --rerun-incomplete "06.Assign_taxonomy/taxonomy.qzv" "07.Build_phylogenetic_tree/rooted-tree.qza" "08.Filter_feature_table/taxa_filtered_table.qzv"

plot:
	@echo "Filtering out rare ASV and generating taxonomy plots"
	snakemake -pr --cores 10 --keep-going --rerun-incomplete  "08.Filter_feature_table/filtered_table.qzv" "09.Taxa_bar_plots/group-bar-plot.qzv" "09.Taxa_bar_plots/samples-bar-plots.qzv"

upload:
	@echo "Copying the denoising folder to HPRC for taxonomy assignment"
	scp -r 05.Denoise_reads/ obayomi@grace.tamu.edu:/scratch/user/obayomi/projects/amplicon_sequencing/Guay

download:
	@echo "Downloading the assign taxonomy folder from HPRC"
	scp -r obayomi@grace.tamu.edu:/scratch/user/obayomi/projects/amplicon_sequencing/Guay/06.Assign_taxonomy/ .
