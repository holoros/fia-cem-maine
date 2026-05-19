#!/bin/bash
#SBATCH --job-name=fia_mn_p3lite
#SBATCH --account=PUOM0008
#SBATCH --time=20:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=48 --mem=200G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_mn_p3lite_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_mn_p3lite_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# =============================================================================
# Minnesota production run, first multistate publication-grade projection.
# Mirrors osc/submit_rcp45_wear_r21.sh (the canonical ME r21 baseline) with
# Maine-specific flags dropped per MULTISTATE_PORTABILITY_GAPS.md:
#
#   DROPPED (Maine-only or not yet built for MN):
#     --use_county_harvest           (no MN county logit offset CSV; Section 8 step 7)
#     --use_decoupled_climate        (no MN ClimateNA pull; pending ClimateNA external)
#     --use_v4_prod_mult / strength  (Maine-keyed cells only; would fall through to 1.0)
#
#   KEPT (multistate-portable):
#     --use_brms_sdimax              (CONUS BRMS plot lookup)
#     --use_disturbance              (state_constants.csv MN row drives wildfire 0.010/cyc)
#     --use_potter_vcc               (CONUS SPCD lookup)
#     --use_owner_stratification     (HCB national raster, MN HCB-FIA agreement 74%)
#     --use_owner_balanced           (mass-balanced HCB multiplier)
#     --no_econ                      (R/11 economic module Maine-only)
#
# Tag: rcp45_wear_p3lite (production run #1 from p-series).
# Expected wall: ~6-10 hours (MN ~63k plots vs ME ~6k).
# Output: output/MN_<DATE>_rcp45_wear_p3lite/
# =============================================================================

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  MN production run (RCP 4.5, p1)"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript run_projection.R --state MN --n_sims 50 --cycles 15 \
  --cores ${SLURM_CPUS_PER_TASK} \
  --scenario_set harvest \
  --tag rcp45_wear_p3lite \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors \
  --climate_rcp 4.5 \
  --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 \
  --include_remeasured \
  --use_brms_sdimax \
  --use_disturbance \
  --use_potter_vcc \
   \
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
