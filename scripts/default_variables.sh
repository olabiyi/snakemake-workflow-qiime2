#!/bin/bash
#$ -S /bin/bash
#$ -N diversity_analysis
#$ -q bioinfo.q
#$ -V
#$ -cwd
#$ -notify
#$ -pe shared 40


set -e

source activate qiime2-2020.6
export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'

TREE=('06.make_tree/dada2' '06.make_tree/dada2' '06.make_tree/deblur' '06.make_tree/deblur' '06.make_tree/dada2' '06.make_tree/dada2' '06.make_tree/deblur' '06.make_tree/deblur' '06.make_tree/dada2' '06.make_tree/dada2' '06.make_tree/deblur' '06.make_tree/deblur' '06.make_tree/dada2' '06.make_tree/dada2' '06.make_tree/deblur' '06.make_tree/deblur')

DEPTH=(1201 1035 1003 501 1201 1276 617 480 3116 989 726 400 2140 2115 1484 1260)

FEATURE_TABLE_DIR=('05.filter_table/dada2' '05.filter_table/dada2' '05.filter_table/deblur/' '05.filter_table/deblur/' '05.filter_table/dada2/indoors' '05.filter_table/dada2/indoors' '05.filter_table/deblur/indoors' '05.filter_table/deblur/indoors' '05.filter_table/dada2/outdoors' '05.filter_table/dada2/outdoors' '05.filter_table/deblur/outdoors' '05.filter_table/deblur/outdoors' '05.filter_table/dada2/mock' '05.filter_table/dada2/mock' '05.filter_table/deblur/mock' '05.filter_table/deblur/mock')

PREFIX=('se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined' 'se' 'pear-joined')

METADATA=('00.mapping/combined.tsv' '00.mapping/combined.tsv' '00.mapping/combined.tsv' '00.mapping/combined.tsv' '00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/indoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/outdoors.tsv' '00.mapping/mock.tsv' '00.mapping/mock.tsv' '00.mapping/mock.tsv' '00.mapping/mock.tsv')

OUT_DIR=('08.core_diversity/dada2' '08.core_diversity/dada2' '08.core_diversity/deblur' '08.core_diversity/deblur' '08.core_diversity/dada2/indoors' '08.core_diversity/dada2/indoors' '08.core_diversity/deblur/indoors' '08.core_diversity/deblur/indoors' '08.core_diversity/dada2/outdoors' '08.core_diversity/dada2/outdoors' '08.core_diversity/deblur/outdoors' '08.core_diversity/deblur/outdoors' '08.core_diversity/dada2/mock' '08.core_diversity/dada2/mock' '08.core_diversity/deblur/mock' '08.core_diversity/deblur/mock')

METADATA_COLUMN=('treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment' 'treatment')

