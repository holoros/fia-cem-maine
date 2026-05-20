#!/bin/bash
# run_l7b_hindcasts.sh
# Run multistate hindcast on all 8 Layer 7b production outputs, then assemble
# the bias comparison table p1 vs l7b. Intended for SLURM-side execution as a
# follow-up after the production reruns complete.

set -e
cd ${HOME}/fia_cem_projections
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data

DATE=20260520

declare -A CONFIGS=(
  [ME:45]="rcp45_hadgem2_wear_econ_l7b"
  [ME:85]="rcp85_hadgem2_wear_econ_l7b"
  [MN:45]="rcp45_wear_l7b"
  [MN:85]="rcp85_wear_l7b"
  [WA:45]="rcp45_wear_l7b"
  [WA:85]="rcp85_wear_l7b"
  [GA:45]="rcp45_wear_l7b"
  [GA:85]="rcp85_wear_l7b"
)

for key in "${!CONFIGS[@]}"; do
  STATE="${key%%:*}"
  RCP="${key##*:}"
  TAG="${CONFIGS[$key]}"
  echo "============================================"
  echo "Hindcasting ${STATE} RCP ${RCP} (tag ${TAG})"
  echo "============================================"
  Rscript scripts/hindcast_multistate.R \
    --state "${STATE}" \
    --tag "${TAG}" \
    --date "${DATE}" \
    || echo "FAILED ${STATE} ${RCP}"
done

# Build the cross-state comparison once hindcasts land
Rscript scripts/build_l7b_vs_p1_comparison.R || echo "Comparison build FAILED"

echo "All hindcasts + comparison complete at $(date)"
