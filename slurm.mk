.PHONY: import denoise assign_taxonomy plot complete clean

complete:
	@echo "Running the complete pipeline. Quality rreports, Corediversity analysis, statistics and functional analysis"
	sbatch 05.run_complete-submit-slurm.sh

import:
	@echo "Importing, trimming primers and adapters, and performing initial quality checks"
	@echo "Inspect the plots generated in 04.QC/trimmed_reads_qual_viz.qzv at https://view.qiime2.org/"
	sbatch 01.import-submit-slurm.sh

denoise:
	@echo "Denoising your imported sequences"
	@echo "Inspect the table 05.Denoise_reads/denoise_stats.qzv at https://view.qiime2.org/"
	@echo "Edit the config/config.yaml file appropriately and re-run if many were lost after denoising."
	sbatch 02.denoise-submit-slurm.sh

assign_taxonomy:
	@echo "Assigning taxonomy and filtering out non-target taxa"
	@echo "After this run completes"
	@echo "Examine 08.Filter_feature_table/taxa_filtered_table.qzv"
	@echo "To figure out the total number of sequences ('Total freqency') to be used to determine the minuminum frequency for filtering out rare taxa"
	@echo  "Simply multiply the total number of sequences by your threshold for example 0.00005 (0.005 percent)"
	@echo "python -c print(1298206 * 0.00005) = 64.9103"
	@echo "Set the 'minimum_frequency' parmeter in config/config.yaml with the result of this calculation rounded up like so:"
	@echo "minimum_frequency: 65"
	sbatch 03.filter_taxa-submit-slurm.sh

plot:
	@echo "Filtering out rare ASV and generating taxonomy plots"
	sbatch 04.filter_rare-submit-slurm.sh

clean:
	rm  slurm-*  *.{e,o}.*

