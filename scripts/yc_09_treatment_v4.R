## yc_09_treatment_v4.R  (Yield-Curve Phase 2, step 5 — anchored harvested fits)
##
## v3 produced upward-biased harvested asymptotes because the harvested
## chronosequence is a mix of recently cut plots (low AGB) and older
## post-cut plots (regrown AGB), with no time-since-treatment dimension.
## The Chapman-Richards `a` parameter inflated to absorb the terminal
## upward trend, yielding implausible asymptotes (e.g., 224 ton/ac for
## Northern hardwood NIPF harvested vs 64 ton/ac untreated).
##
## v4 fix (analytical): for cells with both untreated and harvested fits,
## keep the harvested curve's `b` (rate) and `c` (shape) but rescale `a`
## to the untreated asymptote of the SAME (forest type × ecoregion ×
## owner). The biological assumption: harvested stands and undisturbed
## stands of the same site type share the same long-term carrying
## capacity; what differs is the recovery trajectory.
##
## Inputs : yield_curves/maine_yield_curves_v3_long.csv
##          yield_curves/maine_yield_curves_v3_fits.csv
## Outputs: yield_curves/maine_yield_curves_v4_long.csv
##          yield_curves/maine_yield_curves_v4_fits.csv
##          figures/fig_yield_curves_v4_anchored.png
##          figures/fig_v3_vs_v4_harvested.png

args <- commandArgs(trailingOnly = TRUE)
yc_dir  <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "yield_curves")
fig_dir <- file.path(yc_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

v3_long <- read.csv(file.path(yc_dir, "maine_yield_curves_v3_long.csv"),
                    stringsAsFactors = FALSE)
v3_fits <- read.csv(file.path(yc_dir, "maine_yield_curves_v3_fits.csv"),
                    stringsAsFactors = FALSE)

cat(sprintf("v3 long rows: %d\n", nrow(v3_long)))
cat(sprintf("v3 fit rows : %d\n", nrow(v3_fits)))

chap_richards <- function(age, a, b, c) a * (1 - exp(-b * age))^c
ages_pred <- seq(5, 150, by = 5)

# ============================================================
# Build v4 fits: anchor harvested `a` to untreated `a`
# ============================================================
v4_fits <- v3_fits
v4_fits$anchor_source <- "free"
v4_fits$a_v3 <- v4_fits$a   # remember original

cells <- unique(v3_fits$cell_key)
n_anchored <- 0
n_v3_kept  <- 0

for (cell in cells) {
  for (resp in unique(v3_fits$response)) {
    untr_idx <- which(v4_fits$cell_key == cell &
                       v4_fits$response  == resp &
                       v4_fits$treatment == "untreated")
    harv_idx <- which(v4_fits$cell_key == cell &
                       v4_fits$response  == resp &
                       v4_fits$treatment == "harvested")
    if (length(untr_idx) == 1 && length(harv_idx) == 1) {
      a_unt <- v4_fits$a[untr_idx]
      a_har <- v4_fits$a[harv_idx]
      # Only anchor if the harvested asymptote is implausibly higher
      # than untreated (>20%); otherwise leave it.
      if (a_har > a_unt * 1.20) {
        v4_fits$a[harv_idx]              <- a_unt
        v4_fits$anchor_source[harv_idx]  <- "anchored_untreated_a"
        n_anchored <- n_anchored + 1
      } else {
        v4_fits$anchor_source[harv_idx]  <- "v3_kept_within_20pct"
        n_v3_kept <- n_v3_kept + 1
      }
    } else if (length(harv_idx) == 1) {
      # No paired untreated; keep v3 free fit but flag
      v4_fits$anchor_source[harv_idx] <- "v3_kept_no_pair"
      n_v3_kept <- n_v3_kept + 1
    }
  }
}

cat(sprintf("Anchored harvested fits  : %d\n", n_anchored))
cat(sprintf("Untouched harvested fits : %d\n", n_v3_kept))
cat(sprintf("Untreated fits (free)    : %d\n",
            sum(v4_fits$treatment == "untreated")))

# ============================================================
# Rebuild long format from updated fits
# ============================================================
v4_long_list <- list()
for (i in seq_len(nrow(v4_fits))) {
  r <- v4_fits[i, ]
  pred <- chap_richards(ages_pred, r$a, r$b, r$c)
  v4_long_list[[i]] <- data.frame(
    cell_key      = r$cell_key,
    ft_group      = r$ft_group,
    ecoregion     = r$ecoregion,
    owner         = r$owner,
    treatment     = r$treatment,
    response      = r$response,
    age           = ages_pred,
    predicted     = round(pred, 3),
    anchor_source = r$anchor_source,
    stringsAsFactors = FALSE)
}
v4_long <- do.call(rbind, v4_long_list)

# Drop the diagnostic a_v3 column from final fits CSV
v4_fits_out <- v4_fits[, c("cell_key","ft_group","ecoregion","owner",
                            "treatment","response","a","b","c",
                            "n_plots","anchor_source","a_v3")]

write.csv(v4_long, file.path(yc_dir, "maine_yield_curves_v4_long.csv"),
          row.names = FALSE)
write.csv(v4_fits_out, file.path(yc_dir, "maine_yield_curves_v4_fits.csv"),
          row.names = FALSE)

cat(sprintf("Wrote v4 long rows: %d\n", nrow(v4_long)))
cat(sprintf("Wrote v4 fit rows : %d\n", nrow(v4_fits_out)))

# ============================================================
# Diagnostic: AGB harvested asymptote v3 vs v4
# ============================================================
agb_har <- v4_fits[v4_fits$response == "agb_tonac" &
                    v4_fits$treatment == "harvested", ]
cat("\nAGB harvested asymptote: v3 -> v4\n")
print(agb_har[, c("cell_key","a_v3","a","anchor_source")],
      row.names = FALSE)

# ============================================================
# Figure 1: top 9 untreated cells, untreated vs anchored harvested
# ============================================================
top_cells <- v4_fits[v4_fits$response == "agb_tonac" &
                      v4_fits$treatment == "untreated", ]
top_cells <- top_cells[order(-top_cells$n_plots), ][1:min(9, nrow(top_cells)), "cell_key"]

dat <- v4_long[v4_long$response == "agb_tonac" &
                v4_long$cell_key %in% top_cells, ]

png(file.path(fig_dir, "fig_yield_curves_v4_anchored.png"),
    width = 11, height = 8, units = "in", res = 150)
op <- par(mfrow = c(3, 3), mar = c(3.5, 3.5, 2.5, 0.5),
          oma = c(2, 2, 2, 0), cex.main = 0.85)
for (cell in top_cells) {
  d <- dat[dat$cell_key == cell, ]
  ymax <- max(d$predicted, na.rm = TRUE) * 1.1
  if (ymax <= 0) ymax <- 100
  plot(NA, xlim = c(0, 150), ylim = c(0, ymax),
       xlab = "Age (yr)", ylab = "AGB (tons/ac)",
       main = gsub("\\|", "/", cell))
  d_unt <- d[d$treatment == "untreated", ]
  d_har <- d[d$treatment == "harvested", ]
  if (nrow(d_unt) > 0)
    lines(d_unt$age, d_unt$predicted, col = "#1b5e20", lwd = 2.2)
  if (nrow(d_har) > 0) {
    src <- unique(d_har$anchor_source)
    col <- if (any(src == "anchored_untreated_a")) "#ef6c00" else "#9e9e9e"
    lines(d_har$age, d_har$predicted, col = col, lwd = 2.2, lty = 2)
  }
}
mtext("v4 yield curves: untreated (green solid) vs harvested (orange dashed = anchored, grey dashed = within tolerance)",
      side = 3, outer = TRUE, line = 0, cex = 0.8)
par(op)
dev.off()
cat(sprintf("\nWrote figure: fig_yield_curves_v4_anchored.png\n"))

# ============================================================
# Figure 2: v3 vs v4 harvested asymptote scatter
# ============================================================
agb_v3 <- v3_fits[v3_fits$response == "agb_tonac" &
                   v3_fits$treatment == "harvested",
                   c("cell_key","a")]
names(agb_v3)[2] <- "a_v3"
agb_v4 <- v4_fits[v4_fits$response == "agb_tonac" &
                   v4_fits$treatment == "harvested",
                   c("cell_key","a","anchor_source")]
names(agb_v4)[2] <- "a_v4"
cmp <- merge(agb_v3, agb_v4, by = "cell_key")

png(file.path(fig_dir, "fig_v3_vs_v4_harvested.png"),
    width = 7, height = 7, units = "in", res = 150)
op <- par(mar = c(4.5, 4.5, 3, 1))
xy_max <- max(c(cmp$a_v3, cmp$a_v4), na.rm = TRUE) * 1.05
plot(cmp$a_v3, cmp$a_v4, xlim = c(0, xy_max), ylim = c(0, xy_max),
     pch = ifelse(cmp$anchor_source == "anchored_untreated_a", 19, 21),
     col = ifelse(cmp$anchor_source == "anchored_untreated_a",
                   "#ef6c00", "#1976d2"),
     bg  = "white", cex = 1.4,
     xlab = "v3 free-fit asymptote (tons/ac)",
     ylab = "v4 anchored asymptote (tons/ac)",
     main = "Harvested AGB asymptote: v3 free vs v4 anchored")
abline(0, 1, lty = 3, col = "grey50")
legend("topleft",
        legend = c("Anchored to untreated a (>20% over)",
                   "v3 fit retained (within 20%)"),
        pch = c(19, 21), col = c("#ef6c00", "#1976d2"),
        bty = "n", cex = 0.9)
par(op)
dev.off()
cat(sprintf("Wrote figure: fig_v3_vs_v4_harvested.png\n"))
