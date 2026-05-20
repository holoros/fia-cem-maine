#!/usr/bin/env Rscript
## =============================================================================
## scripts/build_p2_vs_p3_comparison.R
##
## p2 (v2 crosswalk, 38.8 pct cond coverage) vs p3 (v3 crosswalk, 100 pct
## coverage) production comparison.
##
## Pulls ci_summaries.csv and raw_mc_summaries.csv from the 12 production
## output dirs (3 states x 2 RCPs x 2 vintages), assembles a tidy frame,
## and writes a 6 panel BAU trajectory comparison plus a 12 row gr_ratio
## table for cycle 1 and cycle 5.
##
## Designed to render the moment all p3 jobs land. Quietly skips any dir not
## yet present.
##
## Usage:
##   Rscript scripts/build_p2_vs_p3_comparison.R
##   Rscript scripts/build_p2_vs_p3_comparison.R --output_dir figures/p3
##
## Author: 18 May 2026
## =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr)
  library(ggplot2); library(stringr); library(purrr)
})

args <- commandArgs(trailingOnly = TRUE)
arg_or_default <- function(flag, default) {
  i <- which(args == flag)
  if (length(i) > 0) args[i + 1] else default
}

output_root <- arg_or_default("--output_root", "~/fia_cem_projections/output")
fig_dir     <- arg_or_default("--output_dir",  "figures/p2_vs_p3")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

STATES <- c("MN", "WA", "GA")
RCPS   <- c(45, 85)
VINTAGES <- c("p2", "p3", "p3lite")

## ---- Locate latest dir per state x rcp x vintage ------------------------
find_run_dir <- function(state, rcp, vintage) {
  pat <- sprintf("^%s_.*_rcp%d_.*_%s$", state, rcp, vintage)
  cand <- list.files(path.expand(output_root), pattern = pat, full.names = TRUE)
  if (length(cand) == 0) return(NA_character_)
  cand <- cand[file.info(cand)$isdir]
  if (length(cand) == 0) return(NA_character_)
  ## Most recent by mtime
  cand[which.max(file.info(cand)$mtime)]
}

grid <- expand.grid(state = STATES, rcp = RCPS, vintage = VINTAGES,
                    stringsAsFactors = FALSE)
grid$dir <- mapply(find_run_dir, grid$state, grid$rcp, grid$vintage)

cat("Run discovery:\n")
print(grid)

## ---- Tidy loader --------------------------------------------------------
load_ci <- function(state, rcp, vintage, dir) {
  if (is.na(dir)) return(NULL)
  fp <- file.path(dir, "ci_summaries.csv")
  if (!file.exists(fp)) return(NULL)
  d <- readr::read_csv(fp, show_col_types = FALSE)
  d$state   <- state
  d$rcp     <- rcp
  d$vintage <- vintage
  d
}

ci_all <- purrr::pmap_dfr(grid, load_ci)
if (nrow(ci_all) == 0) {
  cat("\nNo ci_summaries found yet. Exiting cleanly.\n")
  quit(status = 0)
}
cat(sprintf("\nLoaded %d ci_summaries rows across %d run dirs\n",
            nrow(ci_all),
            length(unique(paste(ci_all$state, ci_all$rcp, ci_all$vintage)))))

## ---- gr_ratio cycle 1 + cycle 5 table -----------------------------------
gr_tab <- ci_all |>
  dplyr::filter(scenario == "BAU", cycle %in% c(1, 5)) |>
  dplyr::transmute(state, rcp, vintage, cycle,
                   gr_ratio = sprintf("%.3f (%.3f, %.3f)",
                                      gr_ratio_mean, gr_ratio_lo, gr_ratio_hi)) |>
  tidyr::pivot_wider(names_from = vintage, values_from = gr_ratio) |>
  dplyr::arrange(state, rcp, cycle)

gr_csv <- file.path(fig_dir, "p2_vs_p3_gr_ratio.csv")
readr::write_csv(gr_tab, gr_csv)
cat(sprintf("Wrote: %s (%d rows)\n", gr_csv, nrow(gr_tab)))
print(gr_tab)

## ---- BAU trajectory comparison panel ------------------------------------
plot_data <- ci_all |>
  dplyr::filter(scenario == "BAU") |>
  dplyr::mutate(year = 1999 + cycle * 5,
                rcp_label = paste0("RCP ", rcp / 10),
                vintage_label = ifelse(vintage == "p2",
                                       "p2 (v2 crosswalk, 38.8% cov)",
                                       "p3 (v3 crosswalk, 100% cov)"))

pub_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"),
        legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey30"))

make_panel <- function(yvar, ylab, title) {
  ggplot(plot_data,
         aes(x = year, y = .data[[yvar]],
             colour = vintage_label, linetype = vintage_label,
             group = paste(state, rcp, vintage))) +
    geom_ribbon(aes(ymin = .data[[paste0(sub("_mean$", "_lo", yvar))]],
                    ymax = .data[[paste0(sub("_mean$", "_hi", yvar))]],
                    fill = vintage_label),
                colour = NA, alpha = 0.15) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 1.5) +
    facet_grid(rcp_label ~ state, scales = "free_y") +
    scale_colour_manual(values = c("p2 (v2 crosswalk, 38.8% cov)" = "#999999",
                                   "p3 (v3 crosswalk, 100% cov)" = "#1f77b4")) +
    scale_fill_manual(values = c("p2 (v2 crosswalk, 38.8% cov)" = "#999999",
                                 "p3 (v3 crosswalk, 100% cov)" = "#1f77b4")) +
    scale_linetype_manual(values = c("p2 (v2 crosswalk, 38.8% cov)" = "dashed",
                                     "p3 (v3 crosswalk, 100% cov)" = "solid")) +
    labs(title = title,
         subtitle = "BAU scenario; ribbon = bootstrap 95 pct CI across sims",
         x = "Year",
         y = ylab,
         colour = NULL, fill = NULL, linetype = NULL) +
    pub_theme
}

p_gr  <- make_panel("gr_ratio_mean",    "Growth/removal ratio",
                    "p2 vs p3: growth/removal ratio trajectory")
p_vol <- make_panel("mean_vol_mean",    "Volume per acre (cuft)",
                    "p2 vs p3: volume per acre trajectory")
p_car <- make_panel("mean_carbon_mean", "Carbon per acre (lb)",
                    "p2 vs p3: above ground carbon per acre trajectory")
p_ba  <- make_panel("mean_ba_mean",     "Basal area (sqft/ac)",
                    "p2 vs p3: basal area trajectory")

ggsave(file.path(fig_dir, "p2_vs_p3_gr_ratio.png"),  p_gr,  width = 10, height = 6, dpi = 300)
ggsave(file.path(fig_dir, "p2_vs_p3_volume.png"),    p_vol, width = 10, height = 6, dpi = 300)
ggsave(file.path(fig_dir, "p2_vs_p3_carbon.png"),    p_car, width = 10, height = 6, dpi = 300)
ggsave(file.path(fig_dir, "p2_vs_p3_basal_area.png"), p_ba, width = 10, height = 6, dpi = 300)

cat(sprintf("\nWrote 4 figures to: %s/\n", fig_dir))
cat("Done.\n")
