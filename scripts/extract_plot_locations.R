## extract_plot_locations.R
## Pull per-state plot locations + ClimateNA input CSVs from ~/FIA/ENTIRE_PLOT.csv.
##
## Companion to MULTISTATE_PORTABILITY_GAPS.md Section 8 step 3.
##
## ClimateNA accepts a CSV with columns: ID1, ID2, lat, long, el. Hand the
## climatena_input_<STATE>.csv files to ClimateNA externally (or the CLI if
## installed on Cardinal) to generate normals and futures, then drop the
## ClimateNA outputs back into ~/FIA/climate/<STATE>/ for the projection
## pipeline to consume.
##
## Inputs:
##   ~/FIA/ENTIRE_PLOT.csv    national FIA PLOT table (1.98M rows)
##
## Outputs (per state):
##   ~/FIA/climate/plot_locations_<STATE>.csv   STATECD, COUNTYCD, PLOT, LAT, LON, ELEV
##   ~/FIA/climate/climatena_input_<STATE>.csv  ID1, ID2, lat, long, el
##
## Usage on Cardinal login node (no SLURM needed; runs in seconds):
##   module load gcc/12.3.0 R/4.4.0
##   Rscript scripts/extract_plot_locations.R
##
## Or with explicit args:
##   Rscript scripts/extract_plot_locations.R ~/FIA ~/FIA/climate

suppressPackageStartupMessages({
  library(data.table); library(dplyr); library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
FIA_DIR <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "FIA")
OUT_DIR <- if (length(args) >= 2) args[2] else file.path(FIA_DIR, "climate")

dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

## Target states. WA, MN, GA are the multistate expansion targets; ME is
## included as the existing reference for diff comparison.
STATES <- c("ME", "MN", "WA", "GA")
STATECD_LOOKUP <- c(ME = 23L, MN = 27L, WA = 53L, GA = 13L)

cat("============================================\n")
cat("  Extracting plot locations + ClimateNA inputs\n")
cat(sprintf("  FIA dir   : %s\n", FIA_DIR))
cat(sprintf("  Output dir: %s\n", OUT_DIR))
cat(sprintf("  States    : %s\n", paste(STATES, collapse = ", ")))
cat("============================================\n\n")

ENTIRE_PLOT <- file.path(FIA_DIR, "ENTIRE_PLOT.csv")
stopifnot(file.exists(ENTIRE_PLOT))

cat(sprintf("Reading %s ...\n", ENTIRE_PLOT))
plot_all <- data.table::fread(
  ENTIRE_PLOT,
  select = c("CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT",
             "INVYR", "LAT", "LON", "ELEV"),
  data.table = FALSE,
  showProgress = FALSE
)
plot_all <- plot_all[plot_all$STATECD %in% STATECD_LOOKUP, ]
cat(sprintf("  retained %d rows across STATECDs %s\n",
            nrow(plot_all),
            paste(sort(unique(plot_all$STATECD)), collapse = ", ")))

## Latest measurement per plot, valid coords only.
plot_latest <- plot_all |>
  filter(!is.na(LAT), !is.na(LON)) |>
  group_by(STATECD, COUNTYCD, PLOT) |>
  slice_max(INVYR, n = 1, with_ties = FALSE) |>
  ungroup()

cat(sprintf("Latest measurement per unique plot: %d rows\n", nrow(plot_latest)))

## Per state writes.
summary_rows <- list()
for (s in STATES) {
  cd <- STATECD_LOOKUP[[s]]
  pl <- plot_latest |>
    filter(STATECD == cd) |>
    select(STATECD, COUNTYCD, PLOT, LAT, LON, ELEV) |>
    mutate(ELEV = ifelse(is.na(ELEV), 0, ELEV))

  ## plot_locations CSV (general purpose lat/lon)
  loc_path <- file.path(OUT_DIR, sprintf("plot_locations_%s.csv", s))
  write_csv(pl, loc_path)

  ## ClimateNA input format: ID1, ID2, lat, long, el
  cna <- pl |>
    transmute(ID1  = paste(STATECD, COUNTYCD, PLOT, sep = "_"),
              ID2  = 1L,
              lat  = LAT,
              long = LON,
              el   = ELEV)
  cna_path <- file.path(OUT_DIR, sprintf("climatena_input_%s.csv", s))
  write_csv(cna, cna_path)

  cat(sprintf("  %-3s  STATECD=%-3d  plots=%6d  lat=[%.2f, %.2f]  lon=[%.2f, %.2f]  elev=[%.0f, %.0f]\n",
              s, cd, nrow(pl),
              min(pl$LAT, na.rm = TRUE),  max(pl$LAT, na.rm = TRUE),
              min(pl$LON, na.rm = TRUE),  max(pl$LON, na.rm = TRUE),
              min(pl$ELEV, na.rm = TRUE), max(pl$ELEV, na.rm = TRUE)))

  summary_rows[[s]] <- tibble::tibble(
    state = s, statecd = cd, n_plots = nrow(pl),
    lat_min = min(pl$LAT,  na.rm = TRUE), lat_max = max(pl$LAT,  na.rm = TRUE),
    lon_min = min(pl$LON,  na.rm = TRUE), lon_max = max(pl$LON,  na.rm = TRUE),
    elev_min = min(pl$ELEV, na.rm = TRUE), elev_max = max(pl$ELEV, na.rm = TRUE),
    plot_locations_csv = loc_path,
    climatena_input_csv = cna_path
  )
}

summary_tab <- bind_rows(summary_rows)
write_csv(summary_tab, file.path(OUT_DIR, "plot_locations_summary.csv"))

cat(sprintf("\nSummary table written to %s/plot_locations_summary.csv\n", OUT_DIR))
cat("\nNext steps:\n")
cat("  1. Hand each climatena_input_<STATE>.csv to ClimateNA (GUI or CLI)\n")
cat("     to produce normals and SSP/RCP futures.\n")
cat("  2. Drop ClimateNA outputs into ~/FIA/climate/<STATE>/ subfolders.\n")
cat("  3. Adapt R/08_climate_interface.R to read from ~/FIA/climate.\n")
cat("\nDone.\n")
