#!/bin/bash
#SBATCH --job-name=hcb_l3_crosswalk
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=4 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/hcb_l3_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/hcb_l3_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# =============================================================================
# Build HCB x L3 ecoregion crosswalk for ME, MN, WA, GA FIA plots.
# Output: ~/fia_cem_projections/config/fia_plots_hcb_l3.csv
# Foundation step from MULTISTATE_PORTABILITY_GAPS.md (Section 8, step 1).
# =============================================================================

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER

cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  HCB x L3 crosswalk build"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript scripts/build_hcb_l3_crosswalk.R \
  ${HOME}/landowner/US_forest_ownership.tif \
  ${HOME}/Disturbance/us_eco_l3_state_boundaries.shp \
  ${HOME}/FIA \
  ${HOME}/fia_cem_projections/config

EXIT_CODE=$?

echo "============================================"
echo "  Finished: $(date)"
echo "  Exit code: ${EXIT_CODE}"
echo "============================================"

exit ${EXIT_CODE}
