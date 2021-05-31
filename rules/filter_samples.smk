
# Filter samples based on a provide metadata file
rule Filter_samples:
    input:
        table=rules.Exclude_non_target_taxa.output.table_raw,
        metadata=config['metadata']
    output:
        table_raw="08.Filter_feature_table/samples_filtered_table.qza",
        table_viz="08.Filter_feature_table/samples_filtered_table.qzv"
    log: "logs/Filter_samples/Filter_samples.log"
    threads: 1
    params:
        conda_activate=config["QIIME2_ENV"],
        minumum_frequency=config['minimum_frequency']
    shell:
        """
        set +u
        {params.conda_activate}
        set -u
 
        # Filter samples
        qiime feature-table filter-samples \
            --i-table {input.table} \
            --m-metadata-file {input.metadata} \
            --o-filtered-table {output.table_raw}

        qiime feature-table summarize \
          --i-table {output.table_raw} \
          --o-visualization {output.table_viz}        
        """



# Removing rare taxa i.e. features with abundance less the 0.005%
rule Exclude_rare_taxa:
    input:
        rules.Filter_samples.output.table_raw
    output:
        table_raw="08.Filter_feature_table/filtered_table.qza",
        table_viz="08.Filter_feature_table/filtered_table.qzv"
    log: "logs//Exclude_singletons.log"
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

