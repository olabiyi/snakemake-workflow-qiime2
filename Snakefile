from os import path, getwd
import pandas as pd


configfile: "config/config.yaml"

onsuccess:
    print("Workflow completed without any error")


mail=config['mail']
onerror:
    print("An error occurred")
    shell("mail -s 'An error occurred' {mail} < {log}")




sample_file = config["sample_file"]

metadata = pd.read_table(sample_file)

mode=config['mode']
merge_method=config['merge_method']
denoise_method=config['denoise_method']

RULES=["Rename_files", "Merge_reads", "Import_sequences",
       "Qaulity_check", "Denoise_reads", "",
       "", "", ""]



rule all:
    input:




# This rule will make rule specific log directories
# # in order to easily store the standard input and stand error
# # generated when submiting jobs to the cluster
rule Make_logs_directories:
    output:
        directory("logs/Rename_files/"),
        directory("logs//"),
        directory("logs//"),
        directory("logs//")
    threads: 1
    shell:
        """
         [ -d logs/ ] || mkdir -p logs/
         cd logs/
         for RULE in {RULES}; do
          [ -d ${{RULE}}/ ] || mkdir -p ${{RULE}}/
         done
        """

# Rename files so that the file names are easy to work with 
rule Rename_files:
    output:
        expand(["01.raw_data/{sample}/{sample}_1.fq.gz", "01.raw_data/{sample}/{sample}_2.fq.gz"],
                 sample=config['samples'])
    log: "logs/Rename_files/Rename_files.log"
    threads: 5
    run:
        for old,new in zip(metadata.Old_name,metadata.New_name):
            shell("mv {old} {new}".format(old=old, new=new))



if mode == "pair":

    # Import pe-sequnces to qiime
    # Make sure you have a paired end specific manifest file - see example in examples folder
    rule Import_sequences:
        input: 
           expand("01.raw_data/{sample}_fastq.gz", sample=config['samples']"),,
           manifest_file=config["MANIFEST"]
        output: "02.import/reads.qza"
        log: "logs/Import_sequences/Import_sequences.log"
        threads: 5
        params:
            conda_activate=config["QIIME2_ENV"],
            seq_dir=lambda w, input: path.dirname(input[0])
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime tools import \
                 --type 'SampleData[PairedEndSequencesWithQuality]' \
                 --input-path {params.seq_dir} \
                 --output-path {output}
        """


elif mode == "single":

    # Import se-sequnces to qiime
    rule Import_sequences:
        input: 
            expand("01.raw_data/{sample}_fastq.gz", sample=config['samples']"),
            manifest_file=config["MANIFEST"]
        output: "03.import/reads.qza"
        log: "logs/Import_sequences/Import_sequences.log"
        threads: 5
        params:
            conda_activate=config["QIIME2_ENV"],
            seq_dir=lambda w, input: path.dirname(input[0])
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime tools import \
                 --type 'SampleData[SequencesWithQuality]' \
                 --input-path {params.seq_dir} \
                 --output-path {output} \
                 --input-format SingleEndFastqManifestPhred33
            """


elif mode == "merge":

    if merge_method == "pear":

        # Merge paired-end reads using pear - modifify the -m -t flags of pear before running the workflow    
        rule Merge_reads:
            input:
                expand("01.raw_data/{sample}_fastq.gz", sample=config['samples']")
            output:
                expand("02.merge_reads/{sample}_fastq.gz", sample=config['samples'])
            log: "logs/Merge_reads/Merge_reads.log"
            threads: 5
            params:
                out_dir=lambda w, output: path.dirname(output[0]),
                in_dir=lambda w, input: path.dirname(input[0]),
                program=config['programs_path']['run_pear']
            shell:
                """
                # Merge reads then delete unnecessary files
                 {params.program} -o {params.out_dir}/  {params.in_dir}/*.fastq.gz && \
                 rm -rf {params.out_dir}/*.unassembled* {params.out_dir}/*discarded*
         
               # gzip to save memory
         
                 gzip {params.out_dir}/*.fastq

                """


        # Import pe-joined reads to qiime
        rule Import_sequences:
            input: 
                rules.Merge_reads.output,
                manifest_file=config["MANIFEST"]
            output: "03.import/reads.qza"
            log: "logs/Import_sequences/Import_sequences.log"
            threads: 5
            params:
                conda_activate=config["QIIME2_ENV"],
                seq_dir=lambda w, input: path.dirname(input[0])
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime tools import \
                     --type 'SampleData[SequencesWithQuality]' \
                     --input-path {params.seq_dir} \
                     --output-path {output} \
                     --input-format SingleEndFastqManifestPhred33
                """


    elif merge_method == "vsearch":

        rule Import_sequences:
            input:
                expand("01.raw_data/{sample}_fastq.gz", sample=config['samples']"),
                manifest_file=config["MANIFEST"]
            output: "03.import/reads.qza"
            log: "logs/Import_sequences/Import_sequences.log"
            threads: 5
            params:
                conda_activate=config["QIIME2_ENV"],
                seq_dir=lambda w, input: path.dirname(input[0])
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime tools import \
                     --type 'SampleData['PairedEndSequencesWithQuality']' \
                     --input-path {params.seq_dir} \
                     --output-path {output} 
                """

        # Merge forwards and reverse reads using vsearch
        rule Merge_reads:
            input: rules.Import_sequences.output
            output: "02.merge_reads/reads.qza"
            log: "logs/Merge_reads/Merge_reads.log"
            threads: 5
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime vsearch join-pairs \
                     --i-demultiplexed-seqs {input} \
                     --p-truncqual {params.trunc_qual} \
                     --p-minlen {params.min_len} \
                     --p-maxns {params.min_ns} \
                     --p-minmergelen {params.men_merge_len} \
                     --p-maxmergelen {params.max_merge_len} \
                     --o-joined-sequences {output}
                """
 

# Demultiplex and View reads quality
# Analyze quality scores of 10000 random samples

# If the merge method is vsearch, the input
# for demultiplexing should be the merged reads after
# Import else use the Imported reads
if merge_method == "vsearch":

    rule Qaulity_check:
        input: rules.Merge_reads.output
        output: "04.QC/qual_viz.qzv"
        log: "logs/Qaulity_check/Qaulity_check.log"
        threads: 10
        params:
            conda_activate=config["QIIME2_ENV"]
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime demux summarize \
                --p-n 10000 \
                --i-data {input} \
                --o-visualization {output}
        """


else:


    rule Qaulity_check:
        input: rules.Import_sequences.output
        output: "04.QC/qual_viz.qzv"
        log: "logs/Qaulity_check/Qaulity_check.log"
        threads: 10
        params:
            conda_activate=config["QIIME2_ENV"]
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime demux summarize \
                --p-n 10000 \
                --i-data {input} \
                --o-visualization {output}
        """



# Qaulity filter, denoise and generate feature table using dada2 or deblur

if denoise_method == "dada2":
    
        
    rule Denoise_reads:
        input: rules.Import_sequences.output
        output: 
            table="05.Denoise_reads/table.qza",
            rep_seqs="05.Denoise_reads/representative_sequences.qza",
            stats="05.Denoise_reads/denoise_stats.qza"
        log: "logs/Denoise_reads/Denoise_reads.log"
        threads: 30
        params:
            conda_activate=config["QIIME2_ENV"],
            mode=config['parameters']['dada2']['mode'],
            trun_len_forward=config['parameters']['dada2']['trunc_length_forward'],
            trun_len_reverse=config['parameters']['dada2']['trunc_length_reverse'],
            trim_len_forward=config['parameters']['dada2']['trim_length_forward'],
            trim_len_reverse=config['parameters']['dada2']['trim_length_reverse'],
            threads=config['parameters']['dada2']['threads']
        shell:
            """
            set +u
            {params.conda_activate}
            set -u
            
            MODE={params.mode}

            if [ ${MODE} == "paired" ];then

                # Paired end
                qiime dada2 denoise-paired \
                    --i-demultiplexed-seqs {input} \
                    --o-table {output.table} \
                    --o-representative-sequences {output.rep_seqs} \
                    --o-denoising-stats {output.stats} \
                    --p-trunc-len-f  {params.trun_len_forward} \
                    --p-trunc-len-r {params.trun_len_reverse} \
                    --p-trim-left-f {params.trim_len_forward} \
                    --p-trim-left-r {params.trim_len_reverse} \
                    --p-n-threads {params.threads} 

            else

                # Single end
                qiime dada2 denoise-single \
                    --i-demultiplexed-seqs {input} \
                    --o-table {output.table} \
                    --o-representative-sequences {output.rep_seqs} \
                    --o-denoising-stats {output.stats} \
                    --p-trunc-len  {params.trun_len_forward} \
                    --p-trim-left {params.trim_len_forward} \
                    --p-n-threads {params.threads}

                  
            """


elif ASV_method == "deblur":

    # Denoise using deblur
    rule Denoise_reads:
        input: rules.Import_sequences.output
        output:
            filtered_reads="05.Denoise_reads/reads-filtered.qza",
            filter_stats="05.Denoise_reads/reads-filter-stats.qza",
            filter_stats_viz="05.Denoise_reads/reads-filter-stats.qzv",
            table="05.Denoise_reads/table.qza",
            rep_seqs="05.Denoise_reads/representative_sequences.qza",
            stats="05.Denoise_reads/denoise_stats.qza"
        log: "logs/Denoise_reads/Denoise_reads.log"
        threads: 30
        params:
            conda_activate=config["QIIME2_ENV"],
            trunc_length=config['parameters']['deblur']['trunc_length']
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            # Initial quality filtering process based on quality scores
            qiime quality-filter q-score \
              --i-demux {input} \
              --o-filtered-sequences {output.filtered_reads} \
              --o-filter-stats {output.filter_stats}

            # Tabulate the filter statistics
            qiime metadata tabulate \
	      --m-input-file {output.filter_stats} \
 	      --o-visualization {output.filter_stats_viz}

            
            # # Next, the Deblur workflow is applied using the qiime deblur denoise-16S method.
            # This method requires one parameter that is used in quality filtering,
            # --p-trim-length n which truncates the sequences at position n.
            #  In general, the Deblur developers recommend setting this value to a length 
            # where the median quality score begins to drop too low

            qiime deblur denoise-16S \
              --i-demultiplexed-seqs {output.filtered_reads} \
              --p-trim-length {params.trunc_length} \
              --o-representative-sequences {params.rep_seqs} \
              --o-table {ouput.table} \
              --p-sample-stats \
              --o-stats {output.stats}
            """


# Summarize denoised feature table (ASV or zOTUS table for dada2 and deblur, respectively)
rule Summarize_feature_table:
    input: rules.Denoise_reads.output.table
    output: "05.Denoise_reads/table_summary.qzv"
    log: "logs/Summarize_feature_table/Summarize_feature_table.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime feature-table summarize \
	   --i-table {input} \
	   --o-visualization {output}
        """


# Tabulate the representative sequences 
rule Tabulate_sequences:
    input: rules.Denoise_reads.output.rep_seqs
    output: "05.Denoise_reads/representative_sequences.qzv"
    log: "logs/Tabulate_sequences/Tabulate_sequences.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime feature-table summarize \
           --i-table {input} \
           --o-visualization {output}
        """


if denoise_method == "dada2":

    rule Tabulate_denoise_statistics:
        input: rules.Denoise_reads.output.stats
        output: "05.Denoise_reads/denoise_stats.qzv"
        log: "logs/Tabulate_denoise_statistics/Tabulate_denoise_statistics.log"
        threads: 1
        params:
            conda_activate=config["QIIME2_ENV"]
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            # Visualize dada2 denoise stats
            qiime metadata tabulate \
              --m-input-file {input} \
              --o-visualization {output}
        """

elif denoise_method == "deblur":
    rule Tabulate_denoise_statistics:
        input: rules.Denoise_reads.output.stats
        output: "05.Denoise_reads/denoise_stats.qzv"
        log: "logs/Tabulate_denoise_statistics/Tabulate_denoise_statistics.log"
        threads: 1
        params:
            conda_activate=config["QIIME2_ENV"]
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

             # Visualize deblur stats
             qiime deblur visualize-stats \
                 --i-deblur-stats {output.stats} \
                 --o-visualization {output}
            """



# Assign taxonomy to denoised representative sequences
rule Assign_taxonomy:
    input: 
        rep_seqs=rules.Denoise_reads.output.rep_seqs,
        classifier=config['classifier']
    output: 
         raw="06.Assign_taxonomy/taxonomy.qza",
         viz="06.Assign_taxonomy/taxonomy.qzv"
    log: "logs/Assign_taxonomy/Assign_taxonomy.log"
    threads: 30
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

         # Assign taxonomy
         qiime feature-classifier classify-sklearn \
           --i-classifier {input.rep_seqs} \
           --i-reads {input.rep_seqs} \
           --o-classification {output.raw} 

         # Tabulate taxonomy

         qiime metadata tabulate \
           --m-input-file {output.raw} \
           --o-visualization {output.viz}
        """



# Build Phylogenetic tree from represenative sequences
rule Build_phylogenetic_tree:
    input:
        rep_seqs=rules.Denoise_reads.output.rep_seqs
    output:
         alignment="07.Build_phylogenetic_tree/aligned_representative_sequences.qza",
         masked_alignment="07.Build_phylogenetic_tree/masked_aligned_representative_sequences.qza",
         unrooted_tree="07.Build_phylogenetic_tree/unrooted-tree.qza",
         rooted_tree="07.Build_phylogenetic_tree/rooted-tree.qza"
    log: "logs/Build_phylogenetic_tree/Build_phylogenetic_tree.log"
    threads: 30
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

         # Run the make phylogenetic tree pipeline
         # 1. Perform multiple sequence alignment with mafft
         # 2. Mask alignment
         # 3. Make tree with fastree
         # 4. Root the tree


        qiime phylogeny align-to-tree-mafft-fasttree \
           --i-sequences {input} \
           --o-alignment {output.alignment} \
           --o-masked-alignment {output.masked_alignment} \
           --o-tree {output.unrooted_tree} \
           --o-rooted-tree {output.rooted_tree}
        """


# ----------------------------------- Filter feature table ------------------------------------ #

# Remove singletons and non-target sequences e.g chloroplast, mitochondria, archaea and eukaryota
# for protists - Bacteria,Fungi,Chytridiomycota,Basidiomycota,Metazoa,Rotifera,Gastrotricha,
# Nematozoa,Euglenozoa,Embryophyta,Spermatophyta,Asterales,Brassicales,Caryophyllales,Cupressales,
# Fabales,Malpighiales,Pinales,Rosales,Solanales,Arecales,Asparagales,Poales,Capsicum,Jatropha,
# Bryophyta,Tracheophyta

if config['amplicon'] == "16S":
    taxa2filter = "Unassigned,Chloroplast,Mitochondria,Archaea,Eukaryota"

elif config['amplicon'] == "18S":
    taxa2filter = "Bacteria,Fungi,Chytridiomycota,Basidiomycota,Metazoa,Rotifera,"
                   "Gastrotricha,Nematozoa,Embryophyta,Spermatophyta,Asterales,"
                   "Brassicales,Caryophyllales,Cupressales,Fabales,Malpighiales,"
                   "Pinales,Rosales,Solanales,Arecales,Asparagales,Poales,"
                   "Capsicum,Jatropha,Bryophyta,Tracheophyta"

elif config['amplicon'] == "ITS":
    taxa2filter = ""



rule Exclude_singletons:
    input:
        rules.Denoise_reads.output.table
    output:
        table_raw="08.Filter_feature_table/noSingleton_filtered_table.qza",
        table_viz="08.Filter_feature_table/noSingleton_filtered_table.qzv"
    log: "logs/Exclude_singletons/Exclude_singletons.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Remove singletons
        qiime feature-table filter-features \
          --i-table {input} \
          --p-min-frequency 2 \
          --o-filtered-table {output.table_raw}

        qiime feature-table summarize \
          --i-table {output.table_raw} \
          --o-visualization {output.table_viz}
        """


# Filter out non-target taxonomy assignment from the feature table

rule Exclude_non_target_taxa:
    input: 
        table=rules.Exclude_singletons.output.table_raw,
        taxonomy=rules.Assign_taxonmy.output.raw
    output: 
        table_raw="08.Filter_feature_table/taxa_filtered_table.qza",
        table_viz="08.Filter_feature_table/taxa_filtered_table.qzv"
    log: "logs/Exclude_non_target_taxa/Exclude_non_target_taxa.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"],
        out_dir=lambda w, output: path.dirname(output.table),
        taxa2exclude=taxa2filter
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Filter out non-target assigments
        qiime taxa filter-table \
          --i-table {input.table} \
          --i-taxonomy  {input.taxonomy} \
          --p-exclude  {params.taxa2exclude} \
          --o-filtered-table {output.table_raw}

        # To figure out the total number of sequences ("Total freqency") 
        # to be used to determine the minuminum frequency for filtering out
        # rare taxa. to calculate the multiply the total number of sequences
        # by 0.005
        qiime feature-table summarize \
          --i-table {output.table_raw} \
          --o-visualization {output.table_raw}
        """

# Removing rare taxa i.e. features with abundance less the 0.005%
rule Exclude_rare_taxa:
    input:
        rules.Exclude_non_target_taxa.output.table_raw
    output:
        table_raw="08.Filter_feature_table/filtered_table.qza",
        table_viz="08.Filter_feature_table/filtered_table.qzv"
    log: "logs/Exclude_rare_taxa/Exclude_rare_taxa.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"],
        minumum_frequency=config['minimum_frequency']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Removing rare otus / features with abundance less the 0.005%
        qiime feature-table filter-features \
          --i-table {input} \
          --p-min-frequency {params.minumum_frequency} \
          --o-filtered-table {output.table_raw}

        qiime feature-table summarize \
          --i-table {output.table_raw} \
          --o-visualization {output.table_viz}
        """

#############################################################################


# ---------------- Generate samples and treatment bar plots -------------------- #

rule Samples_taxa_bar_plot:
    input:
        table=rules.Exclude_rare_taxa.output.table_raw,
        taxonomy=rules.Assign_taxonmy.output.raw,
        metadata=config['metadata']
    output: "09.Taxa_bar_plots/samples-bar-plots.qzv"
    log: "logs/Samples_taxa_bar_plots/Samples_taxa_bar_plots.log"
    threads: 5
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u


       # Samples bar plot
       qiime taxa barplot \
         --i-table {input.table} \
         --i-taxonomy {input.taxonomy} \
         --m-metadata-file {input.metadata} \
         --o-visualization  {output}
       """


rule Group_taxa_bar_plot:
    input:
        table=rules.Exclude_rare_taxa.output.table_raw,
        taxonomy=rules.Assign_taxonmy.output.raw,
        metadata=config['metadata']
    output: 
         grouped_table="09.Taxa_bar_plots/grouped-filtered_table.qza"
         bar_plot="09.Taxa_bar_plots/group-bar-plot.qzv"
    log: "logs/Group_taxa_bar_plot/Group_taxa_bar_plot.log"
    threads: 5
    params:
        conda_activate=config["QIIME2_ENV"],
        category=config['parameters']['group_taxa_plot']['category'],
        mode=config['parameters']['group_taxa_plot']['mode']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Group feature table by group in metadata file
        qiime feature-table group \
           --i-table  {input.table}  \
           --p-axis sample \
           --m-metadata-file {input.metadata} \ 
           --m-metadata-column {params.category}
           --p-mode {params.mode} \
           --o-grouped-table {output.grouped_table}

        # Grouped bar plot
        qiime taxa barplot \
          --i-table {output.grouped_table} \
          --i-taxonomy {input.taxonomy} \
          --m-metadata-file {input.metadata} \
          --o-visualization  {output}
       """


# -----------------------------------  Alpha and Beta diversity -------------------------------------#

# Perform core diversity analysis - output are directory with various
# alpha and beta diversity metrics
rule Core_diversity_analysis:
    input:
        table=rules.Exclude_rare_taxa.output.table_raw,
        metadata=config['metadata'],
        tree=rules.Build_phylogenetic_tree.output.rooted_tree
    output:
        directory("10.Diversity_analysis_{depth}".format(depth=config['rarefaction_depth']))   
    log: "logs/Core_diversity_analysis/Core_diversity_analysis.log"
    threads: 10
    params:
        conda_activate=config["QIIME2_ENV"],
        depth=config['rarefaction_depth']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime diversity core-metrics-phylogenetic \
           --p-sampling-depth {params.depth} \
           --i-table {input.table} \
           --i-phylogeny {input.tree} \
           --m-metadata-file {input.metadata} \
           --output-dir {output}
        """

# Alpha rarefaction curves show taxon accumulation as a function of sequence depth
rule Make_rarefaction_curves:
    input:
        table=rules.Exclude_rare_taxa.output.table_raw,
        metadata=config['metadata'],
        tree=rules.Build_phylogenetic_tree.output.rooted_tree
    output:
        "10.Diversity_analysis_{depth}/alpha_rarefaction.qzv"
         .format(depth=config['rarefaction_depth'])
    log: "logs/Make_rarefaction_curves/Make_rarefaction_curves.log"
    threads: 10
    params:
        conda_activate=config["QIIME2_ENV"],
        depth=config['rarefaction_depth']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime diversity alpha-rarefaction \
           --p-max-depth {params.depth} \
           --i-table {input.table} \
           --i-phylogeny {input.tree} \
           --m-metadata-file {input.metadata} \
           --o-visualization {output}
        """


# Alpha Diversity - statistics
# Test for between-group differences
alpha_diversity_metrics=["faith_pd", "observed_features", "shannon", "evenness"]
diversity_dir="10.Diversity_analysis_{depth}".format(depth=config['rarefaction_depth'])

rule Alpha_diversity_statistics:
   input:
        expand(diversity_dir + "/{metric}_vector.qza", metric=alpha_diversity_metrics),
        metadata=config['metadata']
    output:
        expand(diversity_dir + "/alpha_{metric}_significance.qzv", metric=alpha_diversity_metrics)
    log: "logs/Alpha_diversity_statistics/Alpha_diversity_statistics.log"
    threads: 10
    params:
        conda_activate=config["QIIME2_ENV"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u
        
        for metric in {alpha_diversity_metrics}; do
        
            qiime diversity alpha-group-significance \
               --i-alpha-diversity  {diversity_dir}/${{metric}}_vector.qza \
               --m-metadata-file {input.metadata} \
               --o-visualization {diversity_dir}/alpha_${{metric}}_significance.qzv
 
        done
        """

# Beta Diversity - statistics

distance_matrices=["bray_curtis", "jaccard", "unweighted_unifrac", "weighted_unifrac"]

rule Beta_diversity_statistics:
   input:
        expand(diversity_dir + "/{distance}_distance_matrix.qza", distance=distance_matrices),
        metadata=config['metadata']
    output:
        expand(diversity_dir + "/beta_{distance}_significance.qzv", distance=distance_matrices)
    log: "logs/Alpha_diversity_statistics/Alpha_diversity_statistics.log"
    threads: 10
    params:
        conda_activate=config["QIIME2_ENV"],
        category=config['parameters']['group_taxa_plot']['category']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u
        
        for distance in {distance_matrices}; do
        
            qiime diversity beta-group-significance \
               --i-distance-matrix  {diversity_dir}/${{distance}}_distance_matrix.qza \
               --m-metadata-file {input.metadata} \
               --m-metadata-column {params.category} \
               --o-visualization {diversity_dir}/beta_${{distance}}_significance.qzv
 
        done
 
        """


