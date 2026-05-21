#!/bin/bash
#SBATCH --job-name=wa_conus_prod85
#SBATCH --account=PUOM0008
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=40 --mem=360G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_conus_prod85_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_conus_prod85_%j.err
cd ~/fia_cem_projections
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS=${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
Rscript run_projection.R --state WA --n_sims 100 --cycles 15 \
  --cores ${SLURM_CPUS_PER_TASK} --scenario_set harvest \
  --tag rcp85_wear_conus_l7b \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors --climate_rcp 8.5 \
  --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 --include_remeasured \
  --conus_donors \
  --use_brms_sdimax --use_disturbance --use_potter_vcc \
  --save_per_plot --skip_supply --no_econ \
  --use_owner_stratification --use_owner_balanced
echo WA conus production done at $(date)
