## build_county_harvest_lookup.R
## Convert Maine SAR per-county harvest rates into a logit offset table that
## can be added to the Wear & Coulston (2025) harvest-choice intercept by
## 03_harvest_choice.R. Produces a small calibration CSV the projection
## engine reads via --use_county_harvest.
##
## Logic: the projection's base harvest probability is a Northeast-region
## logit. The county multiplier from SAR is applied as an additive logit
## offset such that the implied per-cycle probability roughly matches the
## observed county harvest rate.
##
##   p_county = sigmoid(intercept_NE + beta_county + ...)
##   With beta_county = log(rate_county / rate_state)
##
## We cap |beta_county| at ±1.5 (sigmoid gain factor of about 4.5x) to avoid
## edge cases where Sagadahoc-style outliers blow up to p > 0.9.

base <- "/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results"
cal <- read.csv(file.path(base, "econ_config",
                          "maine_county_harvest_calibration.csv"),
                stringsAsFactors = FALSE)

cap <- 1.5     # logit cap, +/-
log_offset <- log(cal$rate_relative_to_statewide)
log_offset[is.na(log_offset) | !is.finite(log_offset)] <- 0
log_offset_capped <- pmin(pmax(log_offset, -cap), cap)

## Recompute partial/clearcut shares from raw acreage (the source CSV
## had pre-aggregated mean_partial_share = 1 for every county which is
## a binding error in upstream aggregation). Use raw partial / clearcut
## acres instead.
total_act <- cal$mean_partial_ac + cal$mean_clearcut_ac
clearcut_share_real <- ifelse(total_act > 0,
                              cal$mean_clearcut_ac / total_act, 0)
partial_share_real  <- 1 - clearcut_share_real

out <- data.frame(
  STATECD                = 23L,
  COUNTYCD               = cal$COUNTYCD,
  county                 = cal$county,
  rate_per_yr            = round(cal$harvest_rate_per_yr, 5),
  rate_rel_to_statewide  = round(cal$rate_relative_to_statewide, 3),
  beta_county_raw        = round(log_offset, 4),
  beta_county_capped     = round(log_offset_capped, 4),
  partial_share          = round(partial_share_real,  3),
  clearcut_share         = round(clearcut_share_real, 3)
)
out <- out[order(-out$beta_county_capped), ]

write.csv(out, file.path(base, "econ_config",
                          "maine_county_harvest_logit_offset.csv"),
          row.names = FALSE)

cat("Maine per-county harvest logit offset table\n")
cat(sprintf("  log offset cap: ±%.1f\n", cap))
print(out, row.names = FALSE)

cat("\nSummary (county count by direction):\n")
cat(sprintf("  Above-state rate (offset > 0): %d\n", sum(out$beta_county_capped > 0)))
cat(sprintf("  Below-state rate (offset < 0): %d\n", sum(out$beta_county_capped < 0)))
cat(sprintf("  Mean offset: %.3f, SD: %.3f\n",
            mean(out$beta_county_capped), sd(out$beta_county_capped)))
cat(sprintf("  Range: %.3f to %.3f\n",
            min(out$beta_county_capped), max(out$beta_county_capped)))
