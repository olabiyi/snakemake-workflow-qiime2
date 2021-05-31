
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/gpfs0/bioinfo/users/obayomi/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
    # eval "$__conda_setup"
# else
    # if [ -f "/gpfs0/bioinfo/users/obayomi/miniconda3/etc/profile.d/conda.sh" ]; then
        # . "/gpfs0/bioinfo/users/obayomi/miniconda3/etc/profile.d/conda.sh"
    # else
        # export PATH="/gpfs0/bioinfo/users/obayomi/miniconda3/bin:$PATH"
    # fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

source /storage/SGE6U8/default/common/settings.sh
# FASTQC
export PATH=/gpfs0/bioinfo/users/obayomi/FastQC/:$PATH
#export SOURCETRACKER_PATH=/gpfs0/biores/users/gilloro/Biyi/SourceTracking/sourcetracker-1.0.1
#Chimera slayer
export PATH=/fastspace/bioinfo_apps/microbiomeutil-r20110519/ChimeraSlayer/:$PATH
#vsearch
export PATH=/fastspace/bioinfo_apps/vsearch/vsearch_v2.3.4/bin/:$PATH
# perldl and pdl2 perl bin
#export PATH=/gpfs0/bioinfo/users/obayomi/perl5/bin/:PATH
# create alias for pdl2 because it has trouble finding perl
alias pdl2="/bin/perl /gpfs0/bioinfo/users/obayomi/perl5/bin/pdl2"
# rlwrap - needed for autocompletion when using perli
export PATH=/gpfs0/bioinfo/users/obayomi/bin/bin/:$PATH
#pathogen analysis scripts
export PATH=/gpfs0/bioinfo/users/obayomi/hinuman_analysis/16s_pathogen_analysis/:$PATH
#qiime
export PATH=/fastspace/bioinfo_apps/qiime/usr/local/bin/:$PATH
#NCBI blast
export PATH=/gpfs0/bioinfo/users/obayomi/ncbi-blast-2.10.1+/bin/:$PATH
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
# Kraken
export PATH=/fastspace/bioinfo_apps/kraken/:$PATH
#metaphlan2
#export PATH=/gpfs0/bioinfo/users/obayomi/biobakery-metaphlan2-5bd7cd0e4854/:$PATH

# bbmap
export PATH=/gpfs0/bioinfo/users/obayomi/bbmap/:$PATH

#microbiome helper
export PATH=/gpfs0/bioinfo/users/obayomi/microbiome_helper/:$PATH
# LAST
export PATH=/gpfs0/bioinfo/users/obayomi/last-1021/src/:$PATH
export PATH=/gpfs0/bioinfo/users/obayomi/last-1021/scripts/:$PATH

#Trimmomatic
export PATH=/fastspace/bioinfo_apps/Trimmomatic-0.32/:$PATH

#set SGE_ROOT variable
export SGE_ROOT=/storage/SGE6U8

#miniconda
#export PATH=/gpfs0/bioinfo/users/obayomi/miniconda3/envs/python2/bin/:$PATH
#export PATH=/gpfs0/bioinfo/apps/Miniconda2/Miniconda_v4.3.21/bin/:$PATH
export PATH=/gpfs0/bioinfo/users/obayomi/miniconda3/bin/:$PATH
#export PATH=/gpfs0/bioinfo/apps/Miniconda2/Miniconda_v4.3.21/envs/Metagenomics/share/minced-0.3.2-0/:$PATH
#HMM
export PATH=/gpfs0/bioinfo/apps/HMMER/HMMER_v3.1b1/bin/:$PATH
#metaBAT
export PATH=/gpfs0/bioinfo/users/obayomi/metabat/:$PATH
alias ll='ls --color=auto -alh'
#Bowtie2
export PATH=/gpfs0/bioinfo/apps/bowtie2/bowtie2-2.3.5-linux-x86_64:$PATH

# source useful function for running Neatseq_Flow
source /gpfs0/bioinfo/users/obayomi/non_model_RNA-Seq/functions.sh

# mauve
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/mauve_snapshot_2015-02-13/

# MinPath
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/MinPath/

# Signalp
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/signalp-5.0b/bin/

# tmHMM
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/tmhmm-2.0c/bin/

# aragorn
#export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/aragorn1.2.36/

# metaErg - anotation of metagenomics and metaproteomics assembly
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/metaerg/bin/

# Phyloflash home
PHYLOFLASH_DBHOME=/gpfs0/bioinfo/users/obayomi/138.1

# Motus
export PATH=$PATH:/gpfs0/bioinfo/users/obayomi/mOTUs_v2/
