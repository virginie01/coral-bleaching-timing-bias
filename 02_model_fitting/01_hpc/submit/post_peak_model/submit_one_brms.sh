#!/bin/bash
#SBATCH --account=st-sdonner-1
#SBATCH --job-name=post_peak_brms
#SBATCH --partition=cascade
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G
#SBATCH --time=60:00:00
#SBATCH --output=output/post_peak_model/post_peak_brms_%j.out
#SBATCH --error=output/post_peak_model/post_peak_brms_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=virginie.bornarel@ubc.ca

# -------------------------------
# Environment setup
# -------------------------------
source /etc/profile.d/modules.sh

module load gcc/9.4.0
module load r/4.4.0
module load r-dplyr

export R_LIBS_USER=/arc/home/vbornare/R/x86_64-pc-linux-gnu-library/4.4

# -------------------------------
# Move to project directory
# -------------------------------
cd $SLURM_SUBMIT_DIR

echo "============================================"
echo "Node: $(hostname)"
echo "Start time: $(date)"
echo "Working directory: $(pwd)"
echo "============================================"

which Rscript
Rscript --version

# -------------------------------
# Run the model
# -------------------------------
Rscript scripts/post_peak_model/run_one_brms_model.R

echo "============================================"
echo "End time: $(date)"
echo "============================================"
