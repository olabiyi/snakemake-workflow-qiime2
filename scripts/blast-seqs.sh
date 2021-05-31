#!/bin/bash
#$ -S /bin/bash
#$ -N blast_seqs 
#$ -q bioinfo.q
#$ -V 
#$ -cwd 
#$ -notify 
#$ -pe shared 72

set -euo pipefail
 
# database after retrieving the sequence by ASV id from the representative sequence file
DATABASE="/gpfs0/bioinfo/users/obayomi/databases/non_redundant_NCBI_DB/non_redundant"
QUERY="/gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/13.find_B12_bacteria/blast/potential_B12_bacteria_sequences.fasta"
OUT="/gpfs0/bioinfo/users/obayomi/hinuman_analysis/16S_illumina/13.find_B12_bacteria/blast/potential_B12_bacteria_blast.tsv"

cat ${QUERY} | \
parallel --jobs 0 --recstart '>' \
	--pipe blastn -db ${DATABASE} -outfmt \"6 qseqid sseqid stitle pident length mismatch gapopen qstart qend sstart send evalue bitscore\"  \
	-max_target_seqs 5  -out ${OUT} -query -
