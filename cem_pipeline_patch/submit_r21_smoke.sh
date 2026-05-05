#!/bin/bash
#SBATCH --job-name=r21_smoke
#SBATCH --account=PUOM0008
#SBATCH --time=01:30:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --mem=60G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/r21_smoke_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/r21_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# Smoke test for v4 productivity multiplier integration. 1 sim, 5 cycles
# to verify the patch loads, runs without error, and produces sensible
# proj_carbon values. About 30 to 60 min on 8 CPUs.

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

Rscript run_projection.R --state ME --n_sims 1 --cycles 5 \
  --cores ${SLURM_CPUS_PER_TASK} --scenario_set harvest \
  --tag rcp45_hadgem2_wear_r21_smoke \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors --climate_rcp 4.5 \
  --fixed_harvest_rate 0.10 --include_remeasured \
  --use_brms_sdimax --use_decoupled_climate --use_disturbance --use_potter_vcc \
  --use_owner_stratification --use_county_harvest --use_owner_balanced \
  --use_v4_prod_mult --v4_prod_mult_strength 1.0 \
  --skip_supply --no_econ
