#!/bin/bash
#SBATCH --job-name=fia_expand_r17
#SBATCH --account=PUOM0008
#SBATCH --time=02:30:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=4 --mem=160G
#SBATCH --output=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_exp_r17_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/fia_cem_projections/logs/fia_exp_r17_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu
# Submit AFTER all four r17 projection jobs complete with:
#   sbatch --dependency=afterok:8877283:8877284:8877285:8877286 osc/expand_r17.sh

mkdir -p logs
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER
export FIA_DATA_DIR=${HOME}/fia_data
cd ${HOME}/fia_cem_projections

Rscript -e '
suppressPackageStartupMessages({
  library(tidyverse); library(data.table); library(here)
})
project_dir <- here::here()
source(file.path(project_dir, "R", "10_state_expansion.R"))

out_dir <- file.path(project_dir, "output", "state_summary_progression")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

r17_dirs <- c(
  "ME_20260427_rcp45_hadgem2_wear_r17",
  "ME_20260427_rcp45_hadgem2_wear_econ_r17",
  "ME_20260427_rcp85_hadgem2_wear_r17",
  "ME_20260427_rcp85_hadgem2_wear_econ_r17"
)
# Note: directories created earlier may exist with incomplete RDS from
# the failed 8866265-8866268 batch. The new (8877283-8877286) jobs should
# overwrite them. We expand whichever RDS is on disk and valid.

for (d in r17_dirs) {
  short_tag <- sub("^ME_\\d{8}_", "", d)
  rds_file  <- file.path(project_dir, "output", d, "per_plot_projections.rds")
  out_prefix <- file.path(out_dir, paste0("state_", short_tag))
  cat(sprintf("\n--- Expanding %s ---\n", d))
  if (!file.exists(rds_file)) { cat("  SKIP: no rds\n"); next }
  fsize <- file.info(rds_file)$size
  cat(sprintf("  RDS size: %.2f GB\n", fsize / 1e9))
  if (fsize < 1e9) { cat("  WARN: RDS smaller than expected (1 GB)\n") }
  tryCatch({
    expand_to_state(
      per_plot_file    = rds_file,
      state            = "ME",
      fia_dir          = Sys.getenv("FIA_DATA_DIR", file.path(Sys.getenv("HOME"), "fia_data")),
      config_dir       = file.path(project_dir, "config"),
      baseline_year    = 1999,
      cycle_length_yrs = 5L,
      output_prefix    = out_prefix,
      scenario_names   = short_tag
    )
    # Free per_plot RDS now to prevent quota from running tight again
    cat(sprintf("  Removing %s to free quota\n", basename(rds_file)))
    file.remove(rds_file)
  }, error = function(e) cat("  ERROR:", conditionMessage(e), "\n"))
}
cat("\n=== Done ===\n")
'
