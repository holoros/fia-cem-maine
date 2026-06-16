#!/usr/bin/env Rscript
# Batch state expansion for the SDImax-enabled CONUS harmonized runs. Globs every
# completed conus_harmonized_sdimax per-plot file and expands it to a state CI,
# writing state_<ST>_conus_sdimax_{sim_totals,ci}.csv. Idempotent / incremental:
# skips states whose CI already exists, so it can be re-run as more states finish.
suppressPackageStartupMessages({ library(tidyverse); library(data.table); library(here) })
pd <- path.expand(tryCatch(here::here(), error=function(e) "~/fia_cem_projections")); setwd(pd)
source(file.path(pd, "R", "10_state_expansion.R"))
source(file.path(pd, "R", "05_scenario_biasing.R"))

out_dir <- file.path(pd, "output", "state_summary_progression")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

dirs <- list.files(file.path(pd, "output"), pattern = "conus_harmonized_sdimax", full.names = TRUE)
dirs <- dirs[file.exists(file.path(dirs, "per_plot_projections.rds"))]
cat("Found", length(dirs), "completed SDImax state runs\n")

for (d in dirs) {
  # dir like <ST>_YYYYMMDD_conus_harmonized_sdimax_<ST>
  st <- toupper(sub("_.*$", "", basename(d)))
  prefix <- file.path(out_dir, sprintf("state_%s_conus_sdimax", st))
  ci <- paste0(prefix, "_ci.csv")
  if (file.exists(ci)) { cat("skip", st, "(CI exists)\n"); next }
  cat("\n--- expanding", st, "---\n")
  ok <- tryCatch({
    expand_to_state(per_plot_file = file.path(d, "per_plot_projections.rds"),
                    state = st, baseline_year = 1999L, output_prefix = prefix)
    TRUE
  }, error = function(e) { cat("  ERROR", st, ":", conditionMessage(e), "\n"); FALSE })
  if (ok) cat("  wrote", ci, "\n")
}
cat("\nDone. CIs in", out_dir, "\n")
