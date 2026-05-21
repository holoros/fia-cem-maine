#!/bin/bash
#SBATCH --job-name=build_addCA
#SBATCH --account=PUOM0008
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=4 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/build_addCA_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/build_addCA_%j.err
cd ~/fia_cem_projections
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS=${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4
unset R_LIBS_USER
Rscript scripts/build_fia_db_WA_addCA.R
echo BUILD DONE $(date)
