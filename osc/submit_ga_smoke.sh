#!/bin/bash
#SBATCH --job-name=ga_smoke
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/ga_smoke_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/ga_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# =============================================================================
# Georgia smoke test for multistate portability. Mirrors submit_mn_smoke.sh.
# Donor pool: GA, FL, SC, NC, TN, AL.
# state_constants row: dT 2.2/4.0, fire 0.040/cycle (8x ME),
#                      sdimax_default 360 (loblolly/oak-pine), terminal_age 80
# =============================================================================

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  GA smoke test"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript run_projection.R --state GA --n_sims 10 --cycles 3 \
  --cores ${SLURM_CPUS_PER_TASK} \
  --scenario_set bau \
  --tag ga_smoke \
  --baseline_year 1999 --baseline_window 5 \
  --include_remeasured --use_brms_sdimax --use_potter_vcc \
  --save_per_plot --skip_supply --no_econ \
  --use_owner_stratification

EXIT_CODE=$?

echo "============================================"
echo "  Finished: $(date)"
echo "  Exit code: ${EXIT_CODE}"
echo "============================================"

exit ${EXIT_CODE}
