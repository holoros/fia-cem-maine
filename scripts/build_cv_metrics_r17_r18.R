## build_cv_metrics_r17_r18.R
## Compute cross-validation residuals for r17 and r18 against subject-matched
## observed FIA at the years where both are available (2004, 2009, 2014, 2019, 2024).
## Outputs cv_metrics_r17_r18.csv with RMSE, bias, and per-year residuals.

base <- "/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results"

obs <- read.csv(file.path(base, "subject_matched_cv",
                          "subject_matched_observed.csv"),
                stringsAsFactors = FALSE)

# Average to 5-yr cycle midpoints to align with projection years
obs$cycle <- floor((obs$year - 2002) / 5)
obs_5yr <- aggregate(subject_only_agc_mmt ~ cycle,
                      data = obs[obs$year >= 2004 & obs$year <= 2024, ],
                      FUN = mean)
obs_5yr$year <- 2004 + obs_5yr$cycle * 5
obs_5yr <- obs_5yr[obs_5yr$year %in% c(2004, 2009, 2014, 2019, 2024), ]
names(obs_5yr)[2] <- "obs_agc_mmt"

cat("Observed AGC by year (subject-matched):\n")
print(obs_5yr, row.names = FALSE)

# Load r17 and r18 BAU trajectories at the 4 RCP × econ × tag combos
load_proj <- function(rcp, econ, tag) {
  f <- file.path(base, "state_summary_progression",
                 sprintf("state_rcp%s_hadgem2_wear%s_%s_ci.csv",
                         rcp, if (econ) "_econ" else "", tag))
  if (!file.exists(f)) return(NULL)
  d <- read.csv(f, stringsAsFactors = FALSE)
  d <- d[d$scenario == "BAU" & d$year %in% c(2004, 2009, 2014, 2019, 2024), ]
  d[, c("year", "mmt_agc_mean")]
}

cv_rows <- list()
for (rcp in c("45", "85")) {
  for (econ in c(FALSE, TRUE)) {
    for (tag in c("r17", "r18")) {
      d <- load_proj(rcp, econ, tag)
      if (is.null(d)) next
      m <- merge(d, obs_5yr[, c("year", "obs_agc_mmt")], by = "year")
      m$residual <- m$mmt_agc_mean - m$obs_agc_mmt
      cv_rows[[paste(rcp, econ, tag, sep = "_")]] <- data.frame(
        rcp = rcp, econ = econ, tag = tag,
        year = m$year,
        proj = round(m$mmt_agc_mean, 1),
        obs  = round(m$obs_agc_mmt,  1),
        residual = round(m$residual, 1)
      )
    }
  }
}
all_cv <- do.call(rbind, cv_rows)

# Summary stats per (rcp, econ, tag)
summ <- aggregate(residual ~ rcp + econ + tag, data = all_cv,
                  FUN = function(r) c(rmse = round(sqrt(mean(r^2)), 1),
                                      bias = round(mean(r), 1),
                                      mae  = round(mean(abs(r)), 1)))
summ <- do.call(data.frame, summ)
names(summ) <- c("rcp", "econ", "tag", "rmse", "bias", "mae")

write.csv(all_cv, file.path(base, "subject_matched_cv",
                             "cv_residuals_r17_r18.csv"), row.names = FALSE)
write.csv(summ, file.path(base, "subject_matched_cv",
                           "cv_metrics_r17_r18.csv"), row.names = FALSE)

cat("\n=== Per-(rcp,econ,tag) CV stats vs subject-matched obs ===\n")
print(summ, row.names = FALSE)

cat("\n=== Per-year residuals (RCP 4.5 wear) ===\n")
print(all_cv[all_cv$rcp == "45" & all_cv$econ == FALSE,
             c("tag", "year", "proj", "obs", "residual")],
      row.names = FALSE)
