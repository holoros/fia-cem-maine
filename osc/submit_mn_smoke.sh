#!/bin/bash
#SBATCH --job-name=mn_smoke
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/mn_smoke_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/mn_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# =============================================================================
# Minnesota smoke test for multistate portability.
# Goal: run the projection with --state MN to surface every Maine fallback.
#
# Reduced parameters for fast turnaround:
#   n_sims  = 10
#   cycles  = 3
#   no_econ (skip R/11 Maine economic module)
#   no decoupled climate (avoid missing MN ClimateNA inputs)
#   no v4 productivity multiplier (Maine-keyed cells fall through to 1.0
#     for MN, which is the desired behavior for diagnostic; skipping the
#     flag avoids false positive "loaded multiplier" log lines)
#
# Outputs land in output/MN_<DATE>_smoke_<jid>/.
# Compare statewide AGC totals against published FIA EVALIDator MN estimates
# as the first sanity check.
# =============================================================================

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  MN smoke test"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript run_projection.R --state MN --n_sims 10 --cycles 3 \
  --cores ${SLURM_CPUS_PER_TASK} \
  --scenario_set bau \
  --tag mn_smoke \
  --baseline_year 1999 --baseline_window 5 \
  --include_remeasured --use_brms_sdimax --use_potter_vcc \
  --save_per_plot --skip_supply --no_econ \
  --use_owner_stratification

EXIT_CODE=$?

echo "============================================"
echo "  Finished: $(date)"
echo "  Exit code: ${EXIT_CODE}"
echo
echo "Diagnostic checklist for the operator:"
echo "  1. Did source_modules complete (all R/0X modules loaded)?"
echo "  2. Did 01_data_prep load STATECD=27 plots successfully?"
echo "  3. Did get_donor_states return MN, WI, MI, IA?"
echo "  4. Did 03_harvest_choice find maine_county_harvest_logit_offset.csv?"
echo "     (expected to fail or skip for MN; verify behavior)"
echo "  5. Did 06_projection_engine apply Maine wildfire baseline 0.5%/cycle"
echo "     to MN plots? (this is a known silent fallback per audit)"
echo "  6. Did 10_state_expansion correctly filter to STATECD == 27?"
echo "  7. Are output volumes / AGC plausible vs FIA EVALIDator MN totals?"
echo "============================================"

exit ${EXIT_CODE}
