#!/bin/bash
#SBATCH --job-name=hcb_l3_v3
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/slurm_logs/hcb_l3_v3_%j.out

set -euo pipefail
cd ~/fia_cem_projections

module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0

mkdir -p ~/fia_cem_projections/config/v3_staging

Rscript scripts/build_hcb_l3_crosswalk_v3.R \
    ~/landowner/US_forest_ownership.tif \
    ~/Disturbance/us_eco_l3.shp \
    ~/FIA \
    ~/fia_cem_projections/config/v3_staging

echo "DONE: $(date)"
