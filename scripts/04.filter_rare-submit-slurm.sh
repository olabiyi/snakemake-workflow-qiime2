#!/bin/bash
#SBATCH --job-name=Taxa-plots       #Set the job name to "JobExample2"
#SBATCH --time=23:00:00               #Set the wall clock limit to 6hr and 30min
#SBATCH --nodes=1                    #Request 1 node
#SBATCH --ntasks=1          #Request 1 tasks/cores per node
#SBATCH --mem=1G                     #Request 1GB per node 
#SBATCH --output=tax-plots.o.%j      #Send stdout/err to "Example2Out.[jobID]" 
#SBATCH --error=tax-plots.e.%j    #Send std err to "Example2error.[jobID]"


module purge
module load iccifort/2020.1.217
module load impi/2019.7.217
module load snakemake/5.26.1-Python-3.8.2


# Filter rare taxa and make relative abundance bar plots
snakemake   \
        --jobs 10 \
        --keep-going \
        --rerun-incomplete \
        --cluster-config config/cluster.yaml \
        --cluster "sbatch --partition {cluster.queue} --job-name={rule}.{wildcards} --mem={cluster.mem} --time={cluster.time} --ntasks={cluster.threads}" \
        "08.Filter_feature_table/filtered_table.qzv" "09.Taxa_bar_plots/group-bar-plot.qzv" "09.Taxa_bar_plots/samples-bar-plots.qzv"



