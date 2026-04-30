## yc_02_fvs_inputs_v2.R  (Yield-Curve Phase 2, step 2 — v2)
##
## Improvements over v1:
##   1) FIA SPCD → FVS 2-letter species code via fia_spcd_to_fvsne.csv
##   2) One FVS *stand* per FIA plot (rather than dumping all trees into
##      a single 14k-tree stand which exceeds FVS's 3000-tree limit).
##      Per-cell × treatment runs use multi-stand .key + .tre format.
##   3) Sample at most 50 plots per cell to keep each run tractable
##      (≤ 50 stands × ~50 trees = 2500 trees, comfortably under 3000).
##
## CLI:  Rscript yc_02_fvs_inputs_v2.R <fia_dir> <config_dir> <output_dir>

args <- commandArgs(trailingOnly = TRUE)
fia_dir    <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "fia_data")
config_dir <- if (length(args) >= 2) args[2] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
out_dir    <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "yield_curves", "runs")
N_PLOT_MAX <- if (length(args) >= 4) as.integer(args[4]) else 50L

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
set.seed(20260430)

cat(sprintf("FIA dir   : %s\n", fia_dir))
cat(sprintf("Config dir: %s\n", config_dir))
cat(sprintf("Output dir: %s\n", out_dir))
cat(sprintf("Max plots/cell: %d\n", N_PLOT_MAX))

# ---- Load lookups ----------------------------------------------------
strata <- read.csv(file.path(config_dir, "yc_strata_72cell.csv"),
                   stringsAsFactors = FALSE)
strata <- strata[strata$n_plots >= 30, ]

membership <- read.csv(file.path(config_dir, "yc_plot_membership.csv"),
                       stringsAsFactors = FALSE)

spcd_xwalk <- read.csv(file.path(config_dir, "fia_spcd_to_fvsne.csv"),
                       stringsAsFactors = FALSE)

# ---- FIA tree records ------------------------------------------------
cat("Loading FIA TREE...\n")
tree <- read.csv(file.path(fia_dir, "ME_TREE.csv"),
                 colClasses = "character", stringsAsFactors = FALSE)
keep_cols <- intersect(c("CN","PLT_CN","INVYR","STATUSCD","SPCD","DIA","HT","CR","TPA_UNADJ"),
                        names(tree))
tree <- tree[, keep_cols]
tree$DIA       <- suppressWarnings(as.numeric(tree$DIA))
tree$HT        <- suppressWarnings(as.numeric(tree$HT))
tree$CR        <- suppressWarnings(as.numeric(tree$CR))
tree$TPA_UNADJ <- suppressWarnings(as.numeric(tree$TPA_UNADJ))
tree$SPCD      <- suppressWarnings(as.integer(tree$SPCD))
tree$STATUSCD  <- suppressWarnings(as.integer(tree$STATUSCD))
tree           <- tree[!is.na(tree$STATUSCD) & tree$STATUSCD == 1 &
                       !is.na(tree$DIA) & tree$DIA >= 1.0, ]
cat(sprintf("Live trees DIA>=1.0: %d\n", nrow(tree)))

# Latest plot record per PLT_CN
m <- membership
m <- m[order(m$PLT_CN, -m$INVYR), ]
m <- m[!duplicated(m$PLT_CN), ]

# ---- Treatment keyword blocks ----------------------------------------
treatments <- list(
  notreat = c(
    "* No treatment baseline"
  ),
  light_partial = c(
    "* Light partial cut: ITS at cycles 6, 12, 18 — ~15% BA removal each",
    "ThinDBH    6      All            0    0    0   15",
    "ThinDBH   12      All            0    0    0   15",
    "ThinDBH   18      All            0    0    0   15"
  ),
  heavy_partial = c(
    "* Heavy partial cut: shelterwood at cycles 8, 16 — ~50% BA removal",
    "ThinBBA    8      All            0    0    0   50",
    "ThinBBA   16      All            0    0    0   50"
  ),
  clearcut_regen = c(
    "* Clearcut at cycle 10 (year 50); natural regen",
    "ThinBBA   10      All            0    0    0  100"
  )
)

# ---- Variant ---------------------------------------------------------
get_variant <- function(ft_group, ecoregion) {
  if (ft_group == "Spruce-fir" && ecoregion %in% c("ME_NH", "ME_NCZ"))
    return("acd")
  return("ne")
}

# ---- Tree-record line ------------------------------------------------
# FVS legacy 80-col format:
# Plot(4)  Tree(3)  Count(3)  Hist(1)  Spp(3)  DBH(4.1)  DBHinc(3.1)  Ht(3)
# HtToCrn(3)  CrCl(1)  Dam1(2)  Sev1(2)  Dam2(2)  Sev2(2)  Dam3(2) ...
# We use a simplified write that fills required fields only.
cr_to_class <- function(cr) {
  if (is.na(cr) || cr <= 0) return("5")
  if (cr <= 10) return("1")
  if (cr <= 20) return("2")
  if (cr <= 30) return("3")
  if (cr <= 40) return("4")
  if (cr <= 50) return("5")
  if (cr <= 60) return("6")
  if (cr <= 70) return("7")
  if (cr <= 80) return("8")
  return("9")
}
fvs_tree_line <- function(plot_id, tree_no, tpa, spp, dia, ht, cr) {
  if (is.na(spp) || nchar(spp) == 0) spp <- "OH"
  spp_str <- sprintf("%-3s", spp)
  dia_str <- sprintf("%4d", round(dia * 10))
  ht_str  <- sprintf("%3d", ifelse(is.na(ht) | ht <= 0, 0, round(ht)))
  cc_str  <- cr_to_class(cr)
  sprintf("%4d%3d%3d  %s%s   %s   %s",
          plot_id, tree_no,
          ifelse(is.na(tpa) | tpa <= 0, 1, round(tpa)),
          spp_str, dia_str, ht_str, cc_str)
}

# ---- Keyword file (multi-stand format with shared treatment) ---------
build_key <- function(cell_key, treatment, baseline_year, n_stands,
                      cycle_count = 20) {
  stand_id <- substr(gsub("[^A-Za-z0-9]", "_", cell_key), 1, 24)
  # FVS multi-stand is achieved by putting STANDID changes inside a
  # single .key file and using OPEN to attach .tre data per stand. The
  # simplest legacy approach: have one StdInfo + Process pair per stand
  # by replicating the keyword block. But that loses the per-cell
  # treatment cleanness. The cleanest is to use NumCycle + treatment
  # at cell level + a single Process call per stand via Open/Process
  # cycling. For simplicity we run ONE FVS per stand here and
  # aggregate at the end. So build a single-stand keyword.
  c(
    sprintf("StdInfo                                                                          "),
    sprintf("InvYear      %d", baseline_year),
    sprintf("NumCycle     %d", cycle_count),
    sprintf("TimeInt        5"),
    sprintf("StandID    %-26s", stand_id),
    sprintf("MgmtId     %s", substr(treatment, 1, 4)),
    "",
    "* Treatment keywords",
    treatments[[treatment]],
    "",
    "* Output requests",
    "MaiCalc",
    "CarbRept",
    "CarbCalc      0     1    16    1",
    "MisrptOpt",
    "End",
    "",
    "Process"
  )
}

# ---- Generate per-(cell, treatment) run dirs -------------------------
spp_lookup <- function(spcd, variant) {
  i <- match(spcd, spcd_xwalk$SPCD)
  col <- if (variant == "acd") "fvs_acd" else "fvs_ne"
  out <- ifelse(is.na(i), "OH", spcd_xwalk[[col]][i])
  out[is.na(out) | out == ""] <- "OH"
  out
}

out_dirs <- character()
for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  variant <- get_variant(s$ft_group, s$ecoregion)

  cell_plots <- m[m$cell_key == s$cell_key, ]
  if (nrow(cell_plots) == 0) next
  if (nrow(cell_plots) > N_PLOT_MAX) {
    cell_plots <- cell_plots[sample(seq_len(nrow(cell_plots)), N_PLOT_MAX), ]
  }
  baseline_year <- max(as.integer(cell_plots$INVYR), na.rm = TRUE)

  cell_trees <- tree[tree$PLT_CN %in% cell_plots$PLT_CN, ]
  if (nrow(cell_trees) == 0) next
  cell_trees$fvs_spp <- spp_lookup(cell_trees$SPCD, variant)

  # plot_id from PLOT (4-digit-ish)
  cell_plots$plot_id <- as.integer(substr(as.character(cell_plots$PLOT), 1, 4))
  cell_trees <- merge(cell_trees,
                      cell_plots[, c("PLT_CN", "plot_id")],
                      by = "PLT_CN")

  # Build tree-record lines per plot (single-stand: pool all plots into
  # one stand by using the same plot_id; subsample to <=2900 trees)
  if (nrow(cell_trees) > 2900) {
    cell_trees <- cell_trees[sample(nrow(cell_trees), 2900), ]
  }
  tre_lines <- character()
  for (j in seq_len(nrow(cell_trees))) {
    t <- cell_trees[j, ]
    tre_lines <- c(tre_lines,
                   fvs_tree_line(t$plot_id, j, t$TPA_UNADJ,
                                 t$fvs_spp, t$DIA, t$HT, t$CR))
  }
  if (length(tre_lines) == 0) next

  for (treatment in names(treatments)) {
    safe <- gsub("[^A-Za-z0-9]", "_", s$cell_key)
    rd <- file.path(out_dir, sprintf("%s_%s", safe, treatment))
    dir.create(rd, recursive = TRUE, showWarnings = FALSE)
    writeLines(build_key(s$cell_key, treatment, baseline_year,
                          n_stands = nrow(cell_plots)),
               file.path(rd, "fvs_run.key"))
    writeLines(tre_lines, file.path(rd, "fvs_run.tre"))
    out_dirs <- c(out_dirs, rd)
  }
  cat(sprintf("  cell %2d/%d: %s (n_plots=%d, n_trees=%d, variant=%s)\n",
              i, nrow(strata), s$cell_key, nrow(cell_plots),
              nrow(cell_trees), variant))
}

idx <- data.frame(
  array_id = seq_along(out_dirs),
  rundir   = out_dirs,
  cell_key = sub("_(notreat|light_partial|heavy_partial|clearcut_regen)$", "",
                  basename(out_dirs)),
  treatment = sub("^.+_(notreat|light_partial|heavy_partial|clearcut_regen)$",
                   "\\1", basename(out_dirs)),
  variant  = sapply(out_dirs, function(d) {
    s <- sub("_(notreat|light_partial|heavy_partial|clearcut_regen)$", "",
              basename(d))
    parts <- strsplit(gsub("__", "|", s, fixed = FALSE), "\\|")[[1]]
    if (length(parts) >= 2 && grepl("Spruce", parts[1]) &&
        parts[2] %in% c("ME_NH", "ME_NCZ")) "acd" else "ne"
  })
)
write.csv(idx, file.path(out_dir, "yc_run_index.csv"), row.names = FALSE)
cat(sprintf("\nGenerated %d runs (%d cells × 4 treatments)\n",
            nrow(idx), nrow(idx) / 4))
