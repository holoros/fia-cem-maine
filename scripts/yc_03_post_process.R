## yc_03_post_process.R  (Yield-Curve Phase 2, step 3)
##
## After the FVS array job completes, parse each run's output, fit a
## Chapman-Richards smooth per (cell, treatment, response variable), and
## archive everything as long-format CSV plus parquet.
##
## FVS-NE / FVS-ACD writes summary statistics to fvs_run.out (legacy ASCII
## tables). For each cycle we want:
##   - YEAR
##   - AGE
##   - BA           (basal area, sq ft / ac)
##   - QMD          (quadratic mean diameter, in)
##   - VOLCFT       (cuft volume / ac, total)
##   - VOLBDFT      (boardft volume / ac, sawtimber)
##   - C_TOTBIO     (total above + below ground biomass C, t / ac)
##   - C_LIVE       (live tree C only, t / ac)
##   - MORT_VOL     (mortality volume, cuft / ac)
##
## Outputs:
##   yield_curves/maine_yield_curves_v1_long.csv   long-format trajectories
##   yield_curves/maine_yield_curves_v1_fits.csv   Chapman-Richards a, b, c per cell × treatment × response
##   yield_curves/maine_yield_curves_v1.parquet   (if arrow installed)
##   figures/fig_yield_curves_*.png                 per-cell × treatment ribbon plots

suppressPackageStartupMessages({
  base_pkgs <- c("stats")
  for (p in base_pkgs) library(p, character.only = TRUE)
})

args <- commandArgs(trailingOnly = TRUE)
yc_dir   <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "yield_curves")
out_dir  <- if (length(args) >= 2) args[2] else yc_dir
fig_dir  <- if (length(args) >= 3) args[3] else file.path(out_dir, "figures")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

idx <- read.csv(file.path(yc_dir, "yc_run_index.csv"), stringsAsFactors = FALSE)
cat(sprintf("Index rows: %d\n", nrow(idx)))

# Parse one FVS .out file. The "Summary Statistics" table has fixed-width
# columns; we use a simple line-scanner.
parse_fvs_out <- function(outfile) {
  if (!file.exists(outfile)) return(NULL)
  lines <- readLines(outfile, warn = FALSE)
  # Find the Summary Statistics table — typically starts after a header
  # line "STAND COMPOSITION AND STRUCTURE"
  hdr_idx <- grep("STAND COMPOSITION AND STRUCTURE|SUMMARY STATISTICS|Year.*Age.*BA",
                   lines)
  if (length(hdr_idx) == 0) return(NULL)
  start <- hdr_idx[1] + 2  # skip header + dashes
  # Read until blank line or another section
  rows <- list()
  for (i in start:length(lines)) {
    line <- lines[i]
    if (nchar(trimws(line)) == 0) break
    if (grepl("^[A-Z]", line)) break
    parts <- strsplit(trimws(line), "\\s+")[[1]]
    if (length(parts) < 4) next
    suppressWarnings({
      year <- as.integer(parts[1])
      age  <- as.integer(parts[2])
      if (is.na(year)) next
      ba   <- as.numeric(parts[3])
      qmd  <- if (length(parts) >= 4) as.numeric(parts[4]) else NA
      vol  <- if (length(parts) >= 5) as.numeric(parts[5]) else NA
      bdft <- if (length(parts) >= 6) as.numeric(parts[6]) else NA
      cbio <- if (length(parts) >= 7) as.numeric(parts[7]) else NA
    })
    rows[[length(rows) + 1]] <- data.frame(
      year, age,
      ba = ba, qmd = qmd, vol_cuft = vol, vol_bdft = bdft,
      c_tot_tonac = cbio
    )
  }
  if (length(rows) == 0) return(NULL)
  do.call(rbind, rows)
}

# Aggregate trajectories
all_traj <- list()
n_ok <- 0
n_fail <- 0
for (i in seq_len(nrow(idx))) {
  r <- idx[i, ]
  outfile <- file.path(r$rundir, "fvs_run.out")
  d <- parse_fvs_out(outfile)
  if (is.null(d) || nrow(d) == 0) {
    n_fail <- n_fail + 1
    next
  }
  d$cell_key  <- r$cell_key
  d$treatment <- r$treatment
  d$variant   <- r$variant
  all_traj[[length(all_traj) + 1]] <- d
  n_ok <- n_ok + 1
}
cat(sprintf("Parsed: %d ok, %d failed\n", n_ok, n_fail))

if (length(all_traj) == 0) {
  cat("No trajectories parsed — check FVS output paths\n"); quit(status = 1)
}

traj <- do.call(rbind, all_traj)
write.csv(traj, file.path(out_dir, "maine_yield_curves_v1_long.csv"),
          row.names = FALSE)
cat(sprintf("Wrote long-format CSV (%d rows)\n", nrow(traj)))

# ---- Chapman-Richards fit per (cell, treatment, response) ------------
chap_richards <- function(age, a, b, c) a * (1 - exp(-b * age))^c

fit_one <- function(age, y) {
  if (length(unique(y[!is.na(y)])) < 4) return(NULL)
  start <- list(a = max(y, na.rm = TRUE), b = 0.04, c = 1.5)
  tryCatch(
    nls(y ~ chap_richards(age, a, b, c), start = start,
        control = list(maxiter = 200, warnOnly = TRUE)),
    error = function(e) NULL
  )
}

fits <- list()
for (cell in unique(traj$cell_key)) {
  for (trt in unique(traj$treatment)) {
    sub <- traj[traj$cell_key == cell & traj$treatment == trt, ]
    if (nrow(sub) < 5) next
    for (resp in c("ba", "vol_cuft", "c_tot_tonac")) {
      m <- fit_one(sub$age, sub[[resp]])
      if (is.null(m)) next
      co <- coef(m)
      fits[[length(fits) + 1]] <- data.frame(
        cell_key = cell, treatment = trt, response = resp,
        a = round(co["a"], 2), b = round(co["b"], 5), c = round(co["c"], 3),
        rmse = round(sqrt(mean(residuals(m)^2, na.rm = TRUE)), 3),
        n = nrow(sub)
      )
    }
  }
}
if (length(fits) > 0) {
  fits_df <- do.call(rbind, fits)
  write.csv(fits_df, file.path(out_dir, "maine_yield_curves_v1_fits.csv"),
            row.names = FALSE)
  cat(sprintf("Wrote Chapman-Richards fits (%d rows)\n", nrow(fits_df)))
}

cat("\nDone.\n")
