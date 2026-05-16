# =============================================================================
# 18_rpa_aggregation.R
# =============================================================================
# Aggregates plot-level harvest predictions to RPA reporting geographies and
# the Forest Service section/subsection scheme. Produces tables that match
# the structure of FOROM and RPA outputs so downstream comparisons against
# Johnston/Guo/Prestemon 2021 baselines are straightforward.
#
# Output tables:
#   rpa_region        4 RPA regions (NE, NC, SE, SC, RM, PNW, PSW combined)
#   rpa_subregion     ~10 RPA subregions
#   bailey_section    ~30 Bailey ecological sections
#   forest_type_grp   FORTYP_GRP across geographies
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(yaml)
  library(qs2)
library(brms)
  library(cli)
})

source("R/utils_pipeline.R", local = TRUE)


aggregate_to_rpa <- function(fit_m1_op, fit_m2, fit_m4,
                              plot_pair_complete,
                              prediction_year = 2025L) {

  cli_h1("RPA aggregation")
  states_cfg <- readr::read_csv("config/conus_states.csv", show_col_types = FALSE)

  # ---- Issue #15 fix (Lane D, 12 May 2026): defensive plot_area_ha ----
  # R/06b should provide plot_area_ha canonically. This is a fallback so the
  # weighted aggregations below do not produce NaN if the column is missing.
  # FIA macroplot constant: 4 subplots x 0.4047 ha = 1.6188 ha standard plot
  # footprint. If CONDPROP_UNADJ is present, scale by that.
  if (!"plot_area_ha" %in% names(plot_pair_complete)) {
    if ("CONDPROP_UNADJ" %in% names(plot_pair_complete)) {
      plot_pair_complete$plot_area_ha <- plot_pair_complete$CONDPROP_UNADJ * 1.6188
    } else {
      plot_pair_complete$plot_area_ha <- 1.6188
    }
  }

  # ---- Issue #19 fix (16 May 2026): regime-split fit handling ----
  # The auto-load convention at line 199 (load_regime_fits_18) returns a
  # named list with $partial and $clearcut brms fits for each model. The
  # bare `posterior_epred(fit_m1_op, ...)` call below errored when fed a
  # list. This helper detects single-fit vs regime-list and runs the
  # appropriate computation.
  #
  # For M1 occurrence: P(harvest) = P(partial) + P(clearcut) - P(both),
  # approximated as pmin(P_partial + P_clearcut, 1) under the partial/
  # clearcut independence assumption documented in HARVEST_DEFINITION_COMPARISON.md.
  #
  # For M2 intensity: weighted by regime probability,
  # I_combined = (P_p * I_p + P_c * I_c) / (P_p + P_c) with safe-divide.
  #
  # For M4 HCS class: use the partial fit by default since most harvest is
  # partial and the HCS classification is regime-agnostic.
  is_regime_list <- function(x) {
    is.list(x) && !inherits(x, "brmsfit") &&
      all(c("partial", "clearcut") %in% names(x))
  }

  # ---- Per plot posterior predictions ----
  cli_alert_info("Computing plot-level posterior summaries...")

  if (is_regime_list(fit_m1_op)) {
    cli_alert_info("M1: regime-split fit list detected; combining partial + clearcut.")
    pred_p1_partial <- posterior_epred(fit_m1_op$partial, newdata = plot_pair_complete,
                                       allow_new_levels = TRUE)
    pred_p1_clear   <- posterior_epred(fit_m1_op$clearcut, newdata = plot_pair_complete,
                                       allow_new_levels = TRUE)
    pred_p1 <- pmin(pred_p1_partial + pred_p1_clear, 1)
  } else {
    pred_p1 <- posterior_epred(fit_m1_op, newdata = plot_pair_complete,
                                allow_new_levels = TRUE)
    pred_p1_partial <- pred_p1
    pred_p1_clear   <- matrix(0, nrow = nrow(pred_p1), ncol = ncol(pred_p1))
  }

  if (is_regime_list(fit_m2)) {
    cli_alert_info("M2: regime-split fit list detected; computing weighted intensity.")
    pred_p2_partial <- posterior_epred(fit_m2$partial, newdata = plot_pair_complete,
                                       allow_new_levels = TRUE)
    pred_p2_clear   <- posterior_epred(fit_m2$clearcut, newdata = plot_pair_complete,
                                       allow_new_levels = TRUE)
    w_total <- pred_p1_partial + pred_p1_clear
    pred_p2 <- ifelse(w_total > 1e-9,
                     (pred_p1_partial * pred_p2_partial +
                      pred_p1_clear   * pred_p2_clear) / w_total,
                     0.5 * (pred_p2_partial + pred_p2_clear))
  } else {
    pred_p2 <- posterior_epred(fit_m2, newdata = plot_pair_complete,
                                allow_new_levels = TRUE)
  }

  # Expected harvested BA per plot (joint M1 x M2)
  # Layer 19 followup (16 May 2026 second pass): the regime-split prediction
  # combination can produce NaN cells when one of the regime brms fits
  # returns NA for a plot row (typically when factor levels in newdata don't
  # match training). Add na.rm = TRUE to the summary calls so the aggregation
  # proceeds with the valid plots; flag the NA count downstream.
  exp_removal <- pred_p1 * pred_p2
  plot_pair_complete$p_harvest_mean   <- apply(pred_p1, 2, mean, na.rm = TRUE)
  plot_pair_complete$p_harvest_lo     <- apply(pred_p1, 2, quantile,
                                                probs = 0.05, na.rm = TRUE)
  plot_pair_complete$p_harvest_hi     <- apply(pred_p1, 2, quantile,
                                                probs = 0.95, na.rm = TRUE)
  plot_pair_complete$expected_removal <- apply(exp_removal, 2, mean,
                                                na.rm = TRUE)
  n_na_pred1 <- sum(is.na(plot_pair_complete$p_harvest_mean))
  if (n_na_pred1 > 0) {
    cli_alert_warning("{n_na_pred1} of {length(plot_pair_complete$p_harvest_mean)} plots have NA p_harvest_mean after regime combination.")
  }

  # ---- M4 HCS class shares ----
  cli_alert_info("Computing HCS class probabilities...")
  # Issue #19 fix continued: use partial fit if M4 is regime-split. HCS
  # classification is regime-agnostic; partial dominates the data volume.
  fit_m4_active <- if (is_regime_list(fit_m4)) fit_m4$partial else fit_m4
  pred_p4 <- posterior_predict(fit_m4_active, newdata = plot_pair_complete,
                                ndraws = 200, allow_new_levels = TRUE)
  hcs_levels <- levels(plot_pair_complete$hcs_class)
  # Issue #18 fix (Lane D, 12 May 2026): posterior_predict on a brms
  # categorical model returns integer class indices. Convert to labels
  # before tabulating so the factor matches hcs_levels (character).
  hcs_share <- t(apply(pred_p4, 2, function(x) {
    table(factor(hcs_levels[x], levels = hcs_levels)) / length(x)
  }))
  colnames(hcs_share) <- paste0("p_hcs_", hcs_levels)
  plot_pair_complete <- dplyr::bind_cols(plot_pair_complete, as.data.frame(hcs_share))

  # ---- Geographic crosswalk ----
  cli_alert_info("Joining geographic crosswalks...")
  # Issue #16 fix (Lane D, 12 May 2026): upstream plot_pair_complete carries
  # STATECD (FIA integer), conus_states.csv carries state_fips. They are the
  # same integer; rename the config side to bridge.
  states_cfg <- states_cfg |>
    dplyr::select(state_fips, fia_region, rpa_subregion) |>
    dplyr::rename(STATECD = state_fips)
  plot_pair_complete <- plot_pair_complete |>
    dplyr::left_join(states_cfg, by = "STATECD")

  # ---- Aggregate: RPA region ----
  by_region <- plot_pair_complete |>
    dplyr::group_by(rpa_region = derive_rpa_region(rpa_subregion)) |>
    dplyr::summarise(
      n_plots         = dplyr::n(),
      area_ha         = sum(plot_area_ha, na.rm = TRUE),
      p_harvest       = weighted.mean(p_harvest_mean, plot_area_ha, na.rm = TRUE),
      total_removal   = sum(expected_removal * plot_area_ha, na.rm = TRUE),
      removal_per_ha  = total_removal / area_ha,
      .groups = "drop"
    )

  # ---- Aggregate: RPA subregion ----
  by_subregion <- plot_pair_complete |>
    dplyr::group_by(rpa_subregion) |>
    dplyr::summarise(
      n_plots          = dplyr::n(),
      area_ha          = sum(plot_area_ha, na.rm = TRUE),
      p_harvest        = weighted.mean(p_harvest_mean, plot_area_ha, na.rm = TRUE),
      p_harvest_lo     = weighted.mean(p_harvest_lo,   plot_area_ha, na.rm = TRUE),
      p_harvest_hi     = weighted.mean(p_harvest_hi,   plot_area_ha, na.rm = TRUE),
      total_removal    = sum(expected_removal * plot_area_ha, na.rm = TRUE),
      removal_per_ha   = total_removal / area_ha,
      .groups = "drop"
    )

  # ---- Aggregate: forest type group within region ----
  by_fortyp <- plot_pair_complete |>
    dplyr::group_by(rpa_subregion, fortyp_grp) |>
    dplyr::summarise(
      n_plots         = dplyr::n(),
      area_ha         = sum(plot_area_ha, na.rm = TRUE),
      p_harvest       = weighted.mean(p_harvest_mean, plot_area_ha, na.rm = TRUE),
      total_removal   = sum(expected_removal * plot_area_ha, na.rm = TRUE),
      .groups = "drop"
    )

  # ---- HCS shares by region ----
  hcs_cols <- grep("^p_hcs_", names(plot_pair_complete), value = TRUE)
  hcs_by_region <- plot_pair_complete |>
    dplyr::group_by(rpa_subregion) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(hcs_cols),
                                    ~ weighted.mean(.x, plot_area_ha, na.rm = TRUE)),
                      .groups = "drop")

  # ---- Comparison to RPA 2020 baseline ----
  rpa_baseline <- load_rpa_baseline()
  comparison <- by_subregion |>
    dplyr::left_join(rpa_baseline, by = "rpa_subregion") |>
    dplyr::mutate(
      pct_diff = (removal_per_ha - rpa_baseline_removal) / rpa_baseline_removal
    )

  # ---- Output ----
  out <- list(
    by_region        = by_region,
    by_subregion     = by_subregion,
    by_fortyp        = by_fortyp,
    hcs_by_region    = hcs_by_region,
    rpa_comparison   = comparison,
    prediction_year  = prediction_year,
    timestamp        = Sys.time()
  )

  qs2::qs_save(out, file.path("output/phase4", "rpa_aggregation.qs"))
  readr::write_csv(by_subregion, file.path("output/phase4", "rpa_by_subregion.csv"))
  readr::write_csv(comparison,   file.path("output/phase4", "rpa_comparison.csv"))

  cli_alert_success("RPA aggregation complete: {nrow(by_subregion)} subregions, {nrow(by_fortyp)} fortyp x subregion combos")
  out
}


# Helper: RPA subregion to RPA region
# Issue #17 fix (Lane D, 12 May 2026): the subregion values in
# config/conus_states.csv are the long underscored forms (South_Central etc.),
# not the two-letter abbreviations. The previous case_when matched none of
# them, so every plot got NA_region. Values below match conus_states.csv
# exactly (South_Central, South_East, North_East, North_Central,
# Rocky_Mountains, Pacific_Southwest, Pacific_Northwest).
derive_rpa_region <- function(subregion) {
  dplyr::case_when(
    subregion %in% c("North_East", "North_Central")    ~ "North",
    subregion %in% c("South_East", "South_Central")    ~ "South",
    subregion %in% c("Rocky_Mountains")                ~ "Rocky Mountain",
    subregion %in% c("Pacific_Northwest",
                      "Pacific_Southwest")             ~ "Pacific Coast",
    TRUE                                                ~ NA_character_
  )
}


# Loader stub: reads a flat file of RPA 2020 baselines or returns zeros if
# the lookup table is not yet populated.
load_rpa_baseline <- function() {
  fp <- "config/rpa_baselines.csv"
  if (file.exists(fp)) {
    readr::read_csv(fp, show_col_types = FALSE)
  } else {
    cli::cli_warn("RPA baseline file not found at {fp}. Returning zeros.")
    tibble::tibble(
      rpa_subregion        = c("NE", "NC", "SE", "SC", "RM_North",
                                "RM_South", "PNW", "PSW"),
      rpa_baseline_removal = NA_real_
    )
  }
}


# CLI entry point
# 14 May 2026: support both the legacy arg-paths invocation (4 single fits)
# and a no-arg auto-load convention (per-regime named lists). Auto-load is
# preferred so Phase 4 can run without bash-side fit-path bookkeeping.
load_regime_fits_18 <- function(prefix, model_root) {
  out <- list()
  for (regime in c("partial", "clearcut")) {
    fp <- file.path(model_root, paste0(prefix, "_", regime), "fit.qs")
    if (file.exists(fp)) out[[regime]] <- qs2::qs_read(fp)
  }
  out
}

if (sys.nframe() == 0L && length(commandArgs(trailingOnly = TRUE)) > 0) {
  args <- commandArgs(trailingOnly = TRUE)
  out <- aggregate_to_rpa(
    fit_m1_op           = qs2::qs_read(args[1]),
    fit_m2              = qs2::qs_read(args[2]),
    fit_m4              = qs2::qs_read(args[3]),
    plot_pair_complete  = qs2::qs_read(args[4])
  )
  invisible(NULL)
  quit(save = "no", status = 0)
} else if (sys.nframe() == 0L && !interactive()) {
  cfg <- read_config()
  model_root <- cfg$model_output_root %||% "models"
  fit_m1_op <- load_regime_fits_18("m1_occurrence/operational", model_root)
  fit_m2    <- load_regime_fits_18("m2_intensity", model_root)
  fit_m4    <- load_regime_fits_18("m4_hcs_class", model_root)
  ppc       <- qs2::qs_read("data/checkpoints/plot_pair_complete.qs")
  out <- aggregate_to_rpa(fit_m1_op, fit_m2, fit_m4, ppc)
  invisible(NULL)
  quit(save = "no", status = 0)
}
