# Snakemake Workflow: Microbiome Amplicon (16S, 18S and ITS) sequence analysis using Qiime2 and PICRUSt2. 

<img alt="QIIME2-workflow" src="images/rulegraph.png">

This workflow performs microbiome analysis using QIIME2 and PICRUSt2 for functional annotation. Functional annotation is only performed for 16S amplicon sequences. 

Please note the following:

1. I analyze my data with qiime2 version 2020.6 so that's what I have tested this pipeline with. 
2. I have not tested the pipeline using deblur or vsearch even though I have implemented them, so use these methods at your own risk. I have tested the dada2 pipeline and it works great. Hence, I advice you run the dada2 pipeline.
3. I provide 3 Snakefiles: Snakefile (16S, 18S and ITS), Snakefile.16S (16S and 18S) and Snakefile.ITS (ITS alone).
4. I will be be happy to fix any bug that you migth find, so please feel free to reach out to me at obadbotanist@yahoo.com


Please do not forget to cite the authors of the tools used.


**The Pipeline does the following:**

- It renames your input files (optional) so that it conforms with the required input format i.e. 01.raw_data/{SAMPLE}_R{1|2}.fastq.gz for paired-end or 01.raw_data/{SAMPLE}.fastq.gz for single-end reads
- Quality checks and summarizes the input reads using FASTQC and MultiQC
- Imports the reads into Qiime2
- Quality checks the input artifact using Qiime2
- Trims the imported arfifact for primers and adaptors using cutadapt implemented in qiime2
- Quality checks the trimmed input artifact using Qiime2
- Denoises (filtering, chimera checking and ASV table generation) the reads using dada2 (default) 
- Asigns taxonomy to the representative sequences using sci-kit learn and your provided database. see the folder Create__DB for a pipeline that can be used to create the required databases
- Excludes singletons and non-target taxa such as Mitochondria, Chloroplast etc. The taxa to be filtered can be set from within the Snakefile file by editing the "taxa2filter" variable.
- Excludes rare ASV i.e. ASVs with sequences less than 0.005% of the total number of sequences (Navas-Molina et al. 2013) 
- Builds a phylogenetic tree
- Generates sample and group taxa plots
- Performs core diversity analysis i.e alpha and betadiversity analysis along with the related statistical tests
- Performs differential abundance testing using ANCOM
- Perform functional anaotation using PICRUSt2 for 16S sequences.


## Authors

* Olabiyi Obayomi (@olabiyi)


Before you start, make sure you have miniconda, qiime2, picrust2 and snakemake installed. You can optionally install my bioinfo environment which contains snakemake and many other useful bioinformatics tools.

### STEP 1:  Install miniconda and qiime 2 (optional)

See instructions on how to do so [here](https://docs.qiime2.org/2020.6/install/)

### STEP 2:  Install picrust2 (optional)

See instuctions on how to do so [here](https://github.com/picrust/picrust2/blob/master/INSTALL.md)


### STEP 3: Install Snakemake in a separate conda environment or install my bioinfo environment which contains snakemake(optional)

Install Snakemake using [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html):

    conda create -c bioconda -c conda-forge -n snakemake snakemake

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).


### Step 4: Obtain a copy of this workflow

	git clone https://github.com/olabiyi/sankemake-workflow-qiime2.git

### Step 5: Configure workflow

Configure the workflow according to your needs by editing the files in the `config/` folder. Adjust `config.yaml` to configure the workflow execution, and `samples.tsv` to specify your sample setup. Make sure your sample.tsv file does not contain any error as this could lead to potentially losing all of your data when renaming the files.

### Step 6: Install bioinfo environment (Optional)

If you would like to use my bioinfo environment:

	conda env create -f envs/bioinfo.yaml  


### Step 7:  Running the pipeline

#### Activate the conda environment containing snakemake  

	source activate bioinfo


#### Set-up the mapping file and raw data directories

	[ -d 00.mapping/ ] || mkdir 00.mapping/   
    [ -d 01.raw_data/ ] || mkdir 01.raw_data/

#### Move your raw data to the 01.raw_data directory 
    # Delete anything that may be present in the rawdata directory
    rm -rf  mkdir 01.raw_data/*
    # Move your read files to the rawa data directory - Every sample in its own directory - see the example in this repo
	mv  location/rawData/16S/* 01.raw_data/

#### Create metadata files

You need two metadata files: a general metadata file called metadata.tsv and a treatment-treatment.tsv file.
Thes files can be createda nd editted with excel. Make sure to save the names as  *metadata.tsv* and *treatment-metadata.tsv*.
The treatment-metadata is used for makeing grouped bar plots while the metadata.tsv is used for corediversity analysis and general statistics.
Please see the examples provided in this repository for specific formats.


#### Create the required  MANIFEST FILE
 
    # Get the sample names. This assumes that the folders in the 01.raw_data/ directory are named by sample.
	SAMPLES=($(ls -1 01.raw_data/ | grep -Ev "MANIFEST|seq" - |sort -V))
    
	# Get sample names for "samples" field in the config file

	(echo -ne '[';echo ${SAMPLES[*]} | sed -E 's/ /, /g' | sed -E 's/(\w+)/"\1"/g'; echo -e ']') 

	# Generate the MANIFEST file
	(echo "sample-id,absolute-filepath,direction"; \
	for SAMPLE in ${SAMPLES[*]}; do echo -ne "${SAMPLE},$PWD/01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz,forward\n${SAMPLE},$PWD/01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz,reverse\n";done) \
    > 01.raw_data/MANIFEST

#### Create config/sample.tsv file
	(echo -ne "SampleID\tType\tOld_name\tNew_name\n"; \
	for SAMPLE in ${SAMPLES[*]}; do echo -ne "${SAMPLE}\tForward\t01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz\t01.raw_data/${SAMPLE}/${SAMPLE}_R1.fastq.gz\n${SAMPLE}\tReverse\t01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz\t01.raw_data/${SAMPLE}/${SAMPLE}_R2.fastq.gz\n";done) \
	> config/sample.tsv


#### gzip fastq files if they are not already gziped as required by this pipeline. It also helps to save disk memory.

	find 01.raw_data/ -type f -name '*.fastq' -exec gzip {} \;


#### Executing the Workflow

##### import reads and check their quality to determine trunc lengths for dada2
	
	snakemake -pr --cores 10 --keep-going "04.QC/trimmed_reads_qual_viz.qzv" "04.QC/raw_reads_qual_viz.qzv"


##### Denoise reads - chimera removal, reads merging, quality trimming and ASV feature table generation take a good look at 05.Denoise_reads/denoise_stats.qzv to see if you didn't lose too many reads and if the reads merged well. If the denoizing was not sucessful, adjust the parameters you set for dada2 and then re-run

	snakemake -pr --cores 15 --keep-going "05.Denoise_reads/denoise_stats.qzv" "05.Denoise_reads/table_summary.qzv" "05.Denoise_reads/representative_sequences.qzv"

##### Filter taxa - Examine "08.Filter_feature_table/taxa_filtered_table.qzv" to determine the threshold for filtering out rare taxa

	snakemake -pr --cores 15 --keep-going  "06.Assign_taxonomy/taxonomy.qzv" "07.Build_phylogenetic_tree/rooted-tree.qza" "08.Filter_feature_table/taxa_filtered_table.qzv"

##### Filter rare taxa and make relative abundance bar plots
	
	snakemake -pr --cores 15 --keep-going  "08.Filter_feature_table/filtered_table.qzv" "09.Taxa_bar_plots/group-bar-plot.qzv" "09.Taxa_bar_plots/samples-bar-plots.qzv"

##### Get the rarefation depth for diversity analysis after viewing "08.Filter_feature_table/filtered_table.qzv" and run the complete pipeline
	
	snakemake -pr --cores 15 --keep-going


#### Export the following files for downstream analysis with R Scripts
 
1.  05.Denoise_reads/denoise_stats.qza -> Denoising statistics
2.  06.Assign_taxonomy/taxonomy.qza -> Taxonomy assignments of the representative sequences
3.  07.Build_phylogenetic_tree/rooted-tree.qza -> Phylogenetic tree for phylogenetic alphadiversity measurements
4.  08.Filter_feature_table/filtered_table.qza -> ASV table
5.  10.Diversity_analysis_{RAREFACTION_DEPTH}/bray_curtis_pcoa_results.qza -> Bray Curtis pcoa results
6.  10.Diversity_analysis_{RAREFACTION_DEPTH}/bray_curtis_distance_matrix.qza -> Bray Curtis distance matrix
7.  15.Function_annotation/picrust2_out_pipeline/pathways_out -> Picrust2 pathway output
8.  15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out -> Picrust2 KO / genes output
