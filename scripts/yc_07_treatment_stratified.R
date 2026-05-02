## yc_07_treatment_stratified.R  (Yield-Curve Phase 2, v3)
##
## Stratify yield curves by treatment history within each cell. Two
## treatment classes are derived from FIA COND:
##
##   "untreated"    plots with no TRTCD in the last 30 yr and no severe
##                  DSTRBCD in the last 20 yr. Stand age reflects
##                  passive succession.
##   "harvested"    plots where TRTCD1 ∈ {10 cutting, 20 site prep, 30
##                  artificial regen, 50 natural regen with site prep}
##                  and TRTYR1 within the last 30 yr.
##
## Fits constrained Chapman-Richards per (cell, treatment, response)
## with 200x bootstrap CIs. Outputs maine_yield_curves_v3_long.csv
## with treatment column + the same lo95/median/hi95 quantile bands.

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
cat(sprintf("Bootstrap : %d draws\n", N_BOOT))

## ---- Load lookups -----------------------------------------------------
strata <- read.csv(file.path(config_dir, "yc_strata_72cell.csv"),
                   stringsAsFactors = FALSE)
strata <- strata[strata$n_plots >= 30, ]
membership <- read.csv(file.path(config_dir, "yc_plot_membership.csv"),
                       stringsAsFactors = FALSE)
m <- membership[order(membership$PLT_CN, -membership$INVYR), ]
m <- m[!duplicated(m$PLT_CN), ]

## ---- FIA COND with treatment + age ----------------------------------
cat("Loading FIA COND...\n")
cond <- read.csv(file.path(fia_dir, "ME_COND.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
keep_c <- intersect(c("PLT_CN","CONDID","STDAGE","CONDPROP_UNADJ",
                      "TRTCD1","TRTYR1","TRTCD2","TRTYR2",
                      "DSTRBCD1","DSTRBYR1","DSTRBCD2","DSTRBYR2"),
                    names(cond))
cond <- cond[, keep_c]
for (col in c("STDAGE","CONDPROP_UNADJ","TRTCD1","TRTYR1",
              "TRTCD2","TRTYR2","DSTRBCD1","DSTRBYR1",
              "DSTRBCD2","DSTRBYR2")) {
  if (col %in% names(cond))
    cond[[col]] <- suppressWarnings(as.numeric(cond[[col]]))
}
cond <- cond[order(cond$PLT_CN, -cond$CONDPROP_UNADJ), ]
cond_dom <- cond[!duplicated(cond$PLT_CN), ]
cat(sprintf("Dominant condition rows: %d\n", nrow(cond_dom)))

## ---- Treatment classification ---------------------------------------
# Reference INVYR per plot from membership (latest visit)
m_yr <- m[, c("PLT_CN", "INVYR")]
cond_dom <- merge(cond_dom, m_yr, by = "PLT_CN", all.x = TRUE)

# Harvest treatment codes: 10=cutting, 20=site prep, 30=artificial regen,
#  50=natural regen with site prep
harvest_codes <- c(10, 20, 30, 50)

cond_dom$has_harvest <- ((cond_dom$TRTCD1 %in% harvest_codes &
                           !is.na(cond_dom$TRTYR1) &
                           (cond_dom$INVYR - cond_dom$TRTYR1) <= 30) |
                          (cond_dom$TRTCD2 %in% harvest_codes &
                           !is.na(cond_dom$TRTYR2) &
                           (cond_dom$INVYR - cond_dom$TRTYR2) <= 30))

# Severe disturbance codes: 10/12 insect (severe), 20/22 disease,
#  30 fire, 50/52 wind, 80 anthropogenic
sev_dstrb_codes <- c(10, 12, 20, 22, 30, 50, 52)
cond_dom$has_disturb <- ((cond_dom$DSTRBCD1 %in% sev_dstrb_codes &
                          !is.na(cond_dom$DSTRBYR1) &
                          (cond_dom$INVYR - cond_dom$DSTRBYR1) <= 20) |
                         (cond_dom$DSTRBCD2 %in% sev_dstrb_codes &
                          !is.na(cond_dom$DSTRBYR2) &
                          (cond_dom$INVYR - cond_dom$DSTRBYR2) <= 20))

# Treatment class assignment
cond_dom$treatment <- ifelse(cond_dom$has_harvest, "harvested",
                       ifelse(cond_dom$has_disturb, "disturbed",
                              "untreated"))
cat(sprintf("Treatment distribution:\n"))
print(table(cond_dom$treatment))

# Keep only plots with a stand age and a non-disturbed treatment class
cond_dom <- cond_dom[!is.na(cond_dom$STDAGE) & cond_dom$STDAGE > 0, ]
cond_dom <- cond_dom[cond_dom$treatment %in% c("untreated", "harvested"), ]
plot_age <- cond_dom[, c("PLT_CN", "STDAGE", "treatment")]
names(plot_age)[2] <- "stand_age"
cat(sprintf("Plots after stand-age filter: %d\n", nrow(plot_age)))

## ---- FIA TREE aggregates --------------------------------------------
cat("Loading FIA TREE...\n")
tree <- read.csv(file.path(fia_dir, "ME_TREE.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
tree <- tree[, intersect(c("PLT_CN","STATUSCD","DIA","TPA_UNADJ",
                            "DRYBIO_AG","CARBON_AG","VOLCFNET"),
                          names(tree))]
for (col in c("DIA","TPA_UNADJ","DRYBIO_AG","CARBON_AG","VOLCFNET")) {
  if (col %in% names(tree))
    tree[[col]] <- suppressWarnings(as.numeric(tree[[col]]))
}
tree$STATUSCD <- suppressWarnings(as.integer(tree$STATUSCD))
tree <- tree[!is.na(tree$STATUSCD) & tree$STATUSCD == 1, ]

agg <- function(formula, dat) {
  out <- aggregate(formula, dat, sum, na.rm = TRUE)
  out
}
agb <- agg(I(DRYBIO_AG * TPA_UNADJ) ~ PLT_CN, tree)
names(agb)[2] <- "agb_tonac"; agb$agb_tonac <- agb$agb_tonac / 2000
ba  <- agg(I(0.005454154 * DIA^2 * TPA_UNADJ) ~ PLT_CN, tree)
names(ba)[2] <- "ba_ft2ac"
tpa <- agg(TPA_UNADJ ~ PLT_CN, tree)
names(tpa)[2] <- "tpa_total"
c_ag <- agg(I(CARBON_AG * TPA_UNADJ) ~ PLT_CN, tree)
names(c_ag)[2] <- "carbon_lbac"
vol  <- agg(I(VOLCFNET * TPA_UNADJ) ~ PLT_CN, tree)
names(vol)[2] <- "vol_cuftac"

plot_dat <- Reduce(function(a, b) merge(a, b, by = "PLT_CN", all = TRUE),
                   list(plot_age, agb, ba, tpa, c_ag, vol))
plot_dat <- merge(plot_dat,
                  m[, c("PLT_CN", "cell_key", "ft_group",
                        "ecoregion", "owner4")],
                  by = "PLT_CN")
cat(sprintf("Plots with age + treatment + cell key: %d\n", nrow(plot_dat)))

## ---- Constrained Chapman-Richards + bootstrap ----------------------
chap_richards <- function(age, a, b, c) a * (1 - exp(-b * age))^c

fit_constrained <- function(age, y) {
  ok <- !is.na(age) & !is.na(y) & y > 0
  if (sum(ok) < 6) return(NULL)
  start_a <- max(y[ok], na.rm = TRUE) * 1.2
  tryCatch({
    nls(y ~ chap_richards(age, a, b, c),
        data = data.frame(age = age[ok], y = y[ok]),
        start = list(a = start_a, b = 0.04, c = 1.5),
        algorithm = "port",
        lower = c(a = 1, b = 0.005, c = 0.5),
        upper = c(a = max(y[ok], na.rm = TRUE) * 3, b = 0.20, c = 5.0),
        control = list(maxiter = 200, warnOnly = TRUE))
  }, error = function(e) NULL)
}

bootstrap_curves <- function(age, y, age_grid, n_boot = N_BOOT) {
  ok <- !is.na(age) & !is.na(y) & y > 0
  age <- age[ok]; y <- y[ok]; n <- length(age)
  if (n < 6) return(NULL)
  preds <- matrix(NA_real_, nrow = n_boot, ncol = length(age_grid))
  for (b in seq_len(n_boot)) {
    idx <- sample.int(n, n, replace = TRUE)
    m_b <- fit_constrained(age[idx], y[idx])
    if (is.null(m_b)) next
    preds[b, ] <- predict(m_b, newdata = data.frame(age = age_grid))
  }
  list(lo95 = apply(preds, 2, quantile, 0.05, na.rm = TRUE),
       median = apply(preds, 2, quantile, 0.50, na.rm = TRUE),
       hi95 = apply(preds, 2, quantile, 0.95, na.rm = TRUE),
       n_succ = sum(complete.cases(preds[, 1])))
}

response_vars <- c("agb_tonac", "ba_ft2ac", "carbon_lbac",
                   "tpa_total", "vol_cuftac")
age_grid <- seq(5, 150, by = 5)

all_curves <- list()
all_fits   <- list()

for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  for (trt in c("untreated", "harvested")) {
    sub <- plot_dat[plot_dat$cell_key == s$cell_key &
                     plot_dat$treatment == trt, ]
    if (nrow(sub) < 10) next
    for (rv in response_vars) {
      if (!(rv %in% names(sub))) next
      m_pt <- fit_constrained(sub$stand_age, sub[[rv]])
      if (is.null(m_pt)) next
      co <- coef(m_pt)
      pt_pred <- predict(m_pt, newdata = data.frame(age = age_grid))
      bs <- bootstrap_curves(sub$stand_age, sub[[rv]], age_grid)
      if (is.null(bs)) next
      all_curves[[length(all_curves) + 1]] <- data.frame(
        cell_key = s$cell_key, ft_group = s$ft_group,
        ecoregion = s$ecoregion, owner = s$owner4,
        treatment = trt, response = rv, age = age_grid,
        predicted = round(pt_pred, 3),
        lo95 = round(bs$lo95, 3),
        median = round(bs$median, 3),
        hi95 = round(bs$hi95, 3))
      all_fits[[length(all_fits) + 1]] <- data.frame(
        cell_key = s$cell_key, ft_group = s$ft_group,
        ecoregion = s$ecoregion, owner = s$owner4,
        treatment = trt, response = rv,
        a = round(unname(co["a"]), 3),
        b = round(unname(co["b"]), 5),
        c = round(unname(co["c"]), 3),
        rmse = round(sqrt(mean(residuals(m_pt)^2, na.rm = TRUE)), 3),
        n_plots = nrow(sub),
        n_boot_succ = bs$n_succ)
    }
    cat(sprintf("  cell %2d/%d  trt=%-9s  n=%d\n",
                i, nrow(strata), trt, nrow(sub)))
  }
}

curves <- do.call(rbind, all_curves)
fits   <- do.call(rbind, all_fits)
write.csv(curves, file.path(out_dir, "maine_yield_curves_v3_long.csv"),
          row.names = FALSE)
write.csv(fits, file.path(out_dir, "maine_yield_curves_v3_fits.csv"),
          row.names = FALSE)
cat(sprintf("\nWrote %d curve rows, %d fit rows\n",
            nrow(curves), nrow(fits)))

## ---- Comparison figure: untreated vs harvested for top cells -------
top_cells <- head(unique(strata$cell_key), 6)
png(file.path(fig_dir, "fig_yield_curves_v3_treatment.png"),
    width = 1500, height = 1000, res = 110)
op <- par(mfrow = c(2, 3), mar = c(4, 4, 2, 1))
for (cell in top_cells) {
  cdat <- curves[curves$cell_key == cell & curves$response == "agb_tonac", ]
  if (nrow(cdat) == 0) {
    plot.new(); title(sprintf("%s\n(no fits)", cell)); next
  }
  ymax <- max(cdat$hi95, na.rm = TRUE) * 1.05
  plot(NA, xlim = c(0, 150), ylim = c(0, ymax),
       xlab = "Stand age (yr)", ylab = "AGB (tons / ac)",
       main = cell)
  for (trt in c("untreated", "harvested")) {
    cd <- cdat[cdat$treatment == trt, ]
    if (nrow(cd) == 0) next
    col_main <- if (trt == "untreated") "#1b5e20" else "#c62828"
    col_band <- if (trt == "untreated") rgb(0.1,0.4,0.1,0.20)
                                       else rgb(0.78,0.15,0.15,0.20)
    polygon(c(cd$age, rev(cd$age)),
            c(cd$lo95, rev(cd$hi95)),
            col = col_band, border = NA)
    lines(cd$age, cd$predicted, col = col_main, lwd = 2.2)
  }
  legend("bottomright",
         legend = c("untreated", "harvested"),
         col = c("#1b5e20", "#c62828"), lwd = 2.2,
         bty = "n", cex = 0.85)
  grid(col = "grey85")
}
par(op)
dev.off()
cat(sprintf("Wrote figure: %s\n",
            file.path(fig_dir, "fig_yield_curves_v3_treatment.png")))
