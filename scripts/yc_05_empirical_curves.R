## yc_05_empirical_curves.R  (Yield-Curve Phase 2, alternative path)
##
## Build empirical Chapman-Richards yield curves for each
## (forest type × ecoregion × owner) cell using FIA's existing
## chronosequence — i.e., plot ages span the curve, so we fit a smooth
## across age within each cell.
##
## This produces yield curves directly from observed Maine FIA data
## without needing to run FVS-NE/ACD. They are complementary to (and
## faster than) FVS-derived curves, and they are anchored in real
## Maine growth dynamics.
##
## Inputs : FIA TREE, COND, PLOT
##          config/yc_strata_72cell.csv
##          config/yc_plot_membership.csv
## Outputs: yield_curves/maine_yield_curves_empirical_long.csv
##          yield_curves/maine_yield_curves_empirical_fits.csv
##          figures/fig_yield_curves_<cell>.png
##
## Response variables fitted: AGB (tons/ac), basal area (ft²/ac),
##   live tree carbon (lb/ac), TPA, volume.

args <- commandArgs(trailingOnly = TRUE)
fia_dir    <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "fia_data")
config_dir <- if (length(args) >= 2) args[2] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
out_dir    <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "yield_curves")
fig_dir    <- file.path(out_dir, "figures")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat(sprintf("FIA dir   : %s\n", fia_dir))
cat(sprintf("Config dir: %s\n", config_dir))
cat(sprintf("Output dir: %s\n", out_dir))

## ---- Load lookups ----------------------------------------------------
strata <- read.csv(file.path(config_dir, "yc_strata_72cell.csv"),
                   stringsAsFactors = FALSE)
strata <- strata[strata$n_plots >= 30, ]

membership <- read.csv(file.path(config_dir, "yc_plot_membership.csv"),
                       stringsAsFactors = FALSE)

## Latest measurement per plot (to pair with TREE table)
m <- membership[order(membership$PLT_CN, -membership$INVYR), ]
m <- m[!duplicated(m$PLT_CN), ]

## ---- Load FIA TREE ---------------------------------------------------
cat("Loading FIA TREE...\n")
tree <- read.csv(file.path(fia_dir, "ME_TREE.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
keep <- intersect(c("CN","PLT_CN","INVYR","STATUSCD","SPCD","DIA","HT",
                    "TPA_UNADJ","DRYBIO_AG","DRYBIO_BG","CARBON_AG",
                    "VOLCFNET","TREECLCD","BHAGE","TOTAGE"),
                  names(tree))
tree <- tree[, keep]
num_cols <- c("DIA","HT","TPA_UNADJ","DRYBIO_AG","DRYBIO_BG","CARBON_AG",
              "VOLCFNET","BHAGE","TOTAGE")
for (col in intersect(num_cols, names(tree))) {
  tree[[col]] <- suppressWarnings(as.numeric(tree[[col]]))
}
tree$STATUSCD <- suppressWarnings(as.integer(tree$STATUSCD))
tree <- tree[!is.na(tree$STATUSCD) & tree$STATUSCD == 1, ]
cat(sprintf("Live trees: %d\n", nrow(tree)))

## ---- Plot-level aggregates -------------------------------------------
cat("Aggregating to plot level...\n")

# Stand age: prefer COND.STDAGE (a per-condition stand-level estimate),
# fall back to median TOTAGE/BHAGE across measured trees.
cat("Loading FIA COND for STDAGE...\n")
cond <- read.csv(file.path(fia_dir, "ME_COND.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
cond_keep <- intersect(c("PLT_CN", "CONDID", "STDAGE", "CONDPROP_UNADJ"),
                        names(cond))
cond <- cond[, cond_keep]
cond$STDAGE         <- suppressWarnings(as.numeric(cond$STDAGE))
cond$CONDPROP_UNADJ <- suppressWarnings(as.numeric(cond$CONDPROP_UNADJ))
# Take the dominant condition (max CONDPROP) per plot
cond <- cond[order(cond$PLT_CN, -cond$CONDPROP_UNADJ), ]
cond_dom <- cond[!duplicated(cond$PLT_CN), ]
plot_age_cond <- cond_dom[!is.na(cond_dom$STDAGE) & cond_dom$STDAGE > 0,
                          c("PLT_CN", "STDAGE")]
names(plot_age_cond)[2] <- "stand_age"
cat(sprintf("Plots with COND.STDAGE: %d\n", nrow(plot_age_cond)))

# Backup from tree-level age (median TOTAGE or BHAGE+5)
tree_with_age <- tree[!is.na(tree$TOTAGE) | !is.na(tree$BHAGE), ]
if (nrow(tree_with_age) > 0) {
  tree_with_age$age_use <- ifelse(!is.na(tree_with_age$TOTAGE),
                                  tree_with_age$TOTAGE,
                                  tree_with_age$BHAGE + 5)
  plot_age_tree <- aggregate(age_use ~ PLT_CN, data = tree_with_age,
                             FUN = function(x) median(x, na.rm = TRUE))
  names(plot_age_tree)[2] <- "stand_age_tree"
} else {
  plot_age_tree <- data.frame(PLT_CN = character(0), stand_age_tree = numeric(0))
}

# Merge: prefer COND age, fall back to tree age
plot_age <- merge(plot_age_cond, plot_age_tree, by = "PLT_CN", all = TRUE)
plot_age$stand_age <- ifelse(!is.na(plot_age$stand_age),
                              plot_age$stand_age,
                              plot_age$stand_age_tree)
plot_age <- plot_age[!is.na(plot_age$stand_age) & plot_age$stand_age > 0,
                     c("PLT_CN", "stand_age")]
cat(sprintf("Total plots with stand age: %d\n", nrow(plot_age)))

# Per-plot biomass and volume (lb/acre = TPA × DRYBIO scaled)
agg_plot <- function(grp_var, val_var, fun = sum) {
  dat <- tree[, c(grp_var, val_var, "TPA_UNADJ")]
  dat[, val_var] <- dat[, val_var] * dat$TPA_UNADJ
  out <- aggregate(dat[, val_var], by = list(dat[, grp_var]), FUN = fun, na.rm = TRUE)
  names(out) <- c(grp_var, val_var)
  out
}

# AGB tons/ac = sum(DRYBIO_AG × TPA) / 2000
plot_agb <- agg_plot("PLT_CN", "DRYBIO_AG")
plot_agb$DRYBIO_AG <- plot_agb$DRYBIO_AG / 2000
names(plot_agb)[2] <- "agb_tonac"

# Live C lb/ac
if ("CARBON_AG" %in% names(tree)) {
  plot_c <- agg_plot("PLT_CN", "CARBON_AG")
  names(plot_c)[2] <- "carbon_lbac"
} else {
  plot_c <- data.frame(PLT_CN = unique(tree$PLT_CN), carbon_lbac = NA_real_)
}

# BA ft2/ac = sum(0.005454 × DIA² × TPA)
tree$ba_ind <- 0.005454154 * tree$DIA^2 * tree$TPA_UNADJ
plot_ba <- aggregate(ba_ind ~ PLT_CN, data = tree, FUN = sum, na.rm = TRUE)
names(plot_ba)[2] <- "ba_ft2ac"

# TPA total
plot_tpa <- aggregate(TPA_UNADJ ~ PLT_CN, data = tree, FUN = sum, na.rm = TRUE)
names(plot_tpa)[2] <- "tpa_total"

# Volume (cuft/ac)
if ("VOLCFNET" %in% names(tree)) {
  plot_vol <- agg_plot("PLT_CN", "VOLCFNET")
  names(plot_vol)[2] <- "vol_cuftac"
} else {
  plot_vol <- data.frame(PLT_CN = unique(tree$PLT_CN), vol_cuftac = NA_real_)
}

## Merge everything
plot_dat <- Reduce(function(a, b) merge(a, b, by = "PLT_CN", all = TRUE),
                   list(plot_age, plot_agb, plot_c, plot_ba, plot_tpa, plot_vol))
cat(sprintf("Plot-level aggregates: %d rows\n", nrow(plot_dat)))

## Join with cell membership
m$cell_key  <- m$cell_key
plot_dat <- merge(plot_dat, m[, c("PLT_CN", "cell_key", "ft_group",
                                   "ecoregion", "owner4")],
                  by = "PLT_CN")
plot_dat <- plot_dat[!is.na(plot_dat$stand_age) & plot_dat$stand_age > 0, ]
cat(sprintf("Plots with stand age and cell key: %d\n", nrow(plot_dat)))

## ---- Chapman-Richards fits ------------------------------------------
chap_richards <- function(age, a, b, c) a * (1 - exp(-b * age))^c

fit_one <- function(age, y) {
  ok <- !is.na(age) & !is.na(y) & y > 0
  if (sum(ok) < 6) return(NULL)
  start_a <- max(y[ok], na.rm = TRUE) * 1.2
  start <- list(a = start_a, b = 0.04, c = 1.5)
  tryCatch(
    nls(y ~ chap_richards(age, a, b, c),
        data = data.frame(age = age[ok], y = y[ok]),
        start = start,
        control = list(maxiter = 200, warnOnly = TRUE)),
    error = function(e) NULL)
}

predict_curve <- function(model, age_grid) {
  if (is.null(model)) return(rep(NA, length(age_grid)))
  predict(model, newdata = data.frame(age = age_grid))
}

response_vars <- list(
  agb_tonac   = "AGB (tons / ac)",
  carbon_lbac = "Live tree C (lb / ac)",
  ba_ft2ac    = "Basal area (ft² / ac)",
  tpa_total   = "Trees per acre",
  vol_cuftac  = "Volume (ft³ / ac)"
)

age_grid <- seq(5, 150, by = 5)
all_curves <- list()
all_fits   <- list()

for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  sub <- plot_dat[plot_dat$cell_key == s$cell_key, ]
  if (nrow(sub) < 10) next
  for (rv in names(response_vars)) {
    if (!(rv %in% names(sub))) next
    m_fit <- fit_one(sub$stand_age, sub[[rv]])
    if (is.null(m_fit)) next
    co <- coef(m_fit)
    pred <- predict_curve(m_fit, age_grid)
    all_curves[[length(all_curves) + 1]] <- data.frame(
      cell_key = s$cell_key, ft_group = s$ft_group,
      ecoregion = s$ecoregion, owner = s$owner4,
      response = rv, age = age_grid, predicted = round(pred, 3))
    rmse <- sqrt(mean(residuals(m_fit)^2, na.rm = TRUE))
    all_fits[[length(all_fits) + 1]] <- data.frame(
      cell_key = s$cell_key, ft_group = s$ft_group,
      ecoregion = s$ecoregion, owner = s$owner4,
      response = rv,
      a = round(unname(co["a"]), 3),
      b = round(unname(co["b"]), 5),
      c = round(unname(co["c"]), 3),
      rmse = round(rmse, 3),
      n_plots = nrow(sub),
      asymptote = round(unname(co["a"]), 3))
  }
  cat(sprintf("  cell %2d/%d: %s (n=%d)\n", i, nrow(strata),
              s$cell_key, nrow(sub)))
}

curves <- do.call(rbind, all_curves)
fits   <- do.call(rbind, all_fits)
write.csv(curves, file.path(out_dir, "maine_yield_curves_empirical_long.csv"),
          row.names = FALSE)
write.csv(fits, file.path(out_dir, "maine_yield_curves_empirical_fits.csv"),
          row.names = FALSE)

cat(sprintf("\nWrote %d curve points across %d (cell × response) fits\n",
            nrow(curves), nrow(fits)))

## ---- Quick figure ----------------------------------------------------
cat("Building summary figure...\n")
top_cells <- head(unique(strata$cell_key), 6)
png(file.path(fig_dir, "fig_yield_curves_top6.png"),
    width = 1200, height = 800, res = 100)
op <- par(mfrow = c(2, 3), mar = c(4, 4, 2, 1))
for (cell in top_cells) {
  sub_plt <- plot_dat[plot_dat$cell_key == cell &
                       !is.na(plot_dat$agb_tonac), ]
  fit_row <- fits[fits$cell_key == cell & fits$response == "agb_tonac", ]
  plot(sub_plt$stand_age, sub_plt$agb_tonac,
       pch = 16, col = rgb(0.2, 0.5, 0.2, 0.4),
       xlab = "Stand age (yr)",
       ylab = "AGB (tons / ac)",
       main = sprintf("%s\n(n=%d)", cell, nrow(sub_plt)),
       xlim = c(0, 150))
  if (nrow(fit_row) == 1) {
    lines(age_grid, chap_richards(age_grid,
                                   fit_row$a, fit_row$b, fit_row$c),
          col = "darkred", lwd = 2)
    legend("topleft",
           legend = sprintf("a=%.1f  b=%.3f  c=%.2f",
                            fit_row$a, fit_row$b, fit_row$c),
           bty = "n", cex = 0.85)
  }
}
par(op)
dev.off()
cat(sprintf("Wrote %s\n", file.path(fig_dir, "fig_yield_curves_top6.png")))
cat("\nDone.\n")
