## yc_06_empirical_curves_v2.R  (Yield-Curve Phase 2, v2)
##
## Improvements over yc_05:
##   1. Constrained Chapman-Richards fits via the `port` algorithm with
##      lower/upper bounds on b and c. Prevents the runaway fits that v1
##      produced for 6 cells (e.g., White/Red pine ME_NCZ NIPF with c=2065).
##   2. 200x bootstrap on the plot index per cell, refit each draw, and
##      take the 5th / 50th / 95th percentile of the predicted curve at
##      each age point.
##   3. Long-format output with `mean / lo95 / median / hi95` columns.
##
## Inputs:  ~/fia_data/ME_TREE.csv, ~/fia_data/ME_COND.csv,
##          config/yc_strata_72cell.csv, config/yc_plot_membership.csv
## Outputs: maine_yield_curves_v2_long.csv  (with quantile bands)
##          maine_yield_curves_v2_fits.csv  (point fit + bootstrap stats)
##          fig_yield_curves_v2_top9.png    (overlaid mean + ribbon)

args <- commandArgs(trailingOnly = TRUE)
fia_dir    <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "fia_data")
config_dir <- if (length(args) >= 2) args[2] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
out_dir    <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "yield_curves")
N_BOOT     <- if (length(args) >= 4) as.integer(args[4]) else 200L
fig_dir    <- file.path(out_dir, "figures")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20260502)

cat(sprintf("FIA dir   : %s\n", fia_dir))
cat(sprintf("Config dir: %s\n", config_dir))
cat(sprintf("Output dir: %s\n", out_dir))
cat(sprintf("Bootstrap : %d draws per cell\n", N_BOOT))

## ---- Load data (same as v1) -----------------------------------------
strata <- read.csv(file.path(config_dir, "yc_strata_72cell.csv"),
                   stringsAsFactors = FALSE)
strata <- strata[strata$n_plots >= 30, ]
membership <- read.csv(file.path(config_dir, "yc_plot_membership.csv"),
                       stringsAsFactors = FALSE)
m <- membership[order(membership$PLT_CN, -membership$INVYR), ]
m <- m[!duplicated(m$PLT_CN), ]

cat("Loading FIA TREE...\n")
tree <- read.csv(file.path(fia_dir, "ME_TREE.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
keep <- intersect(c("PLT_CN", "STATUSCD", "DIA", "TPA_UNADJ",
                    "DRYBIO_AG", "CARBON_AG", "VOLCFNET", "BHAGE", "TOTAGE"),
                  names(tree))
tree <- tree[, keep]
for (col in c("DIA", "TPA_UNADJ", "DRYBIO_AG", "CARBON_AG",
              "VOLCFNET", "BHAGE", "TOTAGE")) {
  if (col %in% names(tree))
    tree[[col]] <- suppressWarnings(as.numeric(tree[[col]]))
}
tree$STATUSCD <- suppressWarnings(as.integer(tree$STATUSCD))
tree <- tree[!is.na(tree$STATUSCD) & tree$STATUSCD == 1, ]
cat(sprintf("Live trees: %d\n", nrow(tree)))

cat("Loading FIA COND for STDAGE...\n")
cond <- read.csv(file.path(fia_dir, "ME_COND.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
cond <- cond[, intersect(c("PLT_CN", "CONDID", "STDAGE", "CONDPROP_UNADJ"),
                          names(cond))]
cond$STDAGE         <- suppressWarnings(as.numeric(cond$STDAGE))
cond$CONDPROP_UNADJ <- suppressWarnings(as.numeric(cond$CONDPROP_UNADJ))
cond <- cond[order(cond$PLT_CN, -cond$CONDPROP_UNADJ), ]
cond_dom <- cond[!duplicated(cond$PLT_CN), ]
plot_age <- cond_dom[!is.na(cond_dom$STDAGE) & cond_dom$STDAGE > 0,
                     c("PLT_CN", "STDAGE")]
names(plot_age)[2] <- "stand_age"
cat(sprintf("Plots with stand age: %d\n", nrow(plot_age)))

## Per-plot aggregates
agb <- aggregate(I(DRYBIO_AG * TPA_UNADJ) ~ PLT_CN, tree, sum, na.rm = TRUE)
names(agb)[2] <- "agb_tonac"; agb$agb_tonac <- agb$agb_tonac / 2000
ba <- aggregate(I(0.005454154 * DIA^2 * TPA_UNADJ) ~ PLT_CN, tree, sum,
                na.rm = TRUE)
names(ba)[2] <- "ba_ft2ac"
tpa <- aggregate(TPA_UNADJ ~ PLT_CN, tree, sum, na.rm = TRUE)
names(tpa)[2] <- "tpa_total"
if ("CARBON_AG" %in% names(tree)) {
  c_ag <- aggregate(I(CARBON_AG * TPA_UNADJ) ~ PLT_CN, tree, sum, na.rm = TRUE)
  names(c_ag)[2] <- "carbon_lbac"
} else c_ag <- data.frame(PLT_CN = character(0), carbon_lbac = numeric(0))
if ("VOLCFNET" %in% names(tree)) {
  vol <- aggregate(I(VOLCFNET * TPA_UNADJ) ~ PLT_CN, tree, sum, na.rm = TRUE)
  names(vol)[2] <- "vol_cuftac"
} else vol <- data.frame(PLT_CN = character(0), vol_cuftac = numeric(0))

plot_dat <- Reduce(function(a, b) merge(a, b, by = "PLT_CN", all = TRUE),
                   list(plot_age, agb, ba, tpa, c_ag, vol))
plot_dat <- merge(plot_dat,
                  m[, c("PLT_CN", "cell_key", "ft_group",
                        "ecoregion", "owner4")],
                  by = "PLT_CN")
plot_dat <- plot_dat[!is.na(plot_dat$stand_age) & plot_dat$stand_age > 0, ]
cat(sprintf("Plots with age + cell: %d\n", nrow(plot_dat)))

## ---- Constrained Chapman-Richards fit --------------------------------
chap_richards <- function(age, a, b, c) a * (1 - exp(-b * age))^c

fit_constrained <- function(age, y) {
  ok <- !is.na(age) & !is.na(y) & y > 0
  if (sum(ok) < 6) return(NULL)
  start_a <- max(y[ok], na.rm = TRUE) * 1.2
  out <- tryCatch({
    nls(y ~ chap_richards(age, a, b, c),
        data = data.frame(age = age[ok], y = y[ok]),
        start = list(a = start_a, b = 0.04, c = 1.5),
        algorithm = "port",
        lower = c(a = 1, b = 0.005, c = 0.5),
        upper = c(a = max(y[ok], na.rm = TRUE) * 3, b = 0.20, c = 5.0),
        control = list(maxiter = 200, warnOnly = TRUE))
  }, error = function(e) NULL)
  out
}

## ---- Bootstrap predict ----------------------------------------------
bootstrap_curves <- function(age, y, age_grid, n_boot = N_BOOT) {
  ok <- !is.na(age) & !is.na(y) & y > 0
  age <- age[ok]; y <- y[ok]
  n   <- length(age)
  preds <- matrix(NA_real_, nrow = n_boot, ncol = length(age_grid))
  for (b in seq_len(n_boot)) {
    idx <- sample.int(n, n, replace = TRUE)
    m_b <- fit_constrained(age[idx], y[idx])
    if (is.null(m_b)) next
    preds[b, ] <- predict(m_b, newdata = data.frame(age = age_grid))
  }
  list(
    lo95   = apply(preds, 2, quantile, 0.05, na.rm = TRUE),
    median = apply(preds, 2, quantile, 0.50, na.rm = TRUE),
    hi95   = apply(preds, 2, quantile, 0.95, na.rm = TRUE),
    n_succ = sum(complete.cases(preds[, 1]))
  )
}

response_vars <- c("agb_tonac", "ba_ft2ac", "carbon_lbac",
                   "tpa_total", "vol_cuftac")
age_grid <- seq(5, 150, by = 5)

all_curves <- list()
all_fits   <- list()

for (i in seq_len(nrow(strata))) {
  s   <- strata[i, ]
  sub <- plot_dat[plot_dat$cell_key == s$cell_key, ]
  if (nrow(sub) < 10) next
  for (rv in response_vars) {
    if (!(rv %in% names(sub))) next
    m_pt <- fit_constrained(sub$stand_age, sub[[rv]])
    if (is.null(m_pt)) next
    co <- coef(m_pt)
    pt_pred <- predict(m_pt, newdata = data.frame(age = age_grid))
    bs <- bootstrap_curves(sub$stand_age, sub[[rv]], age_grid)
    all_curves[[length(all_curves) + 1]] <- data.frame(
      cell_key = s$cell_key, ft_group = s$ft_group,
      ecoregion = s$ecoregion, owner = s$owner4,
      response = rv, age = age_grid,
      predicted = round(pt_pred, 3),
      lo95   = round(bs$lo95,   3),
      median = round(bs$median, 3),
      hi95   = round(bs$hi95,   3))
    all_fits[[length(all_fits) + 1]] <- data.frame(
      cell_key = s$cell_key, ft_group = s$ft_group,
      ecoregion = s$ecoregion, owner = s$owner4,
      response = rv,
      a = round(unname(co["a"]), 3),
      b = round(unname(co["b"]), 5),
      c = round(unname(co["c"]), 3),
      rmse = round(sqrt(mean(residuals(m_pt)^2, na.rm = TRUE)), 3),
      n_plots = nrow(sub),
      n_boot_succ = bs$n_succ,
      asymptote = round(unname(co["a"]), 3))
  }
  cat(sprintf("  cell %2d/%d: %s (n=%d)\n",
              i, nrow(strata), s$cell_key, nrow(sub)))
}

curves <- do.call(rbind, all_curves)
fits   <- do.call(rbind, all_fits)
write.csv(curves, file.path(out_dir, "maine_yield_curves_v2_long.csv"),
          row.names = FALSE)
write.csv(fits, file.path(out_dir, "maine_yield_curves_v2_fits.csv"),
          row.names = FALSE)
cat(sprintf("\nWrote %d rows long-format, %d fit rows\n",
            nrow(curves), nrow(fits)))

## ---- Figure: top 9 cells with bootstrap ribbons ---------------------
top_cells <- head(unique(strata$cell_key), 9)
png(file.path(fig_dir, "fig_yield_curves_v2_top9.png"),
    width = 1400, height = 1000, res = 110)
op <- par(mfrow = c(3, 3), mar = c(4, 4, 2, 1))
for (cell in top_cells) {
  pdat <- plot_dat[plot_dat$cell_key == cell &
                    !is.na(plot_dat$agb_tonac), ]
  cdat <- curves[curves$cell_key == cell & curves$response == "agb_tonac", ]
  fit_row <- fits[fits$cell_key == cell & fits$response == "agb_tonac", ]
  if (nrow(cdat) == 0) {
    plot.new(); title(sprintf("%s\n(no fit)", cell)); next
  }
  plot(pdat$stand_age, pdat$agb_tonac,
       pch = 16, col = rgb(0.2, 0.5, 0.2, 0.35),
       xlab = "Stand age (yr)", ylab = "AGB (tons / ac)",
       main = sprintf("%s\n(n=%d, bs=%d)", cell, nrow(pdat),
                      fit_row$n_boot_succ),
       xlim = c(0, 150),
       ylim = c(0, max(pdat$agb_tonac, cdat$hi95, na.rm = TRUE) * 1.05))
  polygon(c(cdat$age, rev(cdat$age)),
          c(cdat$lo95, rev(cdat$hi95)),
          col = rgb(0.8, 0.2, 0.2, 0.20), border = NA)
  lines(cdat$age, cdat$predicted, col = "darkred", lwd = 2)
  if (nrow(fit_row) == 1) {
    legend("topleft",
           legend = sprintf("a=%.1f  b=%.3f  c=%.2f",
                            fit_row$a, fit_row$b, fit_row$c),
           bty = "n", cex = 0.85)
  }
}
par(op)
dev.off()
cat(sprintf("Wrote figure: %s\n",
            file.path(fig_dir, "fig_yield_curves_v2_top9.png")))
