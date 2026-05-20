#!/bin/bash
#SBATCH --job-name=fia_wa_l7b_85
#SBATCH --account=PUOM0008
#SBATCH --time=12:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=48 --mem=180G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_wa_l7b_85_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_wa_l7b_85_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# Washington production run, RCP 8.5 companion to submit_wa_production.sh.
# Mirrors the running RCP 4.5 submission with --climate_rcp 8.5 and
# --tag rcp85_wear_l7b. WA state_constants row: dT 2.0/3.8, fire 0.060/cyc.
# Tag: rcp85_wear_l7b
# Output: output/WA_<DATE>_rcp85_wear_l7b/

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

echo "============================================"
echo "  WA production run (RCP 8.5, p1)"
echo "  Job: ${SLURM_JOB_ID}  Node: ${SLURM_NODELIST}"
echo "  Started: $(date)"
echo "============================================"

Rscript run_projection.R --state WA --n_sims 100 --cycles 15 \
  --cores ${SLURM_CPUS_PER_TASK} \
  --scenario_set harvest \
  --tag rcp85_wear_l7b \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors \
  --climate_rcp 8.5 \
  --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 \
  --include_remeasured \
  --use_brms_sdimax \
  --use_disturbance \
  --use_potter_vcc \
  --save_per_plot \
  --skip_supply \
  --no_econ \
  --use_owner_stratification \
  --use_owner_balanced

EXIT_CODE=$?

echo "============================================"
echo "  Finished: $(date)"
echo "  Exit code: ${EXIT_CODE}"
echo "============================================"

exit ${EXIT_CODE}
