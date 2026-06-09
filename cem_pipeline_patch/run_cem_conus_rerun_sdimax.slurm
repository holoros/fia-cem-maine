#!/bin/bash
#SBATCH --job-name=cem_rerun
#SBATCH --time=20:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=logs/cem_rerun_%A_%a.out
#SBATCH --error=logs/cem_rerun_%A_%a.err
#SBATCH --array=0-38%12
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# Re-run the 39 CEM CONUS states that failed the first array (cem_ecoregion
# integer/character bind_rows bug, now fixed in R/02_cem_matching.R) or OOM/
# timed out. 48G mem + 20h for the large/slow states.
set -uo pipefail
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0 >/dev/null 2>&1
export R_LIBS="$HOME/R/cardinal_libs/4.4.0:$HOME/R/cardinal_libs:$HOME/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
cd "$HOME/fia_cem_projections"; mkdir -p logs

# 39 states not completed by 11321543 (succeeded: AL CT FL IA ID MA MT RI TN)
STATES=(AZ AR CA CO DE GA IL IN KS KY LA ME MD MI MN MS MO NE NV NH NJ NM NY NC \
        ND OH OK OR PA SC SD TX UT VT VA WA WV WI WY)
ST=${STATES[$SLURM_ARRAY_TASK_ID]}
echo "=== CEM rerun: $ST $(date) ==="
Rscript run_projection.R --state "$ST" --n_sims 100 --cycles 15 \
  --cores ${SLURM_CPUS_PER_TASK} --scenario_set harvest \
  --tag "conus_harmonized_sdimax_${ST}" --save_per_plot --use_brms_sdimax
rc=$?; echo "=== exit $ST rc=$rc $(date) ==="
