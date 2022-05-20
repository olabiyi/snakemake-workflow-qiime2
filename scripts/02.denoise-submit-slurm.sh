#!/bin/bash
#SBATCH --job-name=dada-denoise       #Set the job name to "JobExample2"
#SBATCH --time=23:00:00               #Set the wall clock limit to 6hr and 30min
#SBATCH --nodes=1                    #Request 1 node
#SBATCH --ntasks=1          #Request 1 tasks/cores per node
#SBATCH --mem=1G                     #Request 1GB per node 
#SBATCH --output=dada-denoise.o.%j      #Send stdout/err to "Example2Out.[jobID]" 
#SBATCH --error=dada-denoise.e.%j    #Send std err to "Example2error.[jobID]"


module purge
module load iccifort/2020.1.217
module load impi/2019.7.217
module load snakemake/5.26.1-Python-3.8.2


# Denoise reads - chimera removal, reads merging, quality trimming and ASV feature table generation take a good look at 05.Denoise_reads/denoise_stats.qzv to see if you didn't lose too many reads and if the reads merged well. If the denoizing was not sucessful, adjust the parameters you set for dada2 and then re-run
snakemake   \
        --jobs 10 \
        --keep-going \
        --rerun-incomplete \
        --cluster-config config/cluster.yaml \
        --cluster "sbatch --partition {cluster.queue} --mem={cluster.mem} --time={cluster.time} --ntasks={cluster.threads}" \
        "05.Denoise_reads/denoise_stats.qzv" "05.Denoise_reads/table_summary.qzv" "05.Denoise_reads/representative_sequences.qzv"


