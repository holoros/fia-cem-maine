## build_hcb_l3_crosswalk_v3.R
## v3 (18 May 2026): emit one row per PLT_CN (every measurement year), not just
## the latest INVYR per plot identity. v2 carried only ~34% of cond_full's
## PLT_CNs because cond_full has a unique PLT_CN per measurement year while v2
## had collapsed those to a single latest row per (STATECD, UNITCD, COUNTYCD,
## PLOT). Result was iter2 section-coarsening 0% match: most subjects could
## join us_l3code but most donors could not.
##
## v3 strategy:
##   1. Read all plot rows (no slice_max(INVYR))
##   2. Build a unique plot identity table on LAT/LON
##   3. HCB raster extract and L3 polygon st_join performed ONCE per identity
##   4. Broadcast spatial attributes back to every PLT_CN that shares the
##      identity. LAT/LON do not change across remeasurements so this is safe.
##   5. OWNCD/FORTYPCD remain per-measurement (joined per PLT_CN majority cond)
##
## Inputs (same as v1/v2):
##   ~/landowner/US_forest_ownership.tif    CONUS HCB raster, NAD83
##   ~/Disturbance/us_eco_l3.shp            L3 ecoregion polygons
##   ~/FIA/ENTIRE_PLOT.csv                  national FIA PLOT table
##   ~/FIA/ENTIRE_COND.csv                  national FIA COND table
##
## Output:
##   <OUT_DIR>/fia_plots_hcb_l3.csv   one row per PLT_CN across 21 states
##
## Usage on Cardinal:
##   module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0
##   Rscript scripts/build_hcb_l3_crosswalk_v3.R \
##       ~/landowner/US_forest_ownership.tif \
##       ~/Disturbance/us_eco_l3.shp \
##       ~/FIA \
##       ~/fia_cem_projections/config

suppressPackageStartupMessages({
  library(terra); library(sf); library(dplyr); library(readr); library(tidyr)
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
HCB_TIF <- if (length(args) >= 1) args[1] else "~/landowner/US_forest_ownership.tif"
L3_SHP  <- if (length(args) >= 2) args[2] else "~/Disturbance/us_eco_l3.shp"
FIA_DIR <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "FIA")
OUT_DIR <- if (length(args) >= 4) args[4] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("============================================\n")
cat("  HCB x L3 ecoregion plot crosswalk builder v3\n")
cat("  ONE ROW PER PLT_CN (per measurement year)\n")
cat(sprintf("  HCB raster : %s\n", HCB_TIF))
cat(sprintf("  L3 shape   : %s\n", L3_SHP))
cat(sprintf("  FIA dir    : %s\n", FIA_DIR))
cat(sprintf("  Output dir : %s\n", OUT_DIR))
cat("============================================\n\n")

stopifnot(file.exists(HCB_TIF), file.exists(L3_SHP), dir.exists(FIA_DIR))

STATES <- c(
  "ME", "MN", "WA", "GA",
  "NH", "VT", "NY", "MA", "CT", "RI",
  "WI", "MI", "IA",
  "OR", "ID", "MT",
  "FL", "SC", "NC", "TN", "AL"
)
STATECD_LOOKUP <- c(
  ME = 23L, MN = 27L, WA = 53L, GA = 13L,
  NH = 33L, VT = 50L, NY = 36L, MA = 25L, CT = 9L, RI = 44L,
  WI = 55L, MI = 26L, IA = 19L,
  OR = 41L, ID = 16L, MT = 30L,
  FL = 12L, SC = 45L, NC = 37L, TN = 47L, AL = 1L
)

## ---- Load ENTIRE FIA tables ---------------------------------------------
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

## ---- HCB raster ---------------------------------------------------------
cat("\nLoading HCB raster...\n")
hcb <- terra::rast(HCB_TIF)
cat(sprintf("  CRS: %s\n", terra::crs(hcb, describe = TRUE)$code))

## ---- L3 polygons --------------------------------------------------------
cat("\nLoading L3 ecoregion polygons...\n")
l3 <- sf::st_read(L3_SHP, quiet = TRUE)
l3_crs <- sf::st_crs(l3)
cat(sprintf("  L3 polygons: %d features\n", nrow(l3)))

l3_code_col <- intersect(c("US_L3CODE", "L3_KEY", "L3CODE", "NA_L3CODE"), names(l3))[1]
l3_name_col <- intersect(c("US_L3NAME", "L3_NAME", "L3NAME", "NA_L3NAME"), names(l3))[1]
if (is.na(l3_code_col)) stop("Could not find L3 code column in shapefile")
if (is.na(l3_name_col)) stop("Could not find L3 name column in shapefile")
cat(sprintf("  L3 code column: %s, name column: %s\n", l3_code_col, l3_name_col))

## ---- HCB to FIA owner class agreement helpers --------------------------
hcb_to_fia_class <- function(hcb_class) {
  dplyr::case_when(
    hcb_class == 3 ~ 3L,
    hcb_class == 4 ~ 3L,
    hcb_class == 5 ~ 3L,
    hcb_class == 6 ~ 1L,
    hcb_class == 7 ~ 2L,
    hcb_class == 8 ~ 2L,
    TRUE ~ 0L
  )
}
fia_owngrpcd_to_class <- function(owngrpcd) {
  dplyr::case_when(
    owngrpcd %in% c(10L, 20L) ~ 1L,
    owngrpcd == 30L           ~ 2L,
    owngrpcd == 40L           ~ 3L,
    TRUE                       ~ 0L
  )
}

## ---- Per-state worker (v3: keep all measurements) -----------------------
process_state <- function(state) {
  cat(sprintf("\n--- %s ---\n", state))
  statecd <- STATECD_LOOKUP[[state]]
  plt <- plot_all[plot_all$STATECD == statecd, ]
  if (nrow(plt) == 0) {
    warning(sprintf("No plots found for STATECD=%d (%s)", statecd, state))
    return(NULL)
  }

  ## Drop rows without coordinates (cannot spatially join).
  plt_xy <- plt |>
    dplyr::filter(!is.na(LAT), !is.na(LON))
  cat(sprintf("  plot rows (all measurements with lat/lon): %d\n", nrow(plt_xy)))

  ## ---- Unique plot identity table -----------------------------------------
  ## A plot identity is (STATECD, UNITCD, COUNTYCD, PLOT). LAT/LON should be
  ## stable across remeasurements but in practice a small jitter can occur as
  ## FIA refines coordinates. Take the median lat/lon per identity (robust to
  ## occasional bad reads).
  ident_xy <- plt_xy |>
    dplyr::group_by(STATECD, UNITCD, COUNTYCD, PLOT) |>
    dplyr::summarise(LAT = stats::median(LAT, na.rm = TRUE),
                     LON = stats::median(LON, na.rm = TRUE),
                     .groups = "drop")
  cat(sprintf("  unique plot identities for spatial extract: %d\n",
              nrow(ident_xy)))

  ## ---- HCB extract on identities -----------------------------------------
  cat("  extracting HCB class at unique identities...\n")
  pts_v <- terra::vect(as.data.frame(ident_xy[, c("LON", "LAT")]),
                       geom = c("LON", "LAT"),
                       crs = "EPSG:4269")
  hcb_vals <- terra::extract(hcb, pts_v)
  ident_xy$hcb_class <- as.integer(hcb_vals[[2]])

  ## ---- L3 st_join on identities ------------------------------------------
  cat("  spatial join to L3 ecoregions...\n")
  pts_sf <- sf::st_as_sf(ident_xy, coords = c("LON", "LAT"), crs = 4269,
                         remove = FALSE)
  pts_sf <- sf::st_transform(pts_sf, l3_crs)
  joined <- sf::st_join(pts_sf, l3[, c(l3_code_col, l3_name_col)],
                        join = sf::st_intersects, left = TRUE)
  ident_xy$us_l3code <- as.integer(as.character(joined[[l3_code_col]]))
  ident_xy$us_l3name <- as.character(joined[[l3_name_col]])

  cat(sprintf("  L3 codes assigned: %d of %d identities (%.1f%%)\n",
              sum(!is.na(ident_xy$us_l3code)), nrow(ident_xy),
              100 * mean(!is.na(ident_xy$us_l3code))))

  ## ---- Per-PLT_CN majority cond (FORTYPCD, OWNCD, OWNGRPCD) --------------
  cnd <- cond_all[cond_all$PLT_CN %in% plt_xy$PLT_CN, ]
  cnd_maj <- cnd |>
    dplyr::group_by(PLT_CN) |>
    dplyr::slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(PLT_CN, FORTYPCD, OWNCD, OWNGRPCD)

  ## ---- Broadcast spatial attrs to every PLT_CN ----------------------------
  plots <- plt_xy |>
    dplyr::left_join(cnd_maj, by = "PLT_CN") |>
    dplyr::left_join(ident_xy |>
                       dplyr::select(STATECD, UNITCD, COUNTYCD, PLOT,
                                     hcb_class, us_l3code, us_l3name),
                     by = c("STATECD", "UNITCD", "COUNTYCD", "PLOT")) |>
    dplyr::mutate(fia_class = fia_owngrpcd_to_class(OWNGRPCD),
                  hcb_simple = hcb_to_fia_class(hcb_class),
                  agree_hcb_fia = (fia_class == hcb_simple)) |>
    dplyr::select(-hcb_simple)

  cat(sprintf("  output PLT_CN rows for %s: %d\n", state, nrow(plots)))
  cat(sprintf("  PLT_CN with us_l3code: %d (%.1f%%)\n",
              sum(!is.na(plots$us_l3code)),
              100 * mean(!is.na(plots$us_l3code))))

  plots[, c("STATECD", "UNITCD", "COUNTYCD", "PLOT", "INVYR",
            "LAT", "LON", "PLT_CN",
            "FORTYPCD", "OWNCD", "OWNGRPCD",
            "hcb_class", "fia_class", "agree_hcb_fia",
            "us_l3code", "us_l3name")]
}

## ---- Run per state and combine ------------------------------------------
results <- lapply(STATES, function(s) {
  tryCatch(process_state(s),
           error = function(e) {
             message(sprintf("ERROR processing %s: %s", s, e$message))
             NULL
           })
})
names(results) <- STATES
results <- results[!vapply(results, is.null, logical(1))]

if (length(results) == 0) stop("No states processed successfully")

combined <- dplyr::bind_rows(results)
cat(sprintf("\n============================================\n"))
cat(sprintf("  Combined output: %d rows across %d states\n",
            nrow(combined), length(results)))

## ---- Per state summary --------------------------------------------------
summary_tab <- combined |>
  dplyr::group_by(STATECD) |>
  dplyr::summarise(n_pltcn = dplyr::n(),
                   n_identities = dplyr::n_distinct(paste(UNITCD, COUNTYCD, PLOT)),
                   n_l3_ecoregions = length(unique(us_l3code[!is.na(us_l3code)])),
                   pct_l3_assigned = 100 * mean(!is.na(us_l3code)),
                   pct_hcb_known = 100 * mean(hcb_class %in% 3:8, na.rm = TRUE),
                   pct_agree = 100 * mean(agree_hcb_fia, na.rm = TRUE),
                   .groups = "drop")
cat("\nPer state summary:\n")
print(summary_tab)

## ---- Write outputs -------------------------------------------------------
out_csv <- file.path(OUT_DIR, "fia_plots_hcb_l3.csv")
backup_csv <- file.path(OUT_DIR, "fia_plots_hcb_l3.v2_backup.csv")
if (file.exists(out_csv) && !file.exists(backup_csv)) {
  file.copy(out_csv, backup_csv)
  cat(sprintf("Backed up v2 to: %s\n", backup_csv))
}
readr::write_csv(combined, out_csv)
cat(sprintf("\nWrote: %s (%d rows, %d cols)\n",
            out_csv, nrow(combined), ncol(combined)))

summary_csv <- file.path(OUT_DIR, "fia_plots_hcb_l3_summary.csv")
readr::write_csv(summary_tab, summary_csv)
cat(sprintf("Wrote: %s\n", summary_csv))

cat("\nDone (v3).\n")
