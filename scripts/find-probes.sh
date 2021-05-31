#!/bin/bash
#$ -S /bin/bash
#$ -N Find_probes 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 40

set -e 

#source activate qiime2-2020.6
#export PERL5LIB='/gpfs0/bioinfo/users/obayomi/miniconda3/envs/qiime2-2020.6/lib/site_perl/5.26.2/x86_64-linux-thread-multi'
PROBES=('ACTCCTACGGGAGGCAGC' 'GGTGACAGTGGGCAGCGA' 'AAACGATGTGGGAAGGC' 'AAACGAAGTGGGAAGGC')

FILES=($(find "sequence_data/" -type f -name "*gz"))

parallel --jobs 0 zgrep {} ${FILES[*]}  '>' find-probe/{}.txt ::: ${PROBES[*]}
