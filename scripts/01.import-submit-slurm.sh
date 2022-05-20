#!/bin/bash
#SBATCH --job-name=import-sequences       #Set the job name to "JobExample2"
#SBATCH --time=10:00:00               #Set the wall clock limit to 6hr and 30min
#SBATCH --nodes=1                    #Request 1 node
#SBATCH --ntasks=1          #Request 1 tasks/cores per node
#SBATCH --mem=1G                     #Request 1GB per node 
#SBATCH --output=import-seqs.o.%j      #Send stdout/err to "Example2Out.[jobID]" 
#SBATCH --error=import-seqs.e.%j    #Send std err to "Example2error.[jobID]"

module purge
module load iccifort/2020.1.217
module load impi/2019.7.217
module load snakemake/5.26.1-Python-3.8.2

# import reads and check their quality to determine trunc lengths for dada2
snakemake   \
        --jobs 10 \
        --keep-going \
        --rerun-incomplete \
        --cluster-config config/cluster.yaml \
        --cluster "sbatch --partition {cluster.queue} --mem={cluster.mem} --time={cluster.time} --ntasks={cluster.threads}" \
        "04.QC/trimmed_reads_qual_viz.qzv" "04.QC/raw_reads_qual_viz.qzv"


