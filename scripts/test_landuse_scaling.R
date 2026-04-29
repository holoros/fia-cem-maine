## Quick offline check that the land-use scaling logic produces sane numbers
## without needing to run the full expansion. Mocks sim_totals shape and
## applies the same multiplicative formula as expand_to_state().

base_acres       <- 17.5e6      # ~17.5 M ac forest in ME
cycle_length_yrs <- 5L
new_forest_c_frac <- 0.30
cycles <- 0:14   # 75 yr horizon (matches r17 settings)

scenarios <- list(
  list(name = "BAU",          conv = 5295,  aff = 0),
  list(name = "Develop2x",    conv = 10590, aff = 0),
  list(name = "Reforest25k",  conv = 5295,  aff = 25000),
  list(name = "Reforest50k",  conv = 5295,  aff = 50000),
  list(name = "LowDev_HiRefor", conv = 2500, aff = 50000)
)

bau_agc <- 268    # MMT, calibrated 2004 baseline

cat(sprintf("Baseline forest area: %s ac\n", format(base_acres, big.mark = ",")))
cat(sprintf("Baseline AGC at cycle 0: %.0f MMT\n", bau_agc))
cat(sprintf("New-forest C frac: %.2f\n\n", new_forest_c_frac))

cat(sprintf("%-15s %5s %12s %12s %10s %8s\n",
            "Scenario", "Year", "ConvAc(cum)", "AffAc(cum)",
            "AreaFactor", "AGC(MMT)"))

for (s in scenarios) {
  for (cyc in c(0, 5, 10, 14)) {
    yrs    <- cyc * cycle_length_yrs
    conv   <- s$conv * yrs
    aff    <- s$aff  * yrs
    af_pre <- (base_acres - conv) / base_acres
    af_aff <- (aff * new_forest_c_frac) / base_acres
    af     <- pmax(0, af_pre + af_aff)
    agc    <- bau_agc * af
    cat(sprintf("%-15s %5d %12s %12s %10.4f %8.1f\n",
                s$name, 2004 + yrs,
                format(round(conv), big.mark = ","),
                format(round(aff),  big.mark = ","),
                af, agc))
  }
  cat("\n")
}
