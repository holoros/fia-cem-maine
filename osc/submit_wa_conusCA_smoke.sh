#!/bin/bash
#SBATCH --job-name=wa_caSMOKE
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=8 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_caSMOKE_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/wa_caSMOKE_%j.err
cd ~/fia_cem_projections
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS=${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
Rscript run_projection.R --state WA --n_sims 2 --cycles 3   --cores ${SLURM_CPUS_PER_TASK} --scenario_set harvest   --tag conusCA_smoke   --baseline_year 1999 --baseline_window 10   --untreated_donors --climate_rcp 4.5   --bootstrap_plots --bootstrap_frac 0.9   --fixed_harvest_rate 0.10 --include_remeasured   --conus_donors   --use_brms_sdimax --use_disturbance --use_potter_vcc   --skip_supply --no_econ   --use_owner_stratification --use_owner_balanced
echo SMOKE DONE $(date)
