#!/bin/bash
#SBATCH --job-name=fia_owner_atlas
#SBATCH --account=PUOM0008
#SBATCH --time=00:45:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=4 --mem=64G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_owner_atlas_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_owner_atlas_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

Rscript build_landowner_atlas.R \
  ${HOME}/landowner/NewEngland_LandOwners.tif \
  ${FIA_DATA_DIR} \
  ${HOME}/fia_cem_projections/config
