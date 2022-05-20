from os import path, getcwd
import pandas as pd

# Run the pipeline like so:
# snakemake -pr --cores 10 --keep-going --rerun-incomplete --restart-times 3
# snakemake -s Snakefile --rulegraph |dot -Tpng > rulegraph.pn
configfile: "config/config.yaml"

onsuccess:
    print("Workflow completed without any error")


mail=config['mail']
onerror:
    print("An error occurred")
    #shell("mail -s 'An error occurred' {mail} < {log}")


sample_file = config["sample_file"]
metadata = pd.read_table(sample_file)

mode=config['mode']
merge_method=config['merge_method']
denoise_method=config['denoise_method']

diversity_dir = "10.Diversity_analysis_{depth}".format(depth=config['rarefaction_depth'])
alpha_diversity_metrics=["faith_pd", "observed_features", "shannon", "evenness"]
distance_matrices=["bray_curtis", "jaccard", "unweighted_unifrac", "weighted_unifrac"]

TAXON_LEVELS=[2, 3, 4, 5, 6, 7]

RULES=["Rename_files", "Merge_reads", "QC_pre_trim", "SummarizeQC_pre_trim", "Import_sequences",
       "Trim_primers","Qaulity_check_raw","Qaulity_check_trimmed", "Denoise_reads", "Summarize_feature_table",
       "Tabulate_sequences", "Tabulate_denoise_statistics", "Assign_taxonomy",
       "Build_phylogenetic_tree", "Exclude_singletons", "Exclude_non_target_taxa",
       "Exclude_rare_taxa", "Samples_taxa_bar_plot", "Group_taxa_bar_plot",
       "Core_diversity_analysis", "Make_rarefaction_curves", "Alpha_diversity_statistics",
       "Beta_diversity_statistics", "Collapse_tables", "Rename_asv_table",
       "Add_pseudocount", "Ancom_differential_abundance", "Export_tables",
       "Function_annotation", "Add_description"]

if mode == "pair" or mode == "merge":

    READS=expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz", "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples'])

else:

    READS=expand(["01.raw_data/{sample}/{sample}.fastq.gz"], sample=config['samples'])


rule all:
    input:
# ------------->>>>>>  You need to edit this rule to be project specific <<<<<------------ #
        #expand("01.raw_data/{sample}.fastq.gz", sample=config['samples']), -> SINGLE-END  # uncomment if you want to rename your files
#        expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz",
#                "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples']), -> PAIRED-END # uncomment if you want to rename your file
        READS,
#        expand("02.merge_reads/{sample}/{sample}.fastq.gz", sample=config['samples']),
        "02.QC/pre_trim/multiqc_report.html",
        "03.import/reads.qza",
        "04.QC/raw_reads_qual_viz.qzv",
        "04.QC/trimmed_reads_qual_viz.qzv",
        "05.Denoise_reads/table_summary.qzv",
        "05.Denoise_reads/representative_sequences.qzv",
        "05.Denoise_reads/denoise_stats.qzv",
        "06.Assign_taxonomy/taxonomy.qza",
        "07.Build_phylogenetic_tree/rooted-tree.qza",
        "09.Taxa_bar_plots/samples-bar-plots.qzv",
        "09.Taxa_bar_plots/group-bar-plot.qzv",
        expand(diversity_dir + "/alpha_{metric}_significance.qzv", metric=alpha_diversity_metrics),
        expand(diversity_dir + "/beta_{distance}_significance.qzv", distance=distance_matrices),
        "10.Diversity_analysis_{depth}/alpha_rarefaction.qzv".format(depth=config['rarefaction_depth']),
        expand("13.Ancom_differential_abundance/L{taxon_level}-ancom.qzv", taxon_level=TAXON_LEVELS),
        "15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv"       
        

# This rule will make rule specific log directories
# # in order to easily store the standard input and standard error
# # generated when submiting jobs to the cluster
rule Make_logs_directories:
    output:
        directory("logs/Rename_files/"),
        directory("logs/QC_pre_trim/"),
        directory("logs/SummarizeQC_pre_trim/"),
        directory("logs/Import_sequences/"),
        directory("logs/Trim_primers/"),
        directory("logs/Qaulity_check_raw/"),
        directory("logs/Summarize_feature_table/"),
        directory("logs/Tabulate_sequences/"),
        directory("logs/Tabulate_denoise_statistics/"),
        directory("logs/Samples_taxa_bar_plot/"),
        directory("logs/Group_taxa_bar_plot/"),
        directory("logs/Make_rarefaction_curves/"),
        directory("logs/Alpha_diversity_statistics/"),
        directory("logs/Beta_diversity_statistics/"),
        directory("logs/Ancom_differential_abundance/"),
        directory("logs/Function_annotation/"),
        directory("logs/Add_description/")
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
# ------------->>>>>>  You need to edit this rule to be project specific <<<<<------------ #

if config['RENAME_FILES']:
    # Remaning paired-end files
    if mode == "pair" or mode == "merge":

        rule Rename_files:
            input: log_dirs=rules.Make_logs_directories.output
            output:
                expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz",
                        "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples'])
            log: "logs/Rename_files/Rename_files.log"
            threads: 5
            run:
                for old,new in zip(metadata.Old_name,metadata.New_name):
                    shell("[ -f {new} ] || mv {old} {new}".format(old=old, new=new))
    else:
    # Renaming single-end files
        rule Rename_files:
            output:
                expand("01.raw_data/{sample}.fastq.gz",sample=config['samples'])
            log: "logs/Rename_files/Rename_files.log"
            threads: 5
            run:
                for old,new in zip(metadata.Old_name,metadata.New_name):
                    shell("mv {old} {new}".format(old=old, new=new))



rule QC_pre_trim:
    input:
        forward="01.raw_data/{sample}/{sample}_R1.fastq.gz",
        rev="01.raw_data/{sample}/{sample}_R2.fastq.gz",
        log_dirs=rules.Make_logs_directories.output
    output:
        forward_html="02.QC/pre_trim/{sample}/{sample}_R1_fastqc.html",
        rev_html="02.QC/pre_trim/{sample}/{sample}_R2_fastqc.html"
    params:
        program=config['programs_path']['fastqc'],
        out_dir=lambda w, output: path.dirname(output[0]),
        conda_activate=config['conda']['bioinfo']['env'],
        PERL5LIB=config['conda']['bioinfo']['perl5lib'],
        threads=5
    log: "logs/QC_pre_trim/{sample}/{sample}_QC_pre_trim.log"
    threads: 5
    shell:
        """
        set +u
        {params.conda_activate}
        {params.PERL5LIB}
        set -u

          {params.program} --outdir {params.out_dir}/ \
             --threads {params.threads} {input.forward} {input.rev}

        """

rule SummarizeQC_pre_trim:
    input:
        forward_html=expand("02.QC/pre_trim/{sample}/{sample}_R1_fastqc.html",
                            sample=config['samples']),
        rev_html=expand("02.QC/pre_trim/{sample}/{sample}_R2_fastqc.html",
                            sample=config['samples'])
    output:
        "02.QC/pre_trim/multiqc_report.html"
    log: "logs/SummarizeQC_pre_trim/multiqc.log"
    params:
        program=config['programs_path']['multiqc'],
        out_dir=lambda w, output: path.dirname(output[0]),
        conda_activate=config['conda']['bioinfo']['env'],
        PERL5LIB=config['conda']['bioinfo']['perl5lib']
    threads: 1
    shell:
        """
        set +u
        {params.conda_activate}
        {params.PERL5LIB}
        set -u

          {params.program} \
              --interactive \
              -f {params.out_dir} \
              -o {params.out_dir}
        """


if mode == "pair":

    # Import pe-sequnces to qiime
    # Make sure you have a paired end specific manifest file - see example in examples folder
    rule Import_sequences:
        input: 
           expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz",
                  "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples']),
           manifest_file=config["MANIFEST"]
        output: "03.import/reads.qza"
        log: "logs/Import_sequences/Import_sequences.log"
        threads: 5
        params:
            conda_activate=config["conda"]["qiime2"]["env"],
            seq_dir=lambda w, input: path.dirname(input[0]).split('/')[0]
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime tools import \
                 --type 'SampleData[PairedEndSequencesWithQuality]' \
                 --input-path {input.manifest_file} \
                 --output-path {output} \
                 --input-format PairedEndFastqManifestPhred33
            """

    rule Trim_primers:
        input: rules.Import_sequences.output
        output: "04.Trim_primers/trimmed_reads.qza"
        log: "logs/Trim_primers/Trim_primers.log"
        threads: 10
        params:
            conda_activate=config["conda"]["qiime2"]["env"],
            forward_primer=config['parameters']['cutadapt']['forward_primer'],
            reverse_primer=config['parameters']['cutadapt']['reverse_primer'],
            cores=config['parameters']['cutadapt']['cores'],
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime cutadapt trim-paired \
                 --i-demultiplexed-sequences {input} \
                 --p-cores {params.cores} \
                 --p-front-f {params.forward_primer} \
                 --p-front-r {params.reverse_primer} \
                 --o-trimmed-sequences {output} \
                 --verbose

            """


elif mode == "single":

    # Import se-sequnces to qiime
    rule Import_sequences:
        input: 
            expand("01.raw_data/{sample}.fastq.gz", sample=config['samples']),
            manifest_file=config["MANIFEST"]
        output: "03.import/reads.qza"
        log: "logs/Import_sequences/Import_sequences.log"
        threads: 5
        params:
            conda_activate=config["conda"]["qiime2"]["env"],
            seq_dir=lambda w, input: path.dirname(input[0])
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime tools import \
                 --type 'SampleData[SequencesWithQuality]' \
                 --input-path {input.manifest_file} \
                 --output-path {output} \
                 --input-format SingleEndFastqManifestPhred33
            """

    rule Trim_primers:
        input: rules.Import_sequences.output
        output: "04.Trim_primers/trimmed_reads.qza"
        log: "logs/Trim_primers/Trim_primers.log"
        threads: 10
        params:
            conda_activate=config["conda"]["qiime2"]["env"],
            forward_primer=config['parameters']['cutadapt']['forward_primer'],
            cores=config['parameters']['cutadapt']['cores'],
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            qiime cutadapt trim-single \
                 --i-demultiplexed-sequences {input} \
                 --p-cores {params.cores} \
                 --p-front {params.forward_primer} \
                 --o-trimmed-sequences {output} \
                 --verbose

            """



elif mode == "merge":

    if merge_method == "pear":

#        # Merge paired-end reads using pear - modifify the -m -t flags of pear before running the workflow    
#        rule Merge_reads:
#            input:
#                expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz", 
#                       "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples'])
#            output:
#                expand("02.merge_reads/{sample}/{sample}.fastq.gz", sample=config['samples'])
#            log: "logs/Merge_reads/Merge_reads.log"
#            threads: 5
#            params:
#                out_dir=lambda w, output: path.dirname(output[0]),
#                in_dir=lambda w, input: path.dirname(input[0]).dirname,
#                program=config['programs_path']['run_pear'],
#                conda_activate=config['conda']['bioinfo']['env'],
#                PERL5LIB=config['conda']['bioinfo']['perl5lib']
#
#            shell:
#                """
#                set +u
#                {params.conda_activate}
#                {params.PERL5LIB}
#                set -u
#                
#
#                FILES=$(find)
#                # Merge reads then delete unnecessary files
#                 {params.program} -o {params.out_dir}/  {params.in_dir}/*.fastq.gz && \
#                 rm -rf {params.out_dir}/*.unassembled* {params.out_dir}/*discarded*
#         
#               # gzip to save memory
#         
#                 gzip {params.out_dir}/*.fastq
#
#                """
        # Merge paired-end reads using pear - modifify the -m -t flags of pear before running the workflow    
        rule Merge_reads:
            input:
                forward="01.raw_data/{sample}/{sample}_R1.fastq.gz",
                rev="01.raw_data/{sample}/{sample}_R2.fastq.gz"
            output: "02.merge_reads/{sample}/{sample}.fastq.gz"
            log: "logs/Merge_reads/{sample}/{sample}.log"
            threads: 5
            params:
                out_dir=lambda w, output: path.dirname(output[0]),
                program=config['programs_path']['run_pear'],
                conda_activate=config['conda']['pear']['env'],
                min=config['parameters']['pear']['min_assembly'],
                max=config['parameters']['pear']['max_assembly'],
                min_trim=config['parameters']['pear']['min_trim'],
                threads=config['parameters']['pear']['threads']

            shell:
                """
                {params.conda_activate}
               
                 [ -d {params.out_dir} ] ||  mkdir -p {params.out_dir}
                 # Merge reads then delete unnecessary files
                 {params.program} \
                    -f {input.forward} \
                    -r {input.rev} \
                    -j {params.threads} \
                    -o {params.out_dir}/{wildcards.sample} \
                    -m {params.max} \
                    -n {params.min} \
                    -t {params.min_trim} > {log} 2>&1


                 rm -rf \
                   {params.out_dir}/{wildcards.sample}.discarded.fastq \
                   {params.out_dir}/{wildcards.sample}.unassembled.forward.fastq \
                   {params.out_dir}/{wildcards.sample}.unassembled.reverse.fastq 

                 mv {params.out_dir}/{wildcards.sample}.assembled.fastq {params.out_dir}/{wildcards.sample}.fastq
         
                 # gzip to save memory
         
                 gzip {params.out_dir}/{wildcards.sample}.fastq

               """



        # Import pe-joined reads to qiime
        rule Import_sequences:
            input: 
                expand("02.merge_reads/{sample}/{sample}.fastq.gz", sample=config['samples']),
                manifest_file=config["MANIFEST"]
            output: "03.import/reads.qza"
            log: "logs/Import_sequences/Import_sequences.log"
            threads: 5
            params:
                conda_activate=config["conda"]["qiime2"]["env"],
                seq_dir=lambda w, input: path.dirname(input[0])
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime tools import \
                     --type 'SampleData[SequencesWithQuality]' \
                     --input-path {input.manifest_file} \
                     --output-path {output} \
                     --input-format SingleEndFastqManifestPhred33
                """

        rule Trim_primers:
            input: rules.Import_sequences.output
            output: "04.Trim_primers/trimmed_reads.qza"
            log: "logs/Trim_primers/Trim_primers.log"
            threads: 10
            params:
                conda_activate=config["conda"]["qiime2"]["env"],
                forward_primer=config['parameters']['cutadapt']['forward_primer'],
                cores=config['parameters']['cutadapt']['cores'],
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime cutadapt trim-single \
                     --i-demultiplexed-sequences {input} \
                     --p-cores {params.cores} \
                     --p-front {params.forward_primer} \
                     --o-trimmed-sequences {output} \
                     --verbose
                """

    elif merge_method == "vsearch":

        rule Import_sequences:
            input:
               expand(["01.raw_data/{sample}/{sample}_R1.fastq.gz",
                      "01.raw_data/{sample}/{sample}_R2.fastq.gz"], sample=config['samples']),
               manifest_file=config["MANIFEST"]
            output: "03.import/reads.qza"
            log: "logs/Import_sequences/Import_sequences.log"
            threads: 5
            params:
                conda_activate=config["conda"]["qiime2"]["env"],
                seq_dir=lambda w, input: path.dirname(input[0]).split('/')[0]
            shell:
                """
                set +u
                {params.conda_activate}
                set -u

                qiime tools import \
                     --type 'SampleData[PairedEndSequencesWithQuality]' \
                     --input-path {input.manifest_file} \
                     --output-path {output} \
                     --input-format PairedEndFastqManifestPhred33
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
 
        rule Trim_primers:
            input: rules.Merge_reads.output
            output: "04.Trim_primers/trimmed_reads.qza"
            log: "logs/Trim_primers/Trim_primers.log"
            threads: 10
            params:
                conda_activate=config["conda"]["qiime2"]["env"],
                forward_primer=config['parameters']['cutadapt']['forward_primer'],
                cores=config['parameters']['cutadapt']['cores'],
            shell:
                """
                set +u
                {params.conda_activate}
                set -u
            
                qiime cutadapt trim-single \
                     --i-demultiplexed-sequences {input} \
                     --p-cores {params.cores} \
                     --p-front {params.forward_primer} \
                     --o-trimmed-sequences {output} \
                     --verbose
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
            conda_activate=config["conda"]["qiime2"]["env"]
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


    rule Qaulity_check_raw:
        input: rules.Import_sequences.output
        output: "04.QC/raw_reads_qual_viz.qzv"
        log: "logs/Qaulity_check/Qaulity_check.log"
        threads: 10
        params:
            conda_activate=config["conda"]["qiime2"]["env"]
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

# quality check after trimming adaptors and primers using cudadapt
    rule Qaulity_check_trimmed:
        input: rules.Trim_primers.output
        output: "04.QC/trimmed_reads_qual_viz.qzv"
        log: "logs/Qaulity_check/Qaulity_check.log"
        threads: 10
        params:
            conda_activate=config["conda"]["qiime2"]["env"]
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
        input: rules.Trim_primers.output #rules.Import_sequences.output
        output: 
            table="05.Denoise_reads/table.qza",
            rep_seqs="05.Denoise_reads/representative_sequences.qza",
            stats="05.Denoise_reads/denoise_stats.qza"
        log: "logs/Denoise_reads/Denoise_reads.log"
        threads: 30
        params:
            conda_activate=config["conda"]["qiime2"]["env"],
            mode=config['parameters']['dada2']['mode'],
            trun_len_forward=config['parameters']['dada2']['trunc_length_forward'],
            trun_len_reverse=config['parameters']['dada2']['trunc_length_reverse'],
            trim_len_forward=config['parameters']['dada2']['trim_length_forward'],
            trim_len_reverse=config['parameters']['dada2']['trim_length_reverse'],
            max_forward_err=config['parameters']['dada2']['maximum_forward_error'],
            max_reverse_err=config['parameters']['dada2']['maximum_reverse_error'],
            threads=config['parameters']['dada2']['threads']
        shell:
            """
            set +u
            {params.conda_activate}
            set -u
            
            MODE={params.mode}

            if [ ${{MODE}} == "paired" ];then

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
                    --p-max-ee-f {params.max_forward_err} \
                    --p-max-ee-r {params.max_reverse_err} \
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
                    --p-max-ee {params.max_forward_err} \
                    --p-n-threads {params.threads}

            fi
      
            """


elif ASV_method == "deblur":

    # Denoise using deblur
    rule Denoise_reads:
        input: rules.Trim_primers.output #rules.Import_sequences.output
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
            conda_activate=config["conda"]["qiime2"]["env"],
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
        conda_activate=config["conda"]["qiime2"]["env"]
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
        conda_activate=config["conda"]["qiime2"]["env"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime feature-table tabulate-seqs \
           --i-data {input} \
           --o-visualization {output}
        """


if denoise_method == "dada2":

    rule Tabulate_denoise_statistics:
        input: rules.Denoise_reads.output.stats
        output: "05.Denoise_reads/denoise_stats.qzv"
        log: "logs/Tabulate_denoise_statistics/Tabulate_denoise_statistics.log"
        threads: 1
        params:
            conda_activate=config["conda"]["qiime2"]["env"]
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
            conda_activate=config["conda"]["qiime2"]["env"]
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
        conda_activate=config["conda"]["qiime2"]["env"],
        threads=config["parameters"]["assign_taxonomy"]["threads"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

         # Assign taxonomy
         qiime feature-classifier classify-sklearn \
           --i-classifier {input.classifier} \
           --i-reads {input.rep_seqs} \
           --o-classification {output.raw} \
           --p-n-jobs {params.threads}

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
        conda_activate=config["conda"]["qiime2"]["env"],
        threads=config["parameters"]["fastree"]["threads"]
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
           --o-rooted-tree {output.rooted_tree} \
           --p-n-threads {params.threads}
        """


# ----------------------------------- Filter feature table ------------------------------------ #

# Edit the taxa listed below as required

# Remove singletons and non-target sequences e.g chloroplast, mitochondria, archaea and eukaryota
# for protists - Bacteria,Fungi,Chytridiomycota,Basidiomycota,Metazoa,Rotifera,Gastrotricha,
# Nematozoa,Euglenozoa,Embryophyta,Spermatophyta,Asterales,Brassicales,Caryophyllales,Cupressales,
# Fabales,Malpighiales,Pinales,Rosales,Solanales,Arecales,Asparagales,Poales,Capsicum,Jatropha,
# Bryophyta,Tracheophyta

if config['amplicon'] == "16S":
    taxa2filter = "Unassigned,Chloroplast,Mitochondria,Eukaryota"

elif config['amplicon'] == "18S":
    taxa2filter = "Bacteria,Fungi,Chytridiomycota,Basidiomycota,Metazoa,Rotifera,"
    "Gastrotricha,Nematozoa,Embryophyta,Spermatophyta,Asterales,"
    "Brassicales,Caryophyllales,Cupressales,Fabales,Malpighiales,"
    "Pinales,Rosales,Solanales,Arecales,Asparagales,Poales,"
    "Capsicum,Jatropha,Bryophyta,Tracheophyta"

elif config['amplicon'] == "ITS":
    taxa2filter = "Fungi"



rule Exclude_singletons:
    input:
        rules.Denoise_reads.output.table
    output:
        table_raw="08.Filter_feature_table/noSingleton_filtered_table.qza",
        table_viz="08.Filter_feature_table/noSingleton_filtered_table.qzv"
    log: "logs/Exclude_singletons/Exclude_singletons.log"
    threads: 1
    params:
        conda_activate=config["conda"]["qiime2"]["env"]
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
        taxonomy=rules.Assign_taxonomy.output.raw
    output: 
        table_raw="08.Filter_feature_table/taxa_filtered_table.qza",
        table_viz="08.Filter_feature_table/taxa_filtered_table.qzv"
    log: "logs/Exclude_non_target_taxa/Exclude_non_target_taxa.log"
    threads: 1
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
        out_dir=lambda w, output: path.dirname(output.table_raw),
        taxa2exclude=taxa2filter,
        amplicon=config['amplicon']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Filter out non-target assigments
        if [ {params.amplicon} == "ITS" ]; then
 
            # Retain only Fungi sequences
            qiime taxa filter-table \
              --i-table {input.table} \
              --i-taxonomy  {input.taxonomy} \
              --p-include  {params.taxa2exclude} \
              --o-filtered-table {output.table_raw}


        else

            # Filter out non-target assigments
            qiime taxa filter-table \
              --i-table {input.table} \
              --i-taxonomy  {input.taxonomy} \
              --p-exclude  {params.taxa2exclude} \
              --o-filtered-table {output.table_raw}
        
        fi

        # To figure out the total number of sequences ("Total freqency") 
        # to be used to determine the minuminum frequency for filtering out
        # rare taxa. to calculate the multiply the total number of sequences
        # by 0.005
        qiime feature-table summarize \
          --i-table {output.table_raw} \
          --o-visualization {output.table_viz}
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
        conda_activate=config["conda"]["qiime2"]["env"],
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
        taxonomy=rules.Assign_taxonomy.output.raw,
        metadata=config['metadata']
    output: "09.Taxa_bar_plots/samples-bar-plots.qzv"
    log: "logs/Samples_taxa_bar_plots/Samples_taxa_bar_plots.log"
    threads: 5
    params:
        conda_activate=config["conda"]["qiime2"]["env"]
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
        taxonomy=rules.Assign_taxonomy.output.raw,
        metadata=config['metadata']
    output: 
         grouped_table="09.Taxa_bar_plots/grouped-filtered_table.qza",
         bar_plot="09.Taxa_bar_plots/group-bar-plot.qzv"
    log: "logs/Group_taxa_bar_plot/Group_taxa_bar_plot.log"
    threads: 5
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
        category=config['parameters']['group_taxa_plot']['category'],
        mode=config['parameters']['group_taxa_plot']['mode'],
        metadata=config['parameters']['group_taxa_plot']['metadata']
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
            --m-metadata-column '{params.category}' \
            --p-mode {params.mode} \
            --o-grouped-table {output.grouped_table}

        # Grouped bar plot
        qiime taxa barplot \
          --i-table {output.grouped_table} \
          --i-taxonomy {input.taxonomy} \
          --m-metadata-file {params.metadata} \
          --o-visualization  {output.bar_plot}
      """


# -----------------------------------  Alpha and Beta diversity -------------------------------------#

# Test for between-group differences
alpha_diversity_metrics=["faith_pd", "observed_features", "shannon", "evenness"]
diversity_dir="10.Diversity_analysis_{depth}".format(depth=config['rarefaction_depth'])
distance_matrices=["bray_curtis", "jaccard", "unweighted_unifrac", "weighted_unifrac"]

# Perform core diversity analysis - output are directory with various
# alpha and beta diversity metrics
rule Core_diversity_analysis:
    input:
        table=rules.Exclude_rare_taxa.output.table_raw,
        metadata=config['metadata'],
        tree=rules.Build_phylogenetic_tree.output.rooted_tree
    output:
        expand(diversity_dir + "/{metric}_vector.qza", metric=alpha_diversity_metrics),
        expand(diversity_dir + "/{distance}_distance_matrix.qza", distance=distance_matrices)   
    log: "logs/Core_diversity_analysis/Core_diversity_analysis.log"
    threads: 10
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
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
           --p-n-jobs-or-threads 'auto' \
           --output-dir core_diversity/  && \
           mv core_diversity/* {diversity_dir}/ && \
           rm -rf core_diversity/
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
        conda_activate=config["conda"]["qiime2"]["env"],
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

rule Alpha_diversity_statistics:
    input:
        expand(diversity_dir + "/{metric}_vector.qza", metric=alpha_diversity_metrics),
        metadata=config['metadata']
    output:
        expand(diversity_dir + "/alpha_{metric}_significance.qzv", metric=alpha_diversity_metrics)
    log: "logs/Alpha_diversity_statistics/Alpha_diversity_statistics.log"
    threads: 10
    params:
        conda_activate=config["conda"]["qiime2"]["env"]
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


rule Beta_diversity_statistics:
    input:
        expand(diversity_dir + "/{distance}_distance_matrix.qza", distance=distance_matrices),
        metadata=config['metadata']
    output:
        expand(diversity_dir + "/beta_{distance}_significance.qzv", distance=distance_matrices)
    log: "logs/Alpha_diversity_statistics/Alpha_diversity_statistics.log"
    threads: 10
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
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

# ---------------------- Differntial abundance testing using ANCOM  ---------------------------- #

# 2, 3, 4, 5, 6 for phylum, class, order, family, genus, respectively.
TAXON_LEVELS=[2, 3, 4, 5, 6]

# Collapse ASV table at the different taxonomy levels
rule Collapse_tables:
    input: 
        table=rules.Exclude_rare_taxa.output.table_raw,
        taxonomy=rules.Assign_taxonomy.output.raw
    output: expand("11.collapse_tables/L{taxon_level}-filtered_table.qza", taxon_level=TAXON_LEVELS)
    log: "logs/Collapse_tables/Collapse_tables.log"
    threads: 10
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
        out_dir=lambda w, output: path.dirname(output[0])
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        TAXON_LEVELS=(2 3 4 5 6)

        for TAXON_LEVEL in ${{TAXON_LEVELS[*]}}; do

            # Collapse ASV table at a taxonomy level of interest
            qiime taxa collapse \
                --i-table {input.table} \
                --i-taxonomy {input.taxonomy} \
                --p-level ${{TAXON_LEVEL}} \
                --o-collapsed-table {params.out_dir}/L${{TAXON_LEVEL}}-filtered_table.qza

        done
        """

# Copy and rename the ASV table as species table L7 in order
# to avoid repeated code in the steps below
rule Rename_asv_table:
    input: 
        rules.Exclude_rare_taxa.output.table_raw
    output: "11.collapse_tables/L7-filtered_table.qza"
    log: "logs/Rename_asv_table/Rename_asv_table.log"
    threads: 1
    params:
        out_dir=lambda w, output: path.dirname(output[0]),
        basename=lambda w, input: path.basename(input[0])
    shell:
        "cp {input} {params.out_dir}/  && "
        "mv {params.out_dir}/{params.basename} {output}"


# 2, 3, 4, 5, 6 for phylum, class, order, family, genus, asv/species respectively.
#TAXON_LEVELS=[2, 3, 4, 5, 6, 7]
# Add pseudocount to ASV table because ANCOM can't deal with zero counts
rule  Add_pseudocount:
    input: "11.collapse_tables/L{taxon_level}-filtered_table.qza"
    output: "12.Add_pseudocount/L{taxon_level}-composition_table.qza"     
    log: "logs/Add_pseudocount/L{taxon_level}-Add_pseudocount.log"
    threads: 1
    params:
        conda_activate=config["conda"]["qiime2"]["env"]
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        qiime composition add-pseudocount \
            --i-table {input} \
            --o-composition-table {output}

        """

# Perform taxa differential abundance testing using ANCOM
rule  Ancom_differential_abundance:
    input: 
        table="12.Add_pseudocount/L{taxon_level}-composition_table.qza",
        metadata=config['metadata']
    output: 
        "13.Ancom_differential_abundance/L{taxon_level}-ancom.qzv"
    log: "logs/Ancom_differential_abundance/L{taxon_level}_Ancom_differential_abundance.log"
    threads: 5
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
        category=config['category']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Apply ANCOM to identify ASV/OTUs that differ in abundance
        qiime composition ancom \
            --i-table {input.table} \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {params.category} \
            --o-visualization {output}
            
        """

# Export feature table, taxonomy table and reprentative sequences
rule Export_tables:
    input:
        feature_table=rules.Exclude_rare_taxa.output.table_raw,
        taxonomy_table=rules.Assign_taxonomy.output.raw,
        rep_seqs=rules.Denoise_reads.output.rep_seqs
    output:
        feature_table_biom="14.Export_tables/feature-table.biom", # table without taxonomy
        feature_table_taxonomy="14.Export_tables/feature-table-with-taxonomy.biom", # table with taxonomy added
        taxonomy_table="14.Export_tables/taxonomy.tsv",
        rep_seqs="14.Export_tables/representative-sequences.fasta"
    log: "logs/Export_tables/Export_tables.log"
    threads: 2
    params:
        conda_activate=config["conda"]["qiime2"]["env"],
        out_dir=lambda w, output: path.dirname(output.rep_seqs)
    shell:
        """
        set +u
        {params.conda_activate}
        set -u

        # Export feature table
        qiime tools export \
           --input-path {input.feature_table} \
           --output-path {params.out_dir}/
        

        # Export representative sequences
        qiime tools export --input-path {input.rep_seqs} --output-path {params.out_dir}/ && \
        mv {params.out_dir}/dna-sequences.fasta  {output.rep_seqs}

        # Export taxonomy
        qiime tools export \
             --input-path {input.taxonomy_table} \
             --output-path {params.out_dir}/

       
        # ---------------------- Add taxonomy to feature table ------------------------ #
        
        # Creating a TSV BIOM table
        biom convert \
            -i {params.out_dir}/feature-table.biom \
            -o {params.out_dir}/feature-table.tsv \
            --to-tsv
       
        # Next, we’ll need to modify the exported taxonomy file’s header before using it with BIOM software.
     
        # Before modifying that file, make a copy:
        cp {params.out_dir}/taxonomy.tsv {params.out_dir}/biom-taxonomy.tsv

        # Change the first line of biom-taxonomy.tsv (i.e. the header) to this:
        # Note that you’ll need to use tab characters in the header since this is a TSV file.
        #OTUID	taxonomy	confidence   

        (echo "#OTUID	taxonomy	confidence"; sed -e '1d' {params.out_dir}/biom-taxonomy.tsv) \
         > {params.out_dir}/tmp.tsv && \
         rm -rf {params.out_dir}/biom-taxonomy.tsv && \
         mv {params.out_dir}/tmp.tsv {params.out_dir}/biom-taxonomy.tsv 

        # Finally, add the taxonomy data to your .biom file:
        biom add-metadata \
             -i {params.out_dir}/feature-table.biom \
             -o {params.out_dir}/feature-table-with-taxonomy.biom \
             --observation-metadata-fp {params.out_dir}/biom-taxonomy.tsv \
             --sc-separated taxonomy

        # Creating a TSV BIOM table
        biom convert \
               -i  {params.out_dir}/feature-table-with-taxonomy.biom  \
               -o  {params.out_dir}/feature-table-with-taxonomy.biom.tsv \
               --to-tsv
        """
    
def get_out_dir(w, output):
    parts = output.ec.split('/')
    return parts[0] + "/" + parts[1]

if config['amplicon'] == "16S":

    # ------------------ Function analysis using Picrust2 -----------------#

    rule Function_annotation:
        input:
            feature_table=rules.Export_tables.output.feature_table_biom,
            rep_seqs=rules.Export_tables.output.rep_seqs
        output:
            ec="15.Function_annotation/picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat.tsv.gz",
            ko="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat.tsv.gz",
            pathway="15.Function_annotation/picrust2_out_pipeline/pathways_out/path_abun_unstrat.tsv.gz",
            #contrib="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_contrib.tsv.gz"
        log: "logs/Function_annotation/Function_annotation.log"
        threads: 10
        params:
            conda_activate=config['conda']['picrust2']["env"],
            out_dir=lambda w, output: output.ec.split('/')[0] + "/" + output.ec.split('/')[1],
            threads=config['parameters']['picrust']['threads']
        shell:
            """
            set +u
            {params.conda_activate}
            set -u
        
            # Remove the temporary output directory if it already exists
            [ -d picrust2_out_pipeline/ ] && rm -rf picrust2_out_pipeline/
        
            # ---- Run picrust2 pipeline for function annotation -------- #
            picrust2_pipeline.py \
                -s {input.rep_seqs} \
                -i {input.feature_table} \
                -o picrust2_out_pipeline/ \
                -p {params.threads} && \
                mv picrust2_out_pipeline/* {params.out_dir}/ && \
                rmdir picrust2_out_pipeline/
            """

    # Add description to PICRUST2 function annotation tables
    rule Add_description:
        input:
            ec=rules.Function_annotation.output.ec,
            ko=rules.Function_annotation.output.ko,
            pathway=rules.Function_annotation.output.pathway,
            #contrib=rules.Function_annotation.output.contrib
        output:
            ec="15.Function_annotation/picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv",
            ko="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv",
            pathway="15.Function_annotation/picrust2_out_pipeline/pathways_out/path_abun_unstrat_descrip.tsv",
            #ec_contrib="15.Function_annotation/picrust2_out_pipeline/EC_metagenome_out/pred_metagenome_contrib.tsv",
            #ko_contrib="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_contrib.tsv",
            #pathway_contrib="15.Function_annotation/picrust2_out_pipeline/pathways_out/path_abun_contrib.tsv"
        log: "logs/Add_description/Add_description.log"
        threads: 10
        params:
            conda_activate=config['conda']['picrust2']["env"],
            threads=10,
            outdir="15.Function_annotation/picrust2_out_pipeline/"
        shell:
            """
            set +u
            {params.conda_activate}
            set -u

            # ----- Annotate your enzymes, KOs and pathways by adding a description column ------#
            # EC
            add_descriptions.py -i {input.ec} -m EC -o {output.ec}

            # Metacyc Pathway
            add_descriptions.py -i {input.pathway} -m METACYC -o {output.pathway}

            # KO
            add_descriptions.py -i {input.ko} -m KO -o {output.ko} 
 
            # Unizip the metagenome contribution files - these files describe the micribes contribution the function profiles
            #find {params.outdir} -type f -name "*contrib.tsv.gz" -exec gunzip {{}} \;
            """

else:
    # This is a dummy rule that just creates an empty file
    rule Add_description:
        input:
            feature_table=rules.Export_tables.output.feature_table_biom
        output:
            ko="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv"
        log: "logs/Add_description/Add_description.log"
        threads: 1
        params:
            outdir="15.Function_annotation/picrust2_out_pipeline/KO_metagenome_out"
        shell:
            """
                # Create an empty file
                mkdir -p {params.outdir} && touch {output.ko}
            """

