#!/bin/bash
#SBATCH --job-name=wa_prodHIND
#SBATCH --account=PUOM0008
#SBATCH --time=01:30:00
#SBATCH --cpus-per-task=4 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_prodHIND_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_prodHIND_%j.err
cd ~/fia_cem_projections
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS=${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
for TAG in rcp45_wear_prodL7b rcp45_wear_prodS_l7b; do
  echo "==== Hindcast WA ${TAG} ===="
  Rscript scripts/hindcast_multistate.R --state WA --tag ${TAG} --date 20260521 || echo "FAILED ${TAG}"
done
echo "WA productivity hindcasts done $(date)"
