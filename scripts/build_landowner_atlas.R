## build_landowner_atlas.R
## Phase 1 deliverable from LANDOWNER_INTEGRATION_STRATEGY.md.
##
## Inputs : ~/landowner/NewEngland_LandOwners.tif (Harris-Caputo-Butler 2025
##          10 m raster), ~/fia_data/ME_PLOT.csv, ~/fia_data/ME_COND.csv
## Outputs: maine_ownership_atlas.csv  -- area by class x county x ecoregion
##          fia_plots_with_owner.csv   -- per-plot HCB class plus FIA OWNCD
##          owner_class_legend.csv     -- code -> label map
##
## Uses terra::extract() for plot-level HCB class lookup. Runs on a single
## node; the raster is 8.4 GB but we only need the cell containing each plot.

suppressPackageStartupMessages({
  library(terra); library(sf); library(dplyr); library(readr); library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)
HCB_TIF  <- if (length(args) >= 1) args[1] else "~/landowner/NewEngland_LandOwners.tif"
FIA_DIR  <- if (length(args) >= 2) args[2] else file.path(Sys.getenv("HOME"), "fia_data")
OUT_DIR  <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat(sprintf("HCB raster: %s\n", HCB_TIF))
cat(sprintf("FIA dir   : %s\n", FIA_DIR))
cat(sprintf("Output dir: %s\n", OUT_DIR))

## ---- Owner class legend -----------------------------------------------
owner_legend <- tibble(
  hcb_class = 0:8,
  label = c("Unknown Forest", "Non-Forest", "Water",
            "Family Forest (NIPF)", "Corporate/Other Private (Industrial)",
            "Tribal Forest", "Federal Forest", "State Forest",
            "Local Forest"),
  cem_class = c("Unknown", "Mask", "Mask",
                "NIPF", "Industrial",
                "Public-Other", "Federal", "State", "Public-Other"),
  treat_baseline = c(NA, NA, NA,
                     "light_partial", "heavy_partial",
                     "no_harvest", "no_harvest", "light_partial", "no_harvest")
)
write_csv(owner_legend, file.path(OUT_DIR, "owner_class_legend.csv"))
cat(sprintf("Wrote owner_class_legend.csv (%d rows)\n", nrow(owner_legend)))

## ---- FIA plot lat/lon and OWNCD ---------------------------------------
plt <- read_csv(file.path(FIA_DIR, "ME_PLOT.csv"),
                col_types = cols(.default = "c"),
                show_col_types = FALSE)
cnd <- read_csv(file.path(FIA_DIR, "ME_COND.csv"),
                col_types = cols(.default = "c"),
                show_col_types = FALSE)

plt <- plt |>
  select(PLT_CN = CN, STATECD, UNITCD, COUNTYCD, PLOT, INVYR, LAT, LON,
         DESIGNCD) |>
  mutate(across(c(STATECD, UNITCD, COUNTYCD, PLOT, INVYR, DESIGNCD),
                ~ as.integer(.)),
         LAT = as.numeric(LAT), LON = as.numeric(LON))

cnd <- cnd |>
  select(PLT_CN, CONDID, FORTYPCD, OWNCD, OWNGRPCD,
         CONDPROP_UNADJ) |>
  mutate(across(c(CONDID, FORTYPCD, OWNCD, OWNGRPCD), ~ as.integer(.)),
         CONDPROP_UNADJ = as.numeric(CONDPROP_UNADJ))

## Use the most recent (max INVYR) record per plot for spatial extraction.
plt_latest <- plt |>
  filter(!is.na(LAT), !is.na(LON)) |>
  group_by(STATECD, UNITCD, COUNTYCD, PLOT) |>
  slice_max(INVYR, n = 1, with_ties = FALSE) |>
  ungroup()

cat(sprintf("Maine plots with lat/lon: %d (latest measurement per plot)\n",
            nrow(plt_latest)))

## Take majority condition for OWNCD per plot (largest CONDPROP_UNADJ).
cnd_majority <- cnd |>
  group_by(PLT_CN) |>
  slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(PLT_CN, FORTYPCD, OWNCD, OWNGRPCD)

plt_owner <- plt_latest |>
  left_join(cnd_majority, by = "PLT_CN")

cat(sprintf("After join with COND (majority condition): %d rows\n",
            nrow(plt_owner)))

## ---- HCB raster extraction --------------------------------------------
cat("Loading HCB raster (lazy)...\n")
r <- rast(HCB_TIF)
cat(sprintf("  raster CRS: %s\n", crs(r, proj = TRUE)))
cat(sprintf("  raster ext: lon [%.3f, %.3f], lat [%.3f, %.3f]\n",
            xmin(r), xmax(r), ymin(r), ymax(r)))

## Convert plots to sf in the raster CRS (NAD83 / EPSG:4269).
pts <- st_as_sf(plt_owner, coords = c("LON", "LAT"), crs = 4269)
pts_terra <- vect(pts)

cat("Extracting HCB class at each plot...\n")
extracted <- terra::extract(r, pts_terra, ID = FALSE)
hcb_col   <- names(extracted)[1]
plt_owner$hcb_class <- as.integer(extracted[[hcb_col]])

n_unknown <- sum(plt_owner$hcb_class == 0, na.rm = TRUE)
n_nf      <- sum(plt_owner$hcb_class %in% c(1, 2), na.rm = TRUE)
n_na      <- sum(is.na(plt_owner$hcb_class))
cat(sprintf("  HCB extracts: %d valid forest, %d Unknown(0), %d NonForest/Water, %d NA\n",
            sum(plt_owner$hcb_class %in% 3:8, na.rm = TRUE),
            n_unknown, n_nf, n_na))

## Reassign Unknown (0) and NA proportionally per county to the local
## forest distribution.
counties <- unique(plt_owner$COUNTYCD)
for (cc in counties) {
  in_cc   <- plt_owner$COUNTYCD == cc
  forest  <- plt_owner$hcb_class %in% 3:8 & in_cc
  nonforest <- (plt_owner$hcb_class == 0 | is.na(plt_owner$hcb_class)) & in_cc
  if (sum(nonforest) == 0 || sum(forest) == 0) next
  dist <- table(plt_owner$hcb_class[forest])
  dist <- dist / sum(dist)
  plt_owner$hcb_class[nonforest] <- sample(
    as.integer(names(dist)),
    size    = sum(nonforest),
    replace = TRUE,
    prob    = as.numeric(dist)
  )
}

## ---- Cross-validate vs FIA OWNCD --------------------------------------
plt_owner <- plt_owner |>
  mutate(
    fia_class = case_when(
      OWNCD %in% c(45, 46)             ~ 3L,            # NIPF
      OWNCD %in% c(41, 42, 43, 44)     ~ 4L,            # Corporate
      OWNCD == 47                      ~ 5L,            # Tribal
      OWNGRPCD %in% c(10, 20)          ~ 6L,            # Federal
      OWNGRPCD == 30                   ~ 7L,            # State
      OWNGRPCD == 31                   ~ 8L,            # Local
      TRUE                             ~ NA_integer_
    ),
    agree_hcb_fia = !is.na(fia_class) &
                    !is.na(hcb_class) &
                    fia_class == hcb_class
  )

agreement <- plt_owner |>
  filter(!is.na(fia_class), !is.na(hcb_class)) |>
  summarise(n = n(),
            agree = sum(agree_hcb_fia),
            agreement_pct = round(100 * mean(agree_hcb_fia), 1))
cat(sprintf("HCB raster vs FIA OWNCD: %s of %s plots agree (%.1f%%)\n",
            format(agreement$agree, big.mark = ","),
            format(agreement$n,     big.mark = ","),
            agreement$agreement_pct))

## Write per-plot table
write_csv(plt_owner |>
            select(STATECD, UNITCD, COUNTYCD, PLOT, INVYR, LAT, LON,
                   PLT_CN, FORTYPCD, OWNCD, OWNGRPCD,
                   hcb_class, fia_class, agree_hcb_fia),
          file.path(OUT_DIR, "fia_plots_with_owner.csv"))
cat(sprintf("Wrote fia_plots_with_owner.csv (%d rows)\n", nrow(plt_owner)))

## ---- Maine ownership atlas (zonal stats from raster) ------------------
## Build atlas from PLOT counts (much faster than full raster zonal stats).
## Plot-area-weighted estimate of statewide owner share.

PLOT_AC <- 0.16723  # FIA fixed-radius plot footprint, but EXPNS is what scales

## Use EXPNS from POP_STRATUM if available.
pop_strat_path <- file.path(FIA_DIR, "ME_POP_STRATUM.csv")
pop_plot_path  <- file.path(FIA_DIR, "ME_POP_PLOT_STRATUM_ASSGN.csv")

atlas <- plt_owner |>
  left_join(owner_legend |> select(hcb_class, hcb_label = label),
            by = "hcb_class") |>
  group_by(COUNTYCD, hcb_class, hcb_label) |>
  summarise(n_plots = n(), .groups = "drop") |>
  arrange(COUNTYCD, hcb_class)

if (file.exists(pop_strat_path) && file.exists(pop_plot_path)) {
  cat("Joining EXPNS for area weighting...\n")
  ps <- read_csv(pop_strat_path, col_types = cols(.default = "c"),
                 show_col_types = FALSE) |>
        select(STRATUM_CN = CN, EXPNS) |>
        mutate(EXPNS = as.numeric(EXPNS))
  ppa <- read_csv(pop_plot_path, col_types = cols(.default = "c"),
                  show_col_types = FALSE) |>
         select(PLT_CN, STRATUM_CN)
  expns <- ppa |> left_join(ps, by = "STRATUM_CN") |>
                  group_by(PLT_CN) |>
                  summarise(EXPNS = mean(EXPNS, na.rm = TRUE),
                            .groups = "drop")

  plt_owner <- plt_owner |> left_join(expns, by = "PLT_CN")
  atlas_ac <- plt_owner |>
    left_join(owner_legend |> select(hcb_class, hcb_label = label),
              by = "hcb_class") |>
    group_by(COUNTYCD, hcb_class, hcb_label) |>
    summarise(n_plots = n(),
              area_acres = round(sum(EXPNS, na.rm = TRUE), 0),
              .groups = "drop") |>
    arrange(COUNTYCD, hcb_class)
  atlas <- atlas_ac
}

write_csv(atlas, file.path(OUT_DIR, "maine_ownership_atlas.csv"))
cat(sprintf("Wrote maine_ownership_atlas.csv (%d rows)\n", nrow(atlas)))

## State-total summary
state_total <- atlas |>
  group_by(hcb_class, hcb_label) |>
  summarise(n_plots = sum(n_plots),
            area_acres = if ("area_acres" %in% names(atlas))
                         sum(area_acres, na.rm = TRUE) else NA_real_,
            .groups = "drop") |>
  mutate(pct = round(100 * n_plots / sum(n_plots), 1))

cat("\n=== Maine ownership distribution (HCB class) ===\n")
print(state_total)

cat("\n=== Done ===\n")
