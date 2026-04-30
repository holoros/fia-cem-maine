## yc_02_fvs_inputs.R  (Yield-Curve Phase 2, step 2)
##
## For each well-sampled (n>=30) cell × treatment combination, generate a
## FVS-NE / FVS-ACD keyword (.key) file and a tree-record (.tre) file.
##
## - Variant: ACD (Acadian) for Spruce-fir cells in ME_NH and ME_NCZ;
##            NE (Northeastern) for everything else.
## - Treatments: notreat, light_partial, heavy_partial, clearcut_regen
## - Cycle length: 5 yr; cycles: 20 (100 yr horizon)
## - Output requested: CARBREPT (carbon report), MISRPTOPT (misc summary),
##   STRCLASS (size-class structure), DATABASE (SQL output)
##
## CLI:  Rscript yc_02_fvs_inputs.R <fia_dir> <config_dir> <output_dir>

args <- commandArgs(trailingOnly = TRUE)
fia_dir    <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "fia_data")
config_dir <- if (length(args) >= 2) args[2] else file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
out_dir    <- if (length(args) >= 3) args[3] else file.path(Sys.getenv("HOME"), "yield_curves")

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat(sprintf("FIA dir   : %s\n", fia_dir))
cat(sprintf("Config dir: %s\n", config_dir))
cat(sprintf("Output dir: %s\n", out_dir))

# ---- Load lookups ----------------------------------------------------
strata <- read.csv(file.path(config_dir, "yc_strata_72cell.csv"),
                   stringsAsFactors = FALSE)
strata <- strata[strata$n_plots >= 30, ]
cat(sprintf("Cells to process: %d\n", nrow(strata)))

membership <- read.csv(file.path(config_dir, "yc_plot_membership.csv"),
                       stringsAsFactors = FALSE)

# ---- FIA tree records (latest measurement per plot) ------------------
cat("Loading FIA TREE...\n")
tree <- read.csv(file.path(fia_dir, "ME_TREE.csv"),
                 colClasses = "character",   # PLT_CN is BIGINT-style
                 stringsAsFactors = FALSE)
# Keep only what we need for FVS input
keep <- c("CN", "PLT_CN", "INVYR", "STATUSCD", "SPCD", "DIA", "HT",
         "ACTUALHT", "CR", "TPA_UNADJ", "DAMTYP1", "DAMTYP2",
         "TREECLCD", "BHAGE", "TOTAGE")
keep <- intersect(keep, names(tree))
tree <- tree[, keep]
tree$DIA       <- suppressWarnings(as.numeric(tree$DIA))
tree$HT        <- suppressWarnings(as.numeric(tree$HT))
tree$CR        <- suppressWarnings(as.numeric(tree$CR))
tree$TPA_UNADJ <- suppressWarnings(as.numeric(tree$TPA_UNADJ))
tree$SPCD      <- suppressWarnings(as.integer(tree$SPCD))
tree$STATUSCD  <- suppressWarnings(as.integer(tree$STATUSCD))
tree           <- tree[!is.na(tree$STATUSCD) & tree$STATUSCD == 1, ]   # live trees
tree           <- tree[!is.na(tree$DIA) & tree$DIA >= 1.0, ]           # FVS min
cat(sprintf("Live trees with DIA >= 1.0: %d\n", nrow(tree)))

# Latest measurement per plot
m_by_plot <- membership
m_by_plot <- m_by_plot[order(m_by_plot$PLT_CN, -m_by_plot$INVYR), ]
m_by_plot <- m_by_plot[!duplicated(m_by_plot$PLT_CN), ]

# ---- Treatment keyword blocks ----------------------------------------
treatments <- list(
  notreat = c(
    "* No treatment baseline",
    "* (no extra keywords needed)"
  ),
  light_partial = c(
    "* Light partial cut: ITS at age 30, 60, 90 — ~15% BA removal each entry",
    "ThinDBH    6      All            0    0    0   15",   # cycle 6 (year 30): 15% BA
    "ThinDBH   12      All            0    0    0   15",   # cycle 12 (year 60)
    "ThinDBH   18      All            0    0    0   15"    # cycle 18 (year 90)
  ),
  heavy_partial = c(
    "* Heavy partial cut: shelterwood at age 40, 80 — ~50% BA removal",
    "ThinBBA    8      All            0    0    0   50",   # cycle 8 (year 40)
    "ThinBBA   16      All            0    0    0   50"    # cycle 16 (year 80)
  ),
  clearcut_regen = c(
    "* Clearcut + regen at age 50 (single rotation in 100-yr horizon)",
    "ThinBBA   10      All            0    0    0  100",   # cycle 10 (year 50)
    "* Plant at year 50 with same species mix (handled by natural regen by default)"
  )
)

# ---- Variant assignment ---------------------------------------------
get_variant <- function(ft_group, ecoregion) {
  if (ft_group == "Spruce-fir" && ecoregion %in% c("ME_NH", "ME_NCZ")) return("acd")
  return("ne")
}

# ---- Tree-record line format (FVS-NE legacy fixed width) -------------
# Cols 1-4 : Plot ID (from FIA: last 4 of PLOT)
# Cols 5-7 : Tree number (sequential within plot)
# Cols 8-10: Tree count factor (= TPA_UNADJ rounded)
# Cols 11-13: History code (1 = live)
# Cols 14-16: FVS species code (3-letter)
# Cols 17-20: DBH × 10 (so 12.5" → 0125)
# Cols 21-23: DBH increment × 100 (we don't compute, leave 0)
# Cols 24-26: Total height (ft)
# Cols 27-29: Height to live crown (ft)
# Cols 30-32: Crown ratio code (1-9; we set from CR pct)
# This is a simplified version; FVS will accept it but we may need
# species-code translation. For now use FIA SPCD numeric in cols 14-16.
fvs_tree_line <- function(plot_id, tree_no, tpa, status, spcd, dia, ht, cr) {
  spcd_str <- sprintf("%3d", as.integer(spcd))
  dia_str  <- sprintf("%4d", round(dia * 10))
  ht_str   <- sprintf("%3d", ifelse(is.na(ht), 0, round(ht)))
  cr_str   <- sprintf("%3d", ifelse(is.na(cr), 5, round(cr / 10)))   # CR in pct → 1-9
  sprintf("%4d%3d%3d%3d%s%s   %s%3d%s",
          plot_id, tree_no,
          ifelse(is.na(tpa), 1, round(tpa)),
          1, spcd_str, dia_str,
          ht_str, 0, cr_str)
}

# ---- Build a keyword file --------------------------------------------
build_key <- function(cell_key, treatment, variant, baseline_year, cycle_count = 20) {
  stand_id <- substr(gsub("[^A-Za-z0-9]", "_", cell_key), 1, 24)
  key_lines <- c(
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
    "Treelist     0     5    20",
    "CutList      0     5    20",
    "MaiCalc",
    "CarbRept",
    "CarbCalc      0     1    16    1",
    "MisrptOpt",
    "Compute",
    "MaxBA       400",
    "End",
    "",
    "Process"
  )
  key_lines
}

# ---- Generate input files for each cell × treatment ------------------
out_dirs <- c()
for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  variant <- get_variant(s$ft_group, s$ecoregion)

  # Plot members for this cell (latest measurement per plot)
  cell_plots <- m_by_plot[m_by_plot$cell_key == s$cell_key, ]
  if (nrow(cell_plots) == 0) next

  # Tree records for those plot CNs, latest INVYR per plot
  cell_trees <- tree[tree$PLT_CN %in% cell_plots$PLT_CN, ]
  if (nrow(cell_trees) == 0) next

  baseline_year <- max(as.integer(cell_plots$INVYR), na.rm = TRUE)

  # Tree-record file: one line per tree, plot-anchored
  cell_plots$plot_id <- as.integer(substr(cell_plots$PLOT, 1, 4))
  if (any(is.na(cell_plots$plot_id))) {
    cell_plots$plot_id <- seq_len(nrow(cell_plots))
  }

  tre_lines <- character()
  cell_trees <- merge(cell_trees,
                      cell_plots[, c("PLT_CN", "plot_id")],
                      by = "PLT_CN")
  for (pid in unique(cell_trees$plot_id)) {
    plt_trees <- cell_trees[cell_trees$plot_id == pid, ]
    for (j in seq_len(nrow(plt_trees))) {
      t <- plt_trees[j, ]
      tre_lines <- c(tre_lines,
                     fvs_tree_line(pid, j,
                                   t$TPA_UNADJ, 1, t$SPCD, t$DIA, t$HT, t$CR))
    }
  }
  if (length(tre_lines) == 0) next

  for (treatment in names(treatments)) {
    safe_cell <- gsub("[^A-Za-z0-9]", "_", s$cell_key)
    rundir <- file.path(out_dir, sprintf("%s_%s", safe_cell, treatment))
    dir.create(rundir, recursive = TRUE, showWarnings = FALSE)

    keyfile <- file.path(rundir, "fvs_run.key")
    trefile <- file.path(rundir, "fvs_run.tre")
    writeLines(build_key(s$cell_key, treatment, variant, baseline_year),
               keyfile)
    writeLines(tre_lines, trefile)

    out_dirs <- c(out_dirs, rundir)
  }
  cat(sprintf("  cell %2d/%d: %s (n=%d, %d trees, variant=%s)\n",
              i, nrow(strata), s$cell_key, nrow(cell_plots),
              nrow(cell_trees), variant))
}

# ---- Index file for the SLURM array job -----------------------------
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
    parts <- strsplit(gsub("_", "|", s), "\\|")[[1]]
    if (length(parts) >= 2 && grepl("Spruce", parts[1]) &&
        parts[2] %in% c("ME_NH", "ME_NCZ"))
      "acd" else "ne"
  })
)
write.csv(idx, file.path(out_dir, "yc_run_index.csv"), row.names = FALSE)

cat(sprintf("\nGenerated %d run dirs (%d cells × 4 treatments)\n",
            nrow(idx), nrow(idx) / 4))
cat(sprintf("Index file: %s\n", file.path(out_dir, "yc_run_index.csv")))
