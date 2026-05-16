#!/usr/bin/env Rscript
# =============================================================================
# scripts/build_hindcast_plot.R
#
# Manuscript ready hindcast figure: observed vs projected AGC for matched years
# across all four states (MN, WA, GA, ME r21 diagnostic), under both RCPs.
#
# Reads the seven HINDCAST_*.csv files from output/hindcast/, tidies them
# into a single comparison dataset, and produces a faceted ggplot with one
# panel per state x RCP combination plus a 1:1 reference line.
#
# Usage:
#   Rscript scripts/build_hindcast_plot.R
#
# Output: figures/p1_hindcast_observed_vs_projected.png
#
# Author: Aaron Weiskittel (built 15 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

input_dir  <- here::here("output", "hindcast")
output_dir <- here::here("figures")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Glob and load
csv_files <- list.files(input_dir, pattern = "^HINDCAST_.*\\.csv$",
                        full.names = TRUE)
if (length(csv_files) == 0) {
  stop("No hindcast CSVs found in ", input_dir,
       ". Pull from Cardinal first.")
}

parse_filename <- function(path) {
  base <- basename(path) |> str_remove("\\.csv$") |> str_remove("^HINDCAST_")
  parts <- str_split_fixed(base, "_", 2)
  list(state = parts[1, 1], tag = parts[1, 2])
}

hindcast_all <- map_dfr(csv_files, function(p) {
  meta <- parse_filename(p)
  read_csv(p, show_col_types = FALSE) |>
    mutate(state = meta$state,
           tag   = meta$tag) |>
    filter(!is.na(proj_subj_agc_mmt))
})

# Add RCP and state label
hindcast_all <- hindcast_all |>
  mutate(
    rcp        = str_extract(tag, "rcp\\d+") |> str_remove("rcp"),
    state_f    = factor(state, levels = c("MN", "WA", "GA", "ME")),
    rcp_label  = factor(if_else(rcp == "45", "RCP 4.5", "RCP 8.5"),
                        levels = c("RCP 4.5", "RCP 8.5")),
    panel      = paste(state_f, rcp_label),
    pct_bias   = 100 * (proj_subj_agc_mmt - obs_subj_agc_mmt) / obs_subj_agc_mmt
  )

cat(sprintf("Loaded %d matched year x state x RCP rows from %d files\n",
            nrow(hindcast_all), length(csv_files)))

# Compute axis range
max_val <- max(c(hindcast_all$obs_subj_agc_mmt,
                 hindcast_all$proj_subj_agc_mmt), na.rm = TRUE) * 1.1

# Plot
pub_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text       = element_text(face = "bold"),
        legend.position  = "bottom",
        plot.title       = element_text(face = "bold", size = 12),
        plot.subtitle    = element_text(size = 10, colour = "grey30"))

fig <- hindcast_all |>
  ggplot(aes(x = obs_subj_agc_mmt, y = proj_subj_agc_mmt)) +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", colour = "grey60") +
  geom_point(aes(colour = year), size = 2.6, alpha = 0.85) +
  geom_text(aes(label = year), nudge_y = max_val * 0.025,
            size = 2.8, colour = "grey25") +
  facet_wrap(~ panel, ncol = 4, scales = "free") +
  scale_colour_viridis_c(option = "plasma", begin = 0.1, end = 0.85,
                         name = "Year") +
  labs(title    = "Hindcast: subject matched projected vs observed AGC",
       subtitle = "Dashed line is the 1:1 reference. Points labelled by EVALID end year.",
       x = "Observed subject matched AGC (MMT)",
       y = "Projected subject matched AGC (MMT)") +
  pub_theme

ggsave(file.path(output_dir, "p1_hindcast_observed_vs_projected.png"),
       fig, width = 14, height = 5, dpi = 200, bg = "white")
cat("  Wrote figures/p1_hindcast_observed_vs_projected.png\n")

# Summary CSV
summary_tbl <- hindcast_all |>
  group_by(state_f, rcp_label) |>
  summarise(
    n_years = n(),
    rmse_mmt = sqrt(mean((proj_subj_agc_mmt - obs_subj_agc_mmt)^2, na.rm = TRUE)),
    bias_mmt = mean(proj_subj_agc_mmt - obs_subj_agc_mmt, na.rm = TRUE),
    pct_bias = 100 * bias_mmt / mean(obs_subj_agc_mmt, na.rm = TRUE),
    .groups  = "drop"
  )

write_csv(summary_tbl, file.path(output_dir, "p1_hindcast_summary.csv"))
cat("  Wrote figures/p1_hindcast_summary.csv\n")

print(summary_tbl)
