# =============================================================================
# Title: Comparison figure: baseline vs wear vs wear_econ
# Author: A. Weiskittel
# Date: 2026-04-17
# Description: Reads state_summary_20260417/*_ci.csv files produced by
#              run_state_expansion_all.R, plus the observed FIA anchor,
#              and builds a multi-panel ggplot comparing pipeline versions
#              across RCP 4.5 and RCP 8.5 with and without harvest.
#
# Panels:
#   Top row: above-ground carbon (MMT AGC) by scenario
#   Bottom row: total forest carbon (MMT total) by scenario
#   Left column: RCP 4.5
#   Right column: RCP 8.5
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(scales)
  library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

sum_dir <- file.path(project_dir, "output", "state_summary_20260417")
out_dir <- file.path(project_dir, "output", "figures_20260417")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Read all *_ci.csv files ----
ci_files <- list.files(sum_dir, pattern = "_ci\\.csv$", full.names = TRUE)
cat(sprintf("Found %d CI files\n", length(ci_files)))

read_ci <- function(f) {
  df <- readr::read_csv(f, show_col_types = FALSE)
  # Extract tag and decompose into pipeline x rcp x harvest
  tag <- sub("^state_", "", sub("_ci\\.csv$", "", basename(f)))
  # tag examples: rcp45_hadgem2_wear, rcp85_hadgem2_wear_nh, rcp45_hadgem2_wear_econ
  df$tag <- tag
  df$rcp <- if (grepl("rcp45", tag)) "RCP 4.5" else "RCP 8.5"
  df$harvest <- if (grepl("_nh$", tag)) "No harvest" else "Harvest (2%/yr x 50%)"
  df$pipeline <- if (grepl("wear_econ", tag)) "wear + econ"
                 else "wear (saturation + multi-pool)"
  df
}
ci <- purrr::map_dfr(ci_files, read_ci)

# Anchor observed values (from observed_anchor.csv)
obs_file <- file.path(sum_dir, "observed_anchor.csv")
if (file.exists(obs_file)) {
  obs <- readr::read_csv(obs_file, show_col_types = FALSE)
} else obs <- tibble()

# ---- Panel helpers ----
theme_proj <- function() {
  theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}

# Standard carbon trajectory plot (AGC or total C)
carbon_panel <- function(ci, metric_mean, metric_lo, metric_hi,
                          title_str, yaxis_str) {
  p <- ggplot(ci, aes(x = year,
                       y = .data[[metric_mean]],
                       color = pipeline, fill = pipeline,
                       linetype = harvest)) +
    geom_ribbon(aes(ymin = .data[[metric_lo]], ymax = .data[[metric_hi]]),
                alpha = 0.15, color = NA) +
    geom_line(linewidth = 0.9) +
    facet_wrap(~ rcp, nrow = 1) +
    scale_color_manual(values = c("wear (saturation + multi-pool)" = "#1f77b4",
                                   "wear + econ"                    = "#d62728"),
                        name = "Pipeline") +
    scale_fill_manual(values = c("wear (saturation + multi-pool)" = "#1f77b4",
                                  "wear + econ"                   = "#d62728"),
                       name = "Pipeline") +
    scale_linetype_manual(values = c("Harvest (2%/yr x 50%)" = "solid",
                                      "No harvest"            = "dashed"),
                           name = "Harvest") +
    scale_x_continuous(breaks = seq(2000, 2100, 20)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 1)) +
    labs(title = title_str, x = "Year", y = yaxis_str) +
    theme_proj()

  # Add observed FIA anchor points if available
  if (nrow(obs) > 0 && metric_mean %in% names(obs)) {
    p <- p + geom_point(data = obs, aes(x = year, y = .data[[metric_mean]]),
                         color = "black", shape = 18, size = 2.5,
                         inherit.aes = FALSE)
  }
  p
}

p_agc <- carbon_panel(ci, "mmt_agc_mean", "mmt_agc_lo", "mmt_agc_hi",
                      title_str = "Above-ground live tree carbon (AGC)",
                      yaxis_str = "MMT C")

# Only plot total if the column is present
if ("mmt_total_c_mean" %in% names(ci)) {
  p_tot <- carbon_panel(ci, "mmt_total_c_mean", "mmt_total_c_lo", "mmt_total_c_hi",
                         title_str = "Total forest carbon (7 pools)",
                         yaxis_str = "MMT C")
  combined <- p_agc / p_tot + plot_layout(guides = "collect") &
              theme(legend.position = "bottom")
} else {
  combined <- p_agc
}

ggsave(file.path(out_dir, "fig_comparison_wear_vs_econ.png"),
       combined, width = 11, height = 8.5, dpi = 200)
ggsave(file.path(out_dir, "fig_comparison_wear_vs_econ.pdf"),
       combined, width = 11, height = 8.5)

cat(sprintf("\nWrote figures to %s\n", out_dir))

# Quick numeric summary
if ("mmt_agc_mean" %in% names(ci)) {
  summary_tbl <- ci |>
    filter(year %in% c(2004, 2024, 2049, 2099)) |>
    select(tag, rcp, harvest, pipeline, year,
           mmt_agc_mean, mmt_agc_lo, mmt_agc_hi,
           any_of(c("mmt_total_c_mean","mmt_total_c_lo","mmt_total_c_hi"))) |>
    arrange(year, rcp, harvest, pipeline)
  write_csv(summary_tbl, file.path(out_dir, "comparison_summary_table.csv"))
  print(summary_tbl, n = Inf)
}
