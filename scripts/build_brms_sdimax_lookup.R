# =============================================================================
# Build SDImax lookup tables from BRMS plot-specific values
# =============================================================================
# Inputs:
#   config/brms_SDImax_plot.csv     plot-keyed BRMS posterior mean/median
#                                    (METRIC units: trees per hectare)
#
# Outputs:
#   config/sdimax_brms_county_fortyp.csv  COUNTY x FORTYPCD aggregation
#   config/sdimax_brms_fortyp.csv         statewide FORTYPCD aggregation
#   config/sdimax_brms_plot.csv           plot-level merged with FORTYPCD
#                                          (PLT_CN keyed for direct lookup)
#
# Conversion: SDImax_english (trees/acre) = SDImax_metric (trees/ha) * 0.4046856
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse); library(data.table); library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

METRIC_TO_ENGLISH <- 0.4046856  # trees/ha -> trees/acre

# Read BRMS plot SDImax
brms <- fread(file.path(project_dir, "config", "brms_SDImax_plot.csv"))
cat(sprintf("BRMS SDImax records: %d plots across %d states\n",
            nrow(brms), uniqueN(brms$STATECD)))
brms[, sdimax_metric_mean   := SDImax.mean]
brms[, sdimax_metric_median := SDImax.median]
brms[, sdimax_english_mean   := sdimax_metric_mean   * METRIC_TO_ENGLISH]
brms[, sdimax_english_median := sdimax_metric_median * METRIC_TO_ENGLISH]

# Read FIA COND (most recent panel for each plot) to get FORTYPCD
# Use Maine + neighbor donor states so the lookup is regional
states <- c("ME","NH","VT","NY","MA","CT","RI","PA","WI","MN","MI",
            "GA","NC","SC","VA","OR","WA")
cond_list <- list()
for (s in states) {
  f <- file.path("~/fia_data", paste0(s, "_COND.csv"))
  if (file.exists(f)) {
    dt <- fread(f, select = c("PLT_CN","CONDID","STATECD","UNITCD","COUNTYCD",
                                "PLOT","INVYR","COND_STATUS_CD","FORTYPCD",
                                "OWNGRPCD","SITECLCD","CONDPROP_UNADJ"),
                colClasses = list(character = "PLT_CN"))
    cond_list[[s]] <- dt
  }
}
cond_all <- rbindlist(cond_list, fill = TRUE)
cat(sprintf("Loaded %d cond records across %d states\n",
            nrow(cond_all), uniqueN(cond_all$STATECD)))

# For each (STATECD, UNITCD, COUNTYCD, PLOT), pick the most recent COND record
# matching the BRMS key. Use the dominant condition (largest CONDPROP_UNADJ).
cond_recent <- cond_all[COND_STATUS_CD == 1][order(-INVYR, -CONDPROP_UNADJ),
                                              .SD[1],
                                              by = .(STATECD, UNITCD, COUNTYCD, PLOT)]
cat(sprintf("Most-recent forested cond per plot: %d\n", nrow(cond_recent)))

# Join BRMS to COND on (STATECD, UNITCD, COUNTYCD, PLOT)
joined <- merge(brms[, .(STATECD, UNITCD, COUNTYCD, PLOT,
                          sdimax_metric_mean, sdimax_metric_median,
                          sdimax_english_mean, sdimax_english_median)],
                cond_recent[, .(STATECD, UNITCD, COUNTYCD, PLOT, PLT_CN, CONDID,
                                 FORTYPCD, OWNGRPCD, SITECLCD)],
                by = c("STATECD","UNITCD","COUNTYCD","PLOT"),
                all = FALSE)
cat(sprintf("Joined BRMS x COND: %d plots\n", nrow(joined)))

# Save plot-level lookup
fwrite(joined, file.path(project_dir, "config", "sdimax_brms_plot.csv"))

# Summarize by COUNTY x FORTYPCD
county_fortyp <- joined[!is.na(FORTYPCD), .(
  n_plots             = .N,
  sdimax_metric_mean   = round(mean(sdimax_metric_mean,   na.rm = TRUE), 1),
  sdimax_metric_median = round(median(sdimax_metric_median, na.rm = TRUE), 1),
  sdimax_metric_p25    = round(quantile(sdimax_metric_mean, 0.25, na.rm = TRUE), 1),
  sdimax_metric_p75    = round(quantile(sdimax_metric_mean, 0.75, na.rm = TRUE), 1),
  sdimax_english_mean   = round(mean(sdimax_english_mean,   na.rm = TRUE), 1),
  sdimax_english_median = round(median(sdimax_english_median, na.rm = TRUE), 1)
), by = .(STATECD, COUNTYCD, FORTYPCD)][order(STATECD, COUNTYCD, FORTYPCD)]
fwrite(county_fortyp, file.path(project_dir, "config", "sdimax_brms_county_fortyp.csv"))
cat(sprintf("County x FORTYPCD: %d rows\n", nrow(county_fortyp)))

# Statewide FORTYPCD aggregation
state_fortyp <- joined[!is.na(FORTYPCD), .(
  n_plots             = .N,
  sdimax_metric_mean   = round(mean(sdimax_metric_mean,   na.rm = TRUE), 1),
  sdimax_metric_median = round(median(sdimax_metric_median, na.rm = TRUE), 1),
  sdimax_metric_p25    = round(quantile(sdimax_metric_mean, 0.25, na.rm = TRUE), 1),
  sdimax_metric_p75    = round(quantile(sdimax_metric_mean, 0.75, na.rm = TRUE), 1),
  sdimax_english_mean   = round(mean(sdimax_english_mean,   na.rm = TRUE), 1),
  sdimax_english_median = round(median(sdimax_english_median, na.rm = TRUE), 1)
), by = .(STATECD, FORTYPCD)][order(STATECD, FORTYPCD)]
fwrite(state_fortyp, file.path(project_dir, "config", "sdimax_brms_fortyp.csv"))
cat(sprintf("Statewide FORTYPCD: %d rows\n", nrow(state_fortyp)))

# Maine-specific summary
cat("\n=== Maine SDImax by FORTYPCD (top 15 by n_plots) ===\n")
me_smry <- state_fortyp[STATECD == 23][order(-n_plots)][1:15]
print(me_smry[, .(FORTYPCD, n_plots, sdimax_metric_mean, sdimax_english_mean)])
