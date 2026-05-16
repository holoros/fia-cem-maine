#!/bin/bash
#SBATCH --job-name=fia_mn_2004
#SBATCH --account=PUOM0008
#SBATCH --time=20:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=48 --mem=200G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_mn_2004_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_mn_2004_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# =============================================================================
# MN 2004 baseline diagnostic rerun. Tests whether the MN -23 percent statewide
# volume undercount observed in the p1 production set (1999 baseline) is
# attributable to the DESIGNCD periodic plot exclusion that effectively
# truncates MN's baseline to 2004-2008 (annualized inventory start year).
#
# If MN with --baseline_year 2004 --baseline_window 5 produces statewide volume
# matching EVALIDator (~28 Bcuft), the manuscript can report the 1999 baseline
# p1 run with a clear "structural FIA inventory design limitation" note.
#
# Tag: rcp45_wear_p1_2004base
# Cycles: 14 (2004 baseline + 14 * 5yr = 2074, same endpoint as 1999 baseline 15 cycle)
# Output: output/MN_<DATE>_rcp45_wear_p1_2004base/
#
# Companion documentation: docs/MN_VOLUME_GAP_ROOT_CAUSE_20260516.md
# =============================================================================

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  MN 2004 baseline diagnostic (RCP 4.5)"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript run_projection.R --state MN --n_sims 100 --cycles 14 \
  --cores ${SLURM_CPUS_PER_TASK} \
  --scenario_set harvest \
  --tag rcp45_wear_p1_2004base \
  --baseline_year 2004 --baseline_window 5 \
  --untreated_donors \
  --climate_rcp 4.5 \
  --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 \
  --include_remeasured \
  --use_brms_sdimax \
  --use_disturbance \
  --use_potter_vcc \
  --save_per_plot \
  --skip_supply \
  --no_econ \
  --use_owner_stratification \
  --use_owner_balanced

EXIT_CODE=$?
echo "============================================"
echo "  Finished: $(date)"
echo "  Exit code: ${EXIT_CODE}"
echo "============================================"
exit ${EXIT_CODE}
