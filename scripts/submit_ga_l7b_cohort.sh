#!/bin/bash
#SBATCH --job-name=ga_l7b_cohort
#SBATCH --time=00:45:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=400G
#SBATCH --account=PUOM0008
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/logs/%x_%j.out
#SBATCH --error=/fs/scratch/PUOM0008/crsfaaron/logs/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

mkdir -p /fs/scratch/PUOM0008/crsfaaron/logs

module load gcc/12.3.0 R/4.4.0

cd $HOME/fia_cem_projections

echo "=== Job $SLURM_JOB_ID on $(hostname) ==="
date
Rscript --vanilla scripts/ga_l7b_cohort_analysis.R
RC=$?
echo "=== Rscript exit code: $RC ==="
date
exit $RC
