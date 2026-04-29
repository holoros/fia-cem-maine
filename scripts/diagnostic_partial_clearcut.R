# =============================================================================
# Title: Diagnostic: partial vs clearcut rate by county in wear_econ runs
# Author: A. Weiskittel
# Date: 2026-04-17
# Description: Reads per_plot_projections.rds from wear_econ scenarios, tabulates
#              the realized share of clearcut vs partial harvests by county
#              and cycle, and compares against the SAR-observed 93/7 statewide
#              split and Aroostook's ~31% clearcut.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

source(file.path(project_dir, "R", "11_economic_harvest.R"))

out_dir <- file.path(project_dir, "output", "diagnostics_20260417")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Find wear_econ RDS files (harvest-containing scenarios only; NH has no harvest
# to diagnose)
rds_files <- list.files(file.path(project_dir, "output"),
                         pattern = "per_plot_projections\\.rds$",
                         recursive = TRUE, full.names = TRUE)
rds_files <- rds_files[grepl("wear_econ", rds_files) & !grepl("_nh", rds_files)]
cat(sprintf("Found %d wear_econ harvest RDS files:\n", length(rds_files)))
for (f in rds_files) cat(sprintf("  %s\n", dirname(f)))

all_split <- purrr::map_dfr(rds_files, function(f) {
  scen <- basename(dirname(f))
  dat <- readRDS(f)
  if (!all(c("was_harvested","is_clearcut","COUNTYCD","cycle") %in% names(dat))) {
    cat(sprintf("  Missing columns in %s\n", scen))
    return(tibble())
  }
  dat |>
    filter(was_harvested == TRUE, !is.na(COUNTYCD), STATECD == 23) |>
    left_join(MAINE_COUNTY_LOOKUP, by = "COUNTYCD") |>
    count(scenario = scen, cycle, county, is_clearcut) |>
    tidyr::pivot_wider(names_from = is_clearcut, values_from = n,
                        values_fill = 0, names_prefix = "cc_") |>
    mutate(n_harvested = cc_TRUE + cc_FALSE,
           clearcut_share = cc_TRUE / pmax(1, n_harvested))
})

write_csv(all_split, file.path(out_dir, "realized_partial_clearcut_by_county.csv"))

# Summary: county-level mean clearcut share across cycles and scenarios
county_summary <- all_split |>
  group_by(county) |>
  summarise(
    mean_clearcut_share = mean(clearcut_share, na.rm = TRUE),
    median_clearcut_share = median(clearcut_share, na.rm = TRUE),
    n_obs = n(),
    total_harvested = sum(n_harvested, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(mean_clearcut_share))

# Compare with SAR observed (from maine_treatment_proportions.csv)
sar <- readr::read_csv(file.path(project_dir, "config",
                                  "maine_treatment_proportions.csv"),
                        show_col_types = FALSE) |>
  group_by(county) |>
  summarise(sar_clearcut_share = mean(clearcut_share, na.rm = TRUE), .groups = "drop")

county_summary <- county_summary |>
  left_join(sar, by = "county") |>
  mutate(diff = mean_clearcut_share - sar_clearcut_share)

write_csv(county_summary, file.path(out_dir, "county_split_comparison.csv"))

cat("\n=== County clearcut share: realized vs SAR observed ===\n")
print(county_summary |>
        select(county, n_obs, mean_clearcut_share, sar_clearcut_share, diff) |>
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      n = Inf)

# Plot: diagonal scatter of realized vs SAR
library(ggplot2)
p <- ggplot(county_summary, aes(x = sar_clearcut_share,
                                 y = mean_clearcut_share,
                                 label = county)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey40") +
  geom_point(color = "#d62728", size = 3) +
  ggrepel::geom_text_repel(size = 3, max.overlaps = 16) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                      limits = c(0, 0.4)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                      limits = c(0, 0.4)) +
  labs(x = "SAR observed clearcut share (2015 to 2023 mean)",
       y = "Pipeline realized clearcut share (100 yr mean)",
       title = "Maine county-level partial vs clearcut split",
       subtitle = "Wear_econ pipeline realized split vs SAR-observed (diagonal = 1:1)") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(out_dir, "fig_partial_clearcut_diag.png"),
       p, width = 7, height = 7, dpi = 200)

cat(sprintf("\nWrote diagnostics to %s\n", out_dir))
