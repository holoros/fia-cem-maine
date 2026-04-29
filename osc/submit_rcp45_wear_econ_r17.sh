#!/bin/bash
#SBATCH --job-name=fia_r45_we
#SBATCH --account=PUOM0008
#SBATCH --time=20:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=48 --mem=180G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_rcp45_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_rcp45_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu
mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections
# 1999 baseline, all plots, HadGEM2-AO RCP 4.5, 2%/yr x 50% biomass, 100 yr
Rscript run_projection.R --state ME --n_sims 100 --cycles 15 \
  --cores ${SLURM_CPUS_PER_TASK} --scenario_set harvest --tag rcp45_hadgem2_wear_econ_r17 \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors \
  --climate_rcp 4.5 --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 --include_remeasured --use_brms_sdimax --use_decoupled_climate --use_disturbance --use_potter_vcc --save_per_plot --skip_supply --no_econ --use_maine_econ
