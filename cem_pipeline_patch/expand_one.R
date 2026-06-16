#!/usr/bin/env Rscript
# Expand the newest fixed-engine ME production run to a state CI for PERSEUS ingest.
suppressPackageStartupMessages({ library(tidyverse); library(data.table); library(here) })
pd <- tryCatch(here::here(), error=function(e) "~/fia_cem_projections")
pd <- path.expand(pd); setwd(pd)
source(file.path(pd, "R", "10_state_expansion.R"))
source(file.path(pd, "R", "05_scenario_biasing.R"))

dirs <- list.files(file.path(pd,"output"), pattern="^ME_.*me_fixed_prod", full.names=TRUE)
dirs <- dirs[file.exists(file.path(dirs,"per_plot_projections.rds"))]
stopifnot(length(dirs) >= 1)
d <- dirs[order(file.info(dirs)$mtime, decreasing=TRUE)][1]
cat("Expanding:", d, "\n")

out_prefix <- file.path(pd, "output", "state_summary_progression", "state_me_fixed_l7b_rcp45")
expand_to_state(per_plot_file = file.path(d, "per_plot_projections.rds"),
                state = "ME", baseline_year = 1999L,
                output_prefix = out_prefix)
cat("Wrote", paste0(out_prefix, "_ci.csv"), "\n")
