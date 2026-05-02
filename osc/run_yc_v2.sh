#!/bin/bash
#SBATCH --job-name=yc_v2
#SBATCH --account=PUOM0008
#SBATCH --time=00:45:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=4 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/yield_curves/logs/yc_v2_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/yield_curves/logs/yc_v2_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

mkdir -p ${HOME}/yield_curves/logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER

cd ${HOME}/yield_curves
Rscript yc_06_empirical_curves_v2.R \
  ${HOME}/fia_data \
  ${HOME}/fia_cem_projections/config \
  ${HOME}/yield_curves \
  200
