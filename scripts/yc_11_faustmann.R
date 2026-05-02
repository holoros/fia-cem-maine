## yc_11_faustmann.R  (Yield-Curve Phase 2, step 7 — PERSEUS rotation demo)
##
## Per-stratum Faustmann rotation optimization with a time-averaged
## carbon constraint. Demonstrates what a downstream Woodstock LP would
## compute when handed our v4 yield-curve adapters: optimal rotation
## age R* maximizing soil expectation value (SEV) subject to
## time-averaged AGB ≥ carbon_floor.
##
## Faustmann SEV (single rotation, infinite series, regen cost = R0):
##   SEV(R) = [p × V(R) × e^(-rR) - R0] / [1 - e^(-rR)]
##
## Where V(R) is merchantable volume at rotation, p is stumpage price,
## r is discount rate, R0 is regeneration cost. We sweep R over
## [20, 150] and report:
##   - SEV-maximizing rotation R*_econ
##   - SEV-maximizing rotation under carbon floor R*_carbon (where
##     time-averaged AGB over the rotation must exceed C_floor)
##   - Carbon shadow price = (SEV_econ - SEV_carbon) per ton additional
##     time-averaged C
##
## Sensitivity sweep over three carbon floors:
##   30 ton/ac (low)   - barely binding for most strata
##   45 ton/ac (medium) - binds on lower-productivity cells
##   60 ton/ac (high)  - binds on most cells, lengthens rotation
##
## Notional Maine 2024 stumpage prices (per Maine Forest Service Stumpage
## Price Reports, blended species mix):
##   Sawlog softwood: $30/cuft (~$60/MBF)
##   Pulp:            $5/cuft   (~$10/cord softwood)
##   Hardwood sawlog: $25/cuft  (~$80/MBF)
##   Blended price for whole-stand merchantable volume: $12/cuft

args <- commandArgs(trailingOnly = TRUE)
yc_dir  <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "yield_curves")
fig_dir <- file.path(yc_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

v4_long <- read.csv(file.path(yc_dir, "maine_yield_curves_v4_long.csv"),
                    stringsAsFactors = FALSE)
v4_fits <- read.csv(file.path(yc_dir, "maine_yield_curves_v4_fits.csv"),
                    stringsAsFactors = FALSE)

# Economic parameters
PRICE_PER_CUFT  <- 12.0   # $/cuft, blended Maine stumpage 2024
REGEN_COST_AC   <- 200.0  # $/ac, planting + site prep amortized
DISCOUNT_RATE   <- 0.04   # 4%/yr real
CARBON_PRICE_C  <- 50.0   # $/ton C reference for shadow-price comparison
                          # converts AGB-ton via 0.45 fraction

ages <- seq(20, 150, by = 5)
rotations <- ages

chap <- function(age, a, b, c) a * (1 - exp(-b * age))^c

# ============================================================
# Compute SEV and time-averaged AGB for each rotation R, per cell
# ============================================================
sev_results <- list()
agb_fits  <- v4_fits[v4_fits$response == "agb_tonac", ]
vol_fits  <- v4_fits[v4_fits$response == "vol_cuftac", ]
keys <- unique(paste(agb_fits$cell_key, agb_fits$treatment, sep = "::"))

for (key in keys) {
  parts  <- strsplit(key, "::")[[1]]
  cell   <- parts[1]
  trt    <- parts[2]
  agb_p  <- agb_fits[agb_fits$cell_key == cell & agb_fits$treatment == trt, ]
  vol_p  <- vol_fits[vol_fits$cell_key == cell & vol_fits$treatment == trt, ]
  if (nrow(agb_p) != 1 || nrow(vol_p) != 1) next

  # Pre-compute trajectories at fine age grid for time-averaging
  fine_ages <- seq(1, 150, by = 1)
  agb_traj  <- chap(fine_ages, agb_p$a, agb_p$b, agb_p$c)
  vol_traj  <- chap(fine_ages, vol_p$a, vol_p$b, vol_p$c)

  for (R in rotations) {
    # Mean AGB over rotation
    mean_agb <- mean(agb_traj[1:R])
    # Volume at rotation
    V_R <- chap(R, vol_p$a, vol_p$b, vol_p$c)
    # SEV
    discount_factor <- exp(-DISCOUNT_RATE * R)
    SEV <- (PRICE_PER_CUFT * V_R * discount_factor - REGEN_COST_AC) /
           (1 - discount_factor)

    sev_results[[length(sev_results) + 1]] <- data.frame(
      cell_key = cell, ft_group = agb_p$ft_group,
      ecoregion = agb_p$ecoregion, owner = agb_p$owner,
      treatment = trt, R = R,
      mean_agb_tonac = round(mean_agb, 2),
      mean_C_tonac   = round(mean_agb * 0.45, 2),
      vol_cuftac     = round(V_R, 1),
      sev_per_ac     = round(SEV, 2),
      stringsAsFactors = FALSE)
  }
}

sev <- do.call(rbind, sev_results)
write.csv(sev, file.path(yc_dir, "faustmann_rotation_sweep.csv"),
          row.names = FALSE)
cat(sprintf("Wrote faustmann_rotation_sweep.csv (%d rows)\n", nrow(sev)))

# ============================================================
# Optimal rotation summary by carbon floor
# ============================================================
carbon_floors <- c(0, 30, 45, 60)  # ton/ac time-averaged AGB
opt_results  <- list()

for (key in unique(paste(sev$cell_key, sev$treatment, sep = "::"))) {
  parts <- strsplit(key, "::")[[1]]
  cell  <- parts[1]
  trt   <- parts[2]
  d     <- sev[sev$cell_key == cell & sev$treatment == trt, ]
  if (nrow(d) == 0) next

  for (cf in carbon_floors) {
    feasible <- d$mean_agb_tonac >= cf
    if (!any(feasible)) {
      # Even longest rotation can't meet floor; report NA
      opt_results[[length(opt_results) + 1]] <- data.frame(
        cell_key = cell, ft_group = d$ft_group[1],
        ecoregion = d$ecoregion[1], owner = d$owner[1],
        treatment = trt, carbon_floor = cf,
        R_opt = NA_real_, sev_opt = NA_real_,
        mean_agb_at_R = NA_real_, vol_at_R = NA_real_,
        feasible = FALSE, stringsAsFactors = FALSE)
      next
    }
    df <- d[feasible, ]
    best <- df[which.max(df$sev_per_ac), ]
    opt_results[[length(opt_results) + 1]] <- data.frame(
      cell_key = cell, ft_group = best$ft_group,
      ecoregion = best$ecoregion, owner = best$owner,
      treatment = trt, carbon_floor = cf,
      R_opt = best$R, sev_opt = best$sev_per_ac,
      mean_agb_at_R = best$mean_agb_tonac,
      vol_at_R = best$vol_cuftac,
      feasible = TRUE, stringsAsFactors = FALSE)
  }
}

opt <- do.call(rbind, opt_results)
write.csv(opt, file.path(yc_dir, "faustmann_optimal_rotation.csv"),
          row.names = FALSE)
cat(sprintf("Wrote faustmann_optimal_rotation.csv (%d rows)\n", nrow(opt)))

# ============================================================
# Carbon shadow price = (SEV_unconstrained - SEV_constrained) / delta_C
# ============================================================
shadow <- list()
for (key in unique(paste(opt$cell_key, opt$treatment, sep = "::"))) {
  parts <- strsplit(key, "::")[[1]]
  cell  <- parts[1]
  trt   <- parts[2]
  d <- opt[opt$cell_key == cell & opt$treatment == trt, ]
  if (nrow(d) < 2) next
  base <- d[d$carbon_floor == 0, ]
  if (nrow(base) != 1 || is.na(base$sev_opt)) next
  for (cf in carbon_floors[-1]) {
    cur <- d[d$carbon_floor == cf, ]
    if (nrow(cur) != 1 || is.na(cur$sev_opt)) next
    delta_C <- cur$mean_agb_at_R * 0.45 - base$mean_agb_at_R * 0.45
    delta_SEV <- base$sev_opt - cur$sev_opt
    shadow_price <- if (abs(delta_C) > 0.01) delta_SEV / delta_C else NA_real_
    shadow[[length(shadow) + 1]] <- data.frame(
      cell_key = cell, ft_group = cur$ft_group,
      ecoregion = cur$ecoregion, owner = cur$owner,
      treatment = trt, carbon_floor = cf,
      delta_C_tonac = round(delta_C, 2),
      delta_SEV_per_ac = round(delta_SEV, 2),
      shadow_price_per_ton_C = round(shadow_price, 2),
      stringsAsFactors = FALSE)
  }
}
shadow_df <- do.call(rbind, shadow)
write.csv(shadow_df, file.path(yc_dir, "faustmann_carbon_shadow_price.csv"),
          row.names = FALSE)
cat(sprintf("Wrote faustmann_carbon_shadow_price.csv (%d rows)\n",
            nrow(shadow_df)))

# Summary table
cat("\n=== Optimal rotation by carbon floor (untreated only) ===\n")
unt <- opt[opt$treatment == "untreated" & opt$feasible, ]
agg <- aggregate(R_opt ~ carbon_floor, data = unt, FUN = function(x)
                  c(mean = round(mean(x), 1),
                    sd = round(sd(x), 1),
                    min = min(x), max = max(x)))
print(agg)

cat("\n=== Mean shadow price by carbon floor (untreated, $/ton C) ===\n")
shu <- shadow_df[shadow_df$treatment == "untreated", ]
print(aggregate(shadow_price_per_ton_C ~ carbon_floor, data = shu,
                 FUN = function(x) round(mean(x, na.rm = TRUE), 2)))

# ============================================================
# Figure: optimal rotation vs carbon floor by forest type
# ============================================================
png(file.path(fig_dir, "fig_faustmann_rotation_carbon.png"),
    width = 10, height = 6, units = "in", res = 150)
op <- par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))

# Panel 1: rotation vs floor
unt <- opt[opt$treatment == "untreated" & opt$feasible, ]
fts <- sort(unique(unt$ft_group))
cols <- rainbow(length(fts), s = 0.7, v = 0.7)
plot(NA, xlim = c(-2, 65), ylim = c(20, 155),
     xlab = "Carbon floor (ton/ac time-avg AGB)",
     ylab = "Optimal rotation R* (yr)",
     main = "Faustmann R* vs carbon constraint")
for (i in seq_along(fts)) {
  ft <- fts[i]
  agg_ft <- aggregate(R_opt ~ carbon_floor, data = unt[unt$ft_group == ft, ],
                       FUN = mean)
  lines(agg_ft$carbon_floor, agg_ft$R_opt, col = cols[i], lwd = 2)
  points(agg_ft$carbon_floor, agg_ft$R_opt, col = cols[i], pch = 19, cex = 1.1)
}
legend("topleft", legend = fts, col = cols, lty = 1, lwd = 2, cex = 0.75,
        bty = "n")

# Panel 2: shadow price by floor
shu <- shadow_df[shadow_df$treatment == "untreated" &
                  !is.na(shadow_df$shadow_price_per_ton_C) &
                  shadow_df$shadow_price_per_ton_C > 0, ]
boxplot(shadow_price_per_ton_C ~ carbon_floor, data = shu,
         xlab = "Carbon floor (ton/ac)",
         ylab = "Shadow price ($/ton C)",
         main = "Marginal cost of carbon retention",
         col = c("#90caf9", "#42a5f5", "#1976d2"),
         outline = FALSE)
abline(h = CARBON_PRICE_C, lty = 3, col = "red")
mtext(sprintf("Reference C price = $%.0f/ton C", CARBON_PRICE_C),
       side = 3, line = -1, col = "red", cex = 0.7)

par(op)
dev.off()
cat(sprintf("\nWrote figure: fig_faustmann_rotation_carbon.png\n"))
