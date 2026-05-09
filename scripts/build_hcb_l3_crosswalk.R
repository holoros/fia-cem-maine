## build_hcb_l3_crosswalk.R
## Foundation step from MULTISTATE_PORTABILITY_GAPS.md (Section 8, step 1).
##
## Builds a per-plot crosswalk joining FIA plot locations to:
##   1. Harris, Caputo, Butler 2025 ownership class (HCB raster)
##   2. EPA Omernik Level III ecoregion (polygon overlay)
##
## Covers four states: ME, MN, WA, GA. Output is one row per plot per state.
##
## Inputs:
##   ~/landowner/US_forest_ownership.tif    CONUS HCB raster, NAD83
##   ~/Disturbance/us_eco_l3_state_boundaries.shp  L3 ecoregion polygons
##   ~/FIA/ENTIRE_PLOT.csv                  national FIA PLOT table
##   ~/FIA/ENTIRE_COND.csv                  national FIA COND table
##
## Output:
##   <OUT_DIR>/fia_plots_hcb_l3.csv         joined plot-level table
##
## Columns of the output CSV:
##   STATECD, UNITCD, COUNTYCD, PLOT, INVYR, LAT, LON, PLT_CN,
##   FORTYPCD, OWNCD, OWNGRPCD,
##   hcb_class, fia_class, agree_hcb_fia,
##   us_l3code, us_l3name
##
## Usage on Cardinal:
##   module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
##   Rscript scripts/build_hcb_l3_crosswalk.R \
##       ~/landowner/US_forest_ownership.tif \
##       ~/Disturbance/us_eco_l3_state_boundaries.shp \
##       ~/FIA \
##       ~/fia_cem_projections/config

suppressPackageStartupMessages({
  library(terra); library(sf); library(dplyr); library(readr); library(tidyr)
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
HCB_TIF <- if (length(args) >= 1) args[1] else "~/landowner/US_forest_ownership.tif"
L3_SHP  <- if (length(args) >= 2) args[2] else "~/Disturbance/us_eco_l3_state_boundaries.shp"
FIA_DIR <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "FIA")
OUT_DIR <- if (length(args) >= 4) args[4] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("============================================\n")
cat("  HCB x L3 ecoregion plot crosswalk builder\n")
cat(sprintf("  HCB raster : %s\n", HCB_TIF))
cat(sprintf("  L3 shape   : %s\n", L3_SHP))
cat(sprintf("  FIA dir    : %s\n", FIA_DIR))
cat(sprintf("  Output dir : %s\n", OUT_DIR))
cat("============================================\n\n")

stopifnot(file.exists(HCB_TIF), file.exists(L3_SHP), dir.exists(FIA_DIR))

## Target states for this audit batch.
STATES <- c("ME", "MN", "WA", "GA")
STATECD_LOOKUP <- c(ME = 23L, MN = 27L, WA = 53L, GA = 13L)

## ---- Load ENTIRE FIA tables once and filter to target STATECDs ----------
## ~/FIA/ENTIRE_PLOT.csv is 1.98M rows, 443 MB. data.table::fread is fast and
## memory-efficient; we filter to the four target states immediately.
ENTIRE_PLOT <- file.path(FIA_DIR, "ENTIRE_PLOT.csv")
ENTIRE_COND <- file.path(FIA_DIR, "ENTIRE_COND.csv")
stopifnot(file.exists(ENTIRE_PLOT), file.exists(ENTIRE_COND))

cat(sprintf("Reading %s...\n", ENTIRE_PLOT))
plot_all <- data.table::fread(
  ENTIRE_PLOT,
  select = c("CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT",
             "INVYR", "LAT", "LON", "DESIGNCD"),
  data.table = FALSE,
  showProgress = FALSE
)
plot_all <- plot_all[plot_all$STATECD %in% STATECD_LOOKUP, ]
cat(sprintf("  retained %d plot rows across STATECDs %s\n",
            nrow(plot_all),
            paste(sort(unique(plot_all$STATECD)), collapse = ", ")))
names(plot_all)[names(plot_all) == "CN"] <- "PLT_CN"

cat(sprintf("Reading %s...\n", ENTIRE_COND))
cond_all <- data.table::fread(
  ENTIRE_COND,
  select = c("PLT_CN", "CONDID", "FORTYPCD", "OWNCD", "OWNGRPCD",
             "CONDPROP_UNADJ"),
  data.table = FALSE,
  showProgress = FALSE
)
cond_all <- cond_all[cond_all$PLT_CN %in% plot_all$PLT_CN, ]
cat(sprintf("  retained %d cond rows for those plots\n", nrow(cond_all)))

## Load HCB raster (uses overviews for fast point queries).
cat("Loading HCB raster...\n")
hcb <- terra::rast(HCB_TIF)
cat(sprintf("  CRS: %s\n", terra::crs(hcb, describe = TRUE)$code))
cat(sprintf("  Pixel size: %.6f deg (~%.0f m)\n",
            terra::res(hcb)[1], terra::res(hcb)[1] * 111000))

## Load L3 ecoregion polygons.
cat("\nLoading L3 ecoregion polygons...\n")
l3 <- sf::st_read(L3_SHP, quiet = TRUE)
l3_crs <- sf::st_crs(l3)
cat(sprintf("  L3 polygons: %d features\n", nrow(l3)))
cat(sprintf("  Columns: %s\n", paste(names(l3), collapse = ", ")))

## Detect L3 column names (shapefile field names vary by source).
l3_code_col <- intersect(c("US_L3CODE", "L3_KEY", "L3CODE", "NA_L3CODE"), names(l3))[1]
l3_name_col <- intersect(c("US_L3NAME", "L3_NAME", "L3NAME", "NA_L3NAME"), names(l3))[1]
if (is.na(l3_code_col)) stop("Could not find L3 code column in shapefile")
if (is.na(l3_name_col)) stop("Could not find L3 name column in shapefile")
cat(sprintf("  L3 code column: %s\n", l3_code_col))
cat(sprintf("  L3 name column: %s\n", l3_name_col))

## ---- HCB to FIA owner class agreement check ----------------------------
## Maps the 8-class HCB scheme to FIA OWNGRPCD groups for an "agree" flag.
hcb_to_fia_class <- function(hcb_class) {
  dplyr::case_when(
    hcb_class == 3 ~ 3L,   # Family / NIPF
    hcb_class == 4 ~ 3L,   # Corporate / Industrial = also private
    hcb_class == 5 ~ 3L,   # Tribal = private (FIA OWNGRPCD 40)
    hcb_class == 6 ~ 1L,   # Federal
    hcb_class == 7 ~ 2L,   # State
    hcb_class == 8 ~ 2L,   # Local = also non-federal public
    TRUE ~ 0L              # Unknown / non-forest / water
  )
}
fia_owngrpcd_to_class <- function(owngrpcd) {
  ## OWNGRPCD: 10 = National Forest, 20 = Other federal, 30 = State/local,
  ## 40 = Private. Collapse to 3-level.
  dplyr::case_when(
    owngrpcd %in% c(10L, 20L) ~ 1L,  # Federal
    owngrpcd == 30L           ~ 2L,  # State / local
    owngrpcd == 40L           ~ 3L,  # Private (NIPF + Industrial + Tribal)
    TRUE                       ~ 0L  # Unknown
  )
}

## ---- Per-state worker ---------------------------------------------------
## Operates on pre-filtered plot_all and cond_all (single read of ENTIRE_*).
process_state <- function(state) {
  cat(sprintf("\n--- %s ---\n", state))
  statecd <- STATECD_LOOKUP[[state]]
  plt <- plot_all[plot_all$STATECD == statecd, ]
  if (nrow(plt) == 0) {
    warning(sprintf("No plots found for STATECD=%d (%s)", statecd, state))
    return(NULL)
  }

  ## Latest measurement per plot, keep only those with valid coordinates.
  plt_latest <- plt |>
    dplyr::filter(!is.na(LAT), !is.na(LON)) |>
    dplyr::group_by(STATECD, UNITCD, COUNTYCD, PLOT) |>
    dplyr::slice_max(INVYR, n = 1, with_ties = FALSE) |>
    dplyr::ungroup()
  cnd <- cond_all[cond_all$PLT_CN %in% plt_latest$PLT_CN, ]

  cat(sprintf("  plots with lat/lon (latest per plot): %d\n", nrow(plt_latest)))

  ## Majority condition for OWNCD / FORTYPCD per plot.
  cnd_maj <- cnd |>
    filter(PLT_CN %in% plt_latest$PLT_CN) |>
    group_by(PLT_CN) |>
    slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(PLT_CN, FORTYPCD, OWNCD, OWNGRPCD)

  plots <- plt_latest |>
    left_join(cnd_maj, by = "PLT_CN")

  ## ---- HCB extract ------------------------------------------------------
  cat("  extracting HCB class at plot points...\n")
  pts_v <- terra::vect(as.data.frame(plots[, c("LON", "LAT")]),
                       geom = c("LON", "LAT"),
                       crs = "EPSG:4269")
  hcb_vals <- terra::extract(hcb, pts_v)
  ## terra::extract returns id + raster value column; second col is the value.
  plots$hcb_class <- as.integer(hcb_vals[[2]])

  ## ---- L3 ecoregion st_join --------------------------------------------
  cat("  spatial join to L3 ecoregions...\n")
  pts_sf <- sf::st_as_sf(plots, coords = c("LON", "LAT"), crs = 4269,
                         remove = FALSE)
  pts_sf <- sf::st_transform(pts_sf, l3_crs)
  joined <- sf::st_join(pts_sf, l3[, c(l3_code_col, l3_name_col)],
                        join = sf::st_intersects, left = TRUE)
  plots$us_l3code <- as.integer(as.character(joined[[l3_code_col]]))
  plots$us_l3name <- as.character(joined[[l3_name_col]])

  ## ---- Agreement flag ---------------------------------------------------
  plots <- plots |>
    mutate(fia_class = fia_owngrpcd_to_class(OWNGRPCD),
           hcb_simple = hcb_to_fia_class(hcb_class),
           agree_hcb_fia = (fia_class == hcb_simple)) |>
    select(-hcb_simple)

  cat(sprintf("  HCB class table:\n"))
  print(table(plots$hcb_class, useNA = "ifany"))
  cat(sprintf("  L3 ecoregions touched: %d\n",
              length(unique(plots$us_l3code))))
  cat(sprintf("  HCB-FIA agreement: %.1f%%\n",
              100 * mean(plots$agree_hcb_fia, na.rm = TRUE)))

  plots[, c("STATECD", "UNITCD", "COUNTYCD", "PLOT", "INVYR",
            "LAT", "LON", "PLT_CN",
            "FORTYPCD", "OWNCD", "OWNGRPCD",
            "hcb_class", "fia_class", "agree_hcb_fia",
            "us_l3code", "us_l3name")]
}

## ---- Run per state and combine ------------------------------------------
results <- lapply(STATES, function(s) {
  out <- tryCatch(process_state(s),
                  error = function(e) {
                    message(sprintf("ERROR processing %s: %s", s, e$message))
                    NULL
                  })
  out
})
names(results) <- STATES
results <- results[!vapply(results, is.null, logical(1))]

if (length(results) == 0) {
  stop("No states processed successfully")
}

combined <- bind_rows(results)
cat(sprintf("\n============================================\n"))
cat(sprintf("  Combined output: %d rows across %d states\n",
            nrow(combined), length(results)))
cat(sprintf("  States covered: %s\n",
            paste(unique(combined$STATECD), collapse = ", ")))

## ---- Per state summary ---------------------------------------------------
summary_tab <- combined |>
  group_by(STATECD) |>
  summarise(n_plots = dplyr::n(),
            n_l3_ecoregions = length(unique(us_l3code[!is.na(us_l3code)])),
            pct_hcb_known = 100 * mean(hcb_class %in% 3:8, na.rm = TRUE),
            pct_agree = 100 * mean(agree_hcb_fia, na.rm = TRUE),
            .groups = "drop")
cat("\nPer state summary:\n")
print(summary_tab)

## ---- Write outputs -------------------------------------------------------
out_csv <- file.path(OUT_DIR, "fia_plots_hcb_l3.csv")
write_csv(combined, out_csv)
cat(sprintf("\nWrote: %s (%d rows, %d cols)\n",
            out_csv, nrow(combined), ncol(combined)))

summary_csv <- file.path(OUT_DIR, "fia_plots_hcb_l3_summary.csv")
write_csv(summary_tab, summary_csv)
cat(sprintf("Wrote: %s\n", summary_csv))

cat("\nDone.\n")
