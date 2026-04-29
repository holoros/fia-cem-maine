# =============================================================================
# Title: Batch state expansion for all completed wear / wear_econ scenarios
# Author: A. Weiskittel
# Date: 2026-04-17
# Description: Runs 10_state_expansion.R expand_to_state() on every
#              per_plot_projections.rds file in output/ matching the
#              ME_YYYYMMDD_*_wear* pattern, plus the OBSERVED multi-year anchor.
#              Writes state_metrics_{tag}_{sim_totals,ci}.csv to a single
#              summary directory for downstream comparison figure.
# Run:
#   Rscript run_state_expansion_all.R
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

source(file.path(project_dir, "R", "10_state_expansion.R"))
source(file.path(project_dir, "R", "05_scenario_biasing.R"))

out_dir <- file.path(project_dir, "output", "state_summary_20260417")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("=== Batch state expansion ===\n")
cat(sprintf("Output: %s\n\n", out_dir))

# Find all completed wear / wear_econ / policy per-plot files
scenario_dirs <- list.files(file.path(project_dir, "output"),
                             pattern = "^ME_20260(417|418)_.*(wear|policy).*$",
                             full.names = TRUE)
scenario_dirs <- scenario_dirs[
  file.exists(file.path(scenario_dirs, "per_plot_projections.rds"))
]

cat(sprintf("Found %d completed scenarios:\n", length(scenario_dirs)))
for (d in scenario_dirs) cat(sprintf("  %s\n", basename(d)))

## Build land-use scenario lookup once. Triggers automatically on dirs whose
## tag contains "land_use". For other tags this is harmless (NULL passed).
lu_set <- get_scenario_set("maine_land_use")
lu_lookup <- tibble::tibble(
  scenario        = vapply(lu_set, function(s) s$name, ""),
  conversion_rate = vapply(lu_set, function(s) s$conversion_rate %||% 0, 0),
  afforest_rate   = vapply(lu_set, function(s) s$afforest_rate   %||% 0, 0)
)

for (d in scenario_dirs) {
  tag <- basename(d)
  # Strip "ME_YYYYMMDD_" prefix for the output prefix
  short_tag <- sub("^ME_\\d{8}_", "", tag)
  rds_file <- file.path(d, "per_plot_projections.rds")
  out_prefix <- file.path(out_dir, paste0("state_", short_tag))
  cat(sprintf("\n--- Expanding %s ---\n", tag))

  # Pass scenario_lookup only for runs flagged as land_use scenario sets.
  pass_lookup <- if (grepl("land_use|landuse", tag, ignore.case = TRUE))
                   lu_lookup else NULL

  tryCatch({
    expand_to_state(
      per_plot_file     = rds_file,
      state             = "ME",
      fia_dir           = Sys.getenv("FIA_DATA_DIR",
                                      unset = file.path(Sys.getenv("HOME"), "fia_data")),
      config_dir        = file.path(project_dir, "config"),
      baseline_year     = 1999,
      cycle_length_yrs  = 5L,
      output_prefix     = out_prefix,
      scenario_names    = short_tag,
      scenario_lookup   = pass_lookup,
      new_forest_c_frac = 0.30
    )
  }, error = function(e) {
    cat(sprintf("  ERROR on %s: %s\n", tag, e$message))
  })
}

# Also compute the OBSERVED multi-year anchor for cross-validation
cat("\n--- Computing OBSERVED multi-year anchor from FIA ---\n")
fia_dir <- Sys.getenv("FIA_DATA_DIR",
                       unset = file.path(Sys.getenv("HOME"), "fia_data"))
observed <- tryCatch({
  observed_state_totals_multi(state = "ME", fia_dir = fia_dir)
}, error = function(e) {
  cat(sprintf("  ERROR: %s\n", e$message))
  tibble()
})
if (nrow(observed) > 0) {
  write_csv(observed, file.path(out_dir, "observed_anchor.csv"))
  cat(sprintf("  Wrote observed_anchor.csv: %d rows\n", nrow(observed)))
}

cat("\n=== Done ===\n")
cat(sprintf("All outputs in: %s\n", out_dir))
