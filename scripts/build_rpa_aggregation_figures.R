#!/usr/bin/env Rscript
# build_rpa_aggregation_figures.R
# Build cross subregion comparison figures from the conus_hcs RPA aggregation
# output landed 16 May 2026.
#
# Inputs:  figures/rpa_by_subregion_20260516.csv
# Outputs: figures/rpa_p_harvest_by_subregion.png
#          figures/rpa_removal_per_ha_by_subregion.png
#          figures/rpa_subregion_panel.png  (2 panel composite)

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(patchwork)
})

setwd(here::here())

ROOT <- normalizePath(".")
IN_CSV  <- file.path(ROOT, "figures/rpa_by_subregion_20260516.csv")
OUT_DIR <- file.path(ROOT, "figures")

dat <- readr::read_csv(IN_CSV, show_col_types = FALSE)

ME_RPA_REF <- 0.10  # Maine RPA per cycle harvest rate reference (FS 366, 2021)

# Order subregions by removal_per_ha for clarity
dat <- dat |>
  dplyr::mutate(
    rpa_subregion = factor(
      rpa_subregion,
      levels = c("North_Central", "South_East", "South_Central",
                 "Pacific_Northwest")
    )
  )

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold"),
    plot.caption     = element_text(size = 9, hjust = 0, color = "grey40")
  )

# Panel A: p_harvest by subregion with 95% interval bars
p_phar <- ggplot(dat, aes(x = rpa_subregion, y = p_harvest)) +
  geom_col(fill = "#3a78a3", alpha = 0.85) +
  geom_errorbar(
    aes(ymin = p_harvest_lo, ymax = p_harvest_hi),
    width = 0.2, color = "grey30", linewidth = 0.4
  ) +
  geom_hline(
    yintercept = ME_RPA_REF, linetype = "dashed",
    color = "#c0504d", linewidth = 0.6
  ) +
  annotate(
    "text", x = 4.4, y = ME_RPA_REF + 0.04,
    label = "ME RPA reference (0.10)",
    color = "#c0504d", size = 3, hjust = 1
  ) +
  scale_y_continuous(limits = c(0, 1.05), expand = c(0, 0)) +
  labs(
    title    = "M1 harvest occurrence probability by RPA subregion",
    subtitle = "Saturation at 0.87 to 0.92 across all subregions reflects re-measured panel pair sample bias",
    x = NULL, y = "P(harvest) per 5 year cycle"
  ) +
  theme_pub

# Panel B: removal per hectare by subregion
p_rem <- ggplot(dat, aes(x = rpa_subregion, y = removal_per_ha)) +
  geom_col(fill = "#7a9c6d", alpha = 0.85) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(
    title    = "Predicted removal per hectare by RPA subregion",
    subtitle = "Magnitudes within plausible RPA range despite saturated probability",
    x = NULL, y = "Removal (volume units per ha)"
  ) +
  theme_pub

# Composite
p_combined <- (p_phar / p_rem) +
  plot_annotation(
    caption = paste(
      "Source: ~/conus_hcs/output/phase4/rpa_by_subregion.csv (SLURM 9717200,",
      "Layer 22 patch, 16 May 2026)",
      "\nFour subregions covered (12 STATECD): NC, SE, SC, PNW.",
      "Missing: NE, RM, PSW. Pacific_Northwest only 50 plots."
    )
  )

ggsave(file.path(OUT_DIR, "rpa_p_harvest_by_subregion.png"),
       plot = p_phar, width = 7, height = 4, dpi = 150, bg = "white")
ggsave(file.path(OUT_DIR, "rpa_removal_per_ha_by_subregion.png"),
       plot = p_rem,  width = 7, height = 4, dpi = 150, bg = "white")
ggsave(file.path(OUT_DIR, "rpa_subregion_panel.png"),
       plot = p_combined, width = 8, height = 7, dpi = 150, bg = "white")

cat("RPA aggregation figures written to figures/\n")
cat("  rpa_p_harvest_by_subregion.png\n")
cat("  rpa_removal_per_ha_by_subregion.png\n")
cat("  rpa_subregion_panel.png\n")
