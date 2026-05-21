#!/usr/bin/env Rscript
## =============================================================================
## scripts/build_hindcast_bias_figure.R
##
## Multistate hindcast bias percent by cycle figure for the manuscript.
## Reads all HINDCAST_*.csv files in output/hindcast/, computes bias percent
## per state per cycle, and emits a single panel figure (year on x, bias pct
## on y, color by state, faceted by RCP). Highlights the cycle 2 dip and the
## WA persistent negative bias.
##
## Usage:
##   Rscript scripts/build_hindcast_bias_figure.R
##
## Author: 19 May 2026
## =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr)
  library(ggplot2); library(stringr); library(purrr)
})

hindcast_dir <- "output/hindcast"
fig_dir      <- "figures/hindcast"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(hindcast_dir, pattern = "^HINDCAST_.*\\.csv$",
                    full.names = TRUE)

parse_meta <- function(fname) {
  base <- tools::file_path_sans_ext(basename(fname))
  parts <- stringr::str_split(base, "_", simplify = TRUE)
  state <- parts[, 2]
  ## tag is everything after HINDCAST_<state>_
  tag <- sub(paste0("HINDCAST_", state, "_"), "", base)
  rcp <- ifelse(grepl("rcp85", tag), 85, 45)
  vintage <- dplyr::case_when(
    grepl("r21", tag) ~ "r21",
    grepl("_p3hindcast$", tag) ~ "p3hindcast",
    grepl("_p3lite$", tag) ~ "p3lite",
    grepl("_p3$", tag) ~ "p3",
    grepl("_p1$", tag) ~ "p1",
    TRUE ~ "other"
  )
  data.frame(file = fname, state = state, rcp = rcp,
             vintage = vintage, tag = tag,
             stringsAsFactors = FALSE)
}

meta <- purrr::map_dfr(files, parse_meta)
cat("Files:\n"); print(meta)

load_one <- function(file, state, rcp, vintage, tag) {
  d <- readr::read_csv(file, show_col_types = FALSE)
  d <- d |> dplyr::filter(!is.na(cycle_match) & !is.na(proj_subj_agc_mmt))
  if (nrow(d) == 0) return(NULL)
  d$state   <- state
  d$rcp     <- rcp
  d$vintage <- vintage
  d$tag     <- tag
  d$bias_pct <- (d$proj_subj_agc_mmt - d$obs_subj_agc_mmt) /
                 d$obs_subj_agc_mmt * 100
  d
}

bias <- purrr::pmap_dfr(meta, load_one)

cat(sprintf("\nLoaded %d rows of valid hindcast points\n", nrow(bias)))
print(bias |> dplyr::select(state, vintage, rcp, cycle_match, year,
                            obs_subj_agc_mmt, proj_subj_agc_mmt,
                            bias_pct))

## Save tidy table
readr::write_csv(bias |> dplyr::select(state, vintage, rcp, cycle_match,
                                       year, obs_subj_agc_mmt,
                                       proj_subj_agc_mmt, bias_pct),
                 file.path(fig_dir, "multistate_hindcast_bias.csv"))

## ---- Plot ----------------------------------------------------------------
state_colors <- c(ME = "#1b9e77", MN = "#d95f02", WA = "#7570b3", GA = "#e7298a")
vintage_shapes <- c(p1 = 16, p3 = 17, p3lite = 15, p3hindcast = 4, r21 = 18)

plot_data <- bias |>
  dplyr::filter(vintage %in% c("p1", "p3", "p3lite", "p3hindcast", "r21")) |>
  dplyr::mutate(rcp_label = paste0("RCP ", rcp / 10),
                state_label = state,
                vintage_label = vintage)

p <- ggplot(plot_data,
            aes(x = year, y = bias_pct,
                colour = state_label, shape = vintage_label,
                group = paste(state, vintage, rcp))) +
  geom_hline(yintercept = 0, colour = "grey50", linetype = "dashed") +
  geom_hline(yintercept = c(-25, 25), colour = "grey80", linetype = "dotted") +
  geom_line(linewidth = 0.7, alpha = 0.7) +
  geom_point(size = 3, alpha = 0.9) +
  facet_wrap(~ rcp_label, ncol = 2) +
  scale_colour_manual(values = state_colors, name = "State") +
  scale_shape_manual(values = vintage_shapes, name = "Vintage") +
  scale_x_continuous(breaks = seq(2004, 2024, by = 5)) +
  scale_y_continuous(breaks = seq(-40, 50, by = 10)) +
  labs(title = "Multistate hindcast bias by cycle",
       subtitle = "Bias percent = (projected - observed) / observed. Dotted lines at +/- 25 pct.",
       x = "Year (cycle midpoint)",
       y = "Bias (%)") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"),
        legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(size = 9, colour = "grey30"))

ggsave(file.path(fig_dir, "multistate_hindcast_bias.png"),
       p, width = 10, height = 5.5, dpi = 300)
ggsave(file.path(fig_dir, "multistate_hindcast_bias.pdf"),
       p, width = 10, height = 5.5)

cat(sprintf("\nWrote: %s/multistate_hindcast_bias.png and .pdf\n", fig_dir))
cat("Done.\n")
