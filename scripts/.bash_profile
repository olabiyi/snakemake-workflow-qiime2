source /storage/SGE6U8/default/common/settings.sh

#export SOURCETRACKER_PATH=/gpfs0/biores/users/gilloro/Biyi/SourceTracking/sourcetracker-1.0.1
#Chimera slayer
export PATH=/fastspace/bioinfo_apps/microbiomeutil-r20110519/ChimeraSlayer/:$PATH
#vsearch
export PATH=/fastspace/bioinfo_apps/vsearch/vsearch_v2.3.4/bin/:$PATH
#pathogen analysis scripts
#export PATH=/gpfs0/biores/users/gilloro/Biyi/pathogen_analysis/:$PATH
#qiime
#export PATH=/fastspace/bioinfo_apps/qiime/usr/local/bin/:$PATH
#NCBI blast
export PATH=/gpfs0/bioinfo/users/obayomi/ncbi-blast-2.3.0+/bin/:$PATH
#qsub
export PATH=/storage/SGE6U8/bin/lx24-amd64/:$PATH
#all executables
export PATH=/gpfs0/bioinfo/users/obayomi/bin/:$PATH
#sra tolkit
export PATH=/gpfs0/bioinfo/users/obayomi/sratoolkit.2.9.6-1-ubuntu64/bin/:$PATH
#Diamond 0.7.11
#export PATH=/fastspace/bioinfo_apps/Diamond/v0.7.11/:$PATH
#MEGAN
export PATH=/gpfs0/bioinfo/users/obayomi/megan/:$PATH
#MEGAN commandline tools
export PATH=/gpfs0/bioinfo/users/obayomi/megan/tools:$PATH
#minimap2 for aligning long reads like nanopore
export PATH=/gpfs0/bioinfo/users/obayomi/minimap2:$PATH
#fastx tool kit for processing fasta and fastq files
#export PATH=/gpfs0/biores/users/gilloro/Biyi/fastx_toolkit/bin:$PATH

#centrifuge for metagenomic reads classification
export PATH=/gpfs0/bioinfo/users/obayomi/centrifuge/:$PATH
#microbiome helper
export PATH=/gpfs0/bioinfo/users/obayomi/microbiome_helper/:$PATH
# LAST
export PATH=/gpfs0/bioinfo/users/obayomi/last-1021/src/:$PATH
export PATH=/gpfs0/bioinfo/users/obayomi/last-1021/scripts/:$PATH
# Kraken
export PATH=/fastspace/bioinfo_apps/kraken/:$PATH
#metaphlan2
#export PATH=/gpfs0/bioinfo/users/obayomi/biobakery-metaphlan2-5bd7cd0e4854/:$PATH
#miniconda
export PATH=/gpfs0/bioinfo/users/obayomi/miniconda3/envs/python2/bin/:$PATH
#set SGE_ROOT variable
export SGE_ROOT=/storage/SGE6U8
#HMM
export PATH=/gpfs0/bioinfo/apps/HMMER/HMMER_v3.1b1/bin/:$PATH
#metaBAT
export PATH=/gpfs0/bioinfo/users/obayomi/metabat/:$PATH
alias ll='ls --color=auto -alh'