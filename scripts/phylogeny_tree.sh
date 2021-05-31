#!/bin/bash
#$ -S /bin/bash
#$ -N make_tree 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'
#IN_PREFIX=('03.dada_denoise/se' '03.dada_denoise/pear-joined' '03.deblur_denoise/se' '03.deblur_denoise/pear-joined')
IN_PREFIX=('03.redo_dada_denoise/se' '03.redo_dada_denoise/pear-joined' '03.redo_dada_denoise/pe' )

#OUT_PREFIX=('06.make_tree/dada2/se' '06.make_tree/dada2/pear-joined' '06.make_tree/deblur/se' '06.make_tree/deblur/pear-joined')
OUT_PREFIX=('06.redo_make_tree/dada2/se' '06.redo_make_tree/dada2/pear-joined' '06.redo_make_tree/dada2/pe')

# Make phylogenetic tree pipeline - all the below in one command
parallel --jobs 0 --link qiime phylogeny align-to-tree-mafft-fasttree \
  		--i-sequences {1}-representative_sequences.qza \
  		--o-alignment {2}-aligned_representative_sequences.qza \
  		--o-masked-alignment {2}-masked_aligned_representative_sequences.qza \
  		--o-tree {2}-unrooted-tree.qza \
  		--o-rooted-tree {2}-rooted-tree.qza ::: ${IN_PREFIX[*]} ::: ${OUT_PREFIX[*]}







#Steps for generating a phylogenetic tree
#qiime alignment mafft \
#		--i-sequences representative_sequences.qza \
#		--o-alignment aligned_representative_sequences

#qiime alignment mask \
#		--i-alignment aligned_representative_sequences.qza \
#		--o-masked-alignment masked_aligned_representative_sequences

#qiime phylogeny fasttree \
#		--i-alignment masked_aligned_representative_sequences.qza \
#		--o-tree unrooted_tree

#qiime phylogeny midpoint-root \
#		--i-tree unrooted_tree.qza \
#		--o-rooted-tree rooted_tree
