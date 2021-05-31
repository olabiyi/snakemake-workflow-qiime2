

# associate the representative sequences with their taxonomic annotations
qiime metadata tabulate \
  --m-input-file rep-seqs.qza \
  --m-input-file taxonomy.qza \
  --o-visualization tabulated-feature-metadata.qzv


# Metadata merging is supported anywhere that metadata is accepted in QIIME 2. For example, it might be interesting to color an Emperor plot based on the study metadata, or sample alpha diversity. This can be accomplished by providing both the sample metadata file and the SampleData[AlphaDiversity] artifact:
qiime emperor plot \
  --i-pcoa unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-file faith_pd_vector.qza \
  --o-visualization unweighted-unifrac-emperor-with-alpha.qzv



# Merging metadata
# Since metadata can come from many different sources, QIIME 2 supports metadata merging when running commands. Building upon the examples above, simply passing --m-input-file multiple times will combine the metadata columns in the specified files
qiime metadata tabulate \
  --m-input-file sample-metadata.tsv \
  --m-input-file faith_pd_vector.qza \
  --o-visualization tabulated-combined-metadata.qzv

# To view an artifact as metadata, simply pass it in to any method or visualizer that expects to see metadata (e.g. metadata tabulate or emperor plot):
qiime metadata tabulate \
  --m-input-file faith_pd_vector.qza \
  --o-visualization tabulated-faith-pd-metadata.qzv

# Tabulate your mapping file with QIIME2
qiime metadata tabulate \
  --m-input-file sample-metadata.tsv \
  --o-visualization tabulated-sample-metadata.qzv
