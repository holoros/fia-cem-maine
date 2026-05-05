## build_woodstock_pkg.R
##
## Builds a Remsoft-Woodstock-ready package from the v4 yield curve archive.
##
## Outputs (under woodstock_package/):
##   YIELDS.txt          : Woodstock YIELDS section, AGE-keyed, ready to paste
##   THEMES.txt          : THEMES section template (forest type, ecoregion,
##                         owner, treatment classifiers)
##   AREAS.txt           : AREAS template (one entry per stratum, area=1.0 ha
##                         placeholder; user replaces with their inventory)
##   ACTIONS.txt         : ACTIONS template (CLEARCUT, PARTIAL_CUT examples)
##   LIFESPAN.txt        : LIFESPAN section keyed by stratum
##   maine_v4_yields.csv : flat copy of source data with named columns
##   README.md           : import instructions for Woodstock practitioners
##   manifest.json       : provenance metadata

args <- commandArgs(trailingOnly = TRUE)
src_dir <- if (length(args) >= 1) args[1] else
  "/sessions/wonderful-peaceful-feynman/mnt/outputs/fia-cem-maine"
out_dir <- if (length(args) >= 2) args[2] else
  file.path(src_dir, "woodstock_package")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

long_csv <- file.path(src_dir, "yield_curves/adapters_v4/woodstock_yields_v4_long.csv")
fits_csv <- file.path(src_dir, "yield_curves/maine_yield_curves_v4_fits.csv")
faust_csv <- file.path(src_dir, "yield_curves/faustmann_optimal_rotation.csv")

long <- read.csv(long_csv, stringsAsFactors = FALSE)
fits <- read.csv(fits_csv, stringsAsFactors = FALSE)
faust <- read.csv(faust_csv, stringsAsFactors = FALSE)

cat(sprintf("Long rows : %d\n", nrow(long)))
cat(sprintf("Fits rows : %d\n", nrow(fits)))
cat(sprintf("Faustmann : %d\n", nrow(faust)))

# Make stratum names Woodstock-compatible: replace spaces and slashes with
# underscores, drop punctuation. Keep treatment as a separate classifier.
clean_name <- function(x) {
  x <- gsub("[/| ]", "_", x)
  x <- gsub("[^A-Za-z0-9_]", "", x)
  x
}

long$ft_id  <- clean_name(long$ft_group)
long$eco_id <- long$ecoregion
long$own_id <- clean_name(long$owner)
long$trt_id <- long$treatment

# Sort: stratum, treatment, ascending age
long <- long[order(long$ft_id, long$eco_id, long$own_id, long$trt_id, long$age), ]

# ============================================================
# 1. THEMES section: classifier definitions
# ============================================================
themes_lines <- c(
  "*THEME 1 Forest type group",
  paste0("  ", sort(unique(long$ft_id))),
  "",
  "*THEME 2 Ecoregion",
  paste0("  ", sort(unique(long$eco_id))),
  "",
  "*THEME 3 Ownership",
  paste0("  ", sort(unique(long$own_id))),
  "",
  "*THEME 4 Treatment history",
  paste0("  ", sort(unique(long$trt_id)))
)
writeLines(themes_lines, file.path(out_dir, "THEMES.txt"))
cat("Wrote THEMES.txt\n")

# ============================================================
# 2. YIELDS section: AGE-keyed yield tables per stratum-treatment
#    Format:
#       *Y stratum_4tuple
#       _AGE  AGB_tonac  Vol_cuftac  Carbon_tonac
#       0     0          0           0
#       5     ...
# ============================================================
strata <- unique(long[, c("ft_id","eco_id","own_id","trt_id")])
strata <- strata[order(strata$ft_id, strata$eco_id, strata$own_id, strata$trt_id), ]

yields_lines <- c(
  "; YIELDS section: Maine FIA empirical chronosequence yield curves (v4)",
  "; Source: github.com/holoros/fia-cem-maine v4 archive",
  "; Generated 2 May 2026; conversion factors documented in PERSEUS_handoff.md",
  ";",
  "; Columns: AGE   AGB_tonac   Vol_m3ha   Carbon_tonac",
  ";",
  "*Y"
)

for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  d <- long[long$ft_id == s$ft_id & long$eco_id == s$eco_id &
              long$own_id == s$own_id & long$trt_id == s$trt_id, ]
  if (nrow(d) == 0) next
  stratum_key <- paste(s$ft_id, s$eco_id, s$own_id, s$trt_id, sep = " ")
  yields_lines <- c(yields_lines,
                     sprintf("%s", stratum_key),
                     "_AGE  AGB_tonac  Vol_m3ha  Carbon_tonac",
                     "0     0.000      0.000     0.000")
  for (j in seq_len(nrow(d))) {
    yields_lines <- c(yields_lines,
                       sprintf("%-5d %-10.3f %-9.3f %-10.3f",
                                d$age[j], d$AGB_tonac[j], d$Vol_m3Ha[j],
                                round(d$AGB_tonac[j] * 0.45, 3)))
  }
  yields_lines <- c(yields_lines, "")
}

writeLines(yields_lines, file.path(out_dir, "YIELDS.txt"))
cat(sprintf("Wrote YIELDS.txt (%d strata-treatments)\n", nrow(strata)))

# ============================================================
# 3. AREAS template: one row per stratum-treatment, default 1.0 ha
# ============================================================
areas_lines <- c(
  "; AREAS section template",
  "; Replace 1.0 with actual inventory area in hectares per stratum",
  "; Source the area distribution from your FIA expansion or HCB owner atlas",
  ";",
  "*A"
)
for (i in seq_len(nrow(strata))) {
  s <- strata[i, ]
  stratum_key <- paste(s$ft_id, s$eco_id, s$own_id, s$trt_id, sep = " ")
  areas_lines <- c(areas_lines,
                    sprintf("%-60s 1.0", stratum_key))
}
writeLines(areas_lines, file.path(out_dir, "AREAS.txt"))
cat(sprintf("Wrote AREAS.txt (%d entries)\n", nrow(strata)))

# ============================================================
# 4. LIFESPAN: maximum age before mortality forces exit
#    Use age_to_90pct from fits as the natural lifespan proxy
# ============================================================
agb_fits <- fits[fits$response == "agb_tonac", ]
agb_fits$ft_id  <- clean_name(agb_fits$ft_group)
agb_fits$eco_id <- agb_fits$ecoregion
agb_fits$own_id <- clean_name(agb_fits$owner)
# age to 90% of asymptote
agb_fits$age_90 <- pmin(150,
  pmax(50,
        round(-log(1 - 0.9^(1 / agb_fits$c)) / agb_fits$b)))

lifespan_lines <- c(
  "; LIFESPAN section",
  "; Set per-stratum maximum age based on age_to_90pct of v4 AGB fit",
  "; bounded to [50, 150] years",
  ";",
  "*LIFESPAN"
)
for (i in seq_len(nrow(agb_fits))) {
  r <- agb_fits[i, ]
  stratum_key <- paste(r$ft_id, r$eco_id, r$own_id, r$treatment, sep = " ")
  lifespan_lines <- c(lifespan_lines,
                       sprintf("%-60s %d", stratum_key, r$age_90))
}
writeLines(lifespan_lines, file.path(out_dir, "LIFESPAN.txt"))
cat(sprintf("Wrote LIFESPAN.txt (%d entries)\n", nrow(agb_fits)))

# ============================================================
# 5. ACTIONS template: CLEARCUT and PARTIAL_CUT
#    Optimal rotations from Faustmann analysis go in the comments
# ============================================================
faust_unt <- faust[faust$treatment == "untreated" & faust$feasible == "TRUE", ]
faust_unt$ft_id  <- clean_name(faust_unt$ft_group)
faust_unt$eco_id <- faust_unt$ecoregion
faust_unt$own_id <- clean_name(faust_unt$owner)

actions_lines <- c(
  "; ACTIONS section template",
  "; CLEARCUT: full removal, transitions stratum to harvested treatment",
  ";           and resets age to 0 (with regeneration delay)",
  "; PARTIAL_CUT: ~50% removal, age penalty 40 yr (Wear 2019 Table 2)",
  "; FAUSTMANN_OPT: Faustmann-optimal rotation (notional 12 USD/cuft, 4% disc)",
  ";                shown as a comment for the no-carbon-floor case",
  ";",
  "*ACTION CLEARCUT",
  "*OPERABILITY",
  "  ? ? ? untreated _AGE >= 30",
  "*PARTIAL",
  "  none",
  "",
  "*ACTION PARTIAL_CUT",
  "*OPERABILITY",
  "  ? ? ? untreated _AGE >= 50",
  "*PARTIAL",
  "  Vol_m3ha 0.50",
  "",
  "; ===== Faustmann optimal rotations (no carbon floor) =====",
  "; Stratum                                                     R*"
)
zero_floor <- faust_unt[faust_unt$carbon_floor == 0, ]
for (i in seq_len(nrow(zero_floor))) {
  r <- zero_floor[i, ]
  stratum_key <- paste(r$ft_id, r$eco_id, r$own_id, "untreated", sep = " ")
  actions_lines <- c(actions_lines,
                      sprintf("; %-60s R* = %d yr", stratum_key, r$R_opt))
}

writeLines(actions_lines, file.path(out_dir, "ACTIONS.txt"))
cat("Wrote ACTIONS.txt\n")

# ============================================================
# 6. Flat CSV copy with all columns named
# ============================================================
flat <- long[, c("ft_id","eco_id","own_id","trt_id","period","age",
                  "AGB_tonac","AGB_MgHa","Vol_m3Ha","CarbonMgHa")]
names(flat) <- c("forest_type","ecoregion","owner","treatment",
                  "period","age_yr","AGB_tonac","AGB_MgHa",
                  "Vol_m3Ha","Carbon_MgHa")
flat$Carbon_tonac <- round(flat$AGB_tonac * 0.45, 3)
write.csv(flat, file.path(out_dir, "maine_v4_yields.csv"), row.names = FALSE)
cat(sprintf("Wrote maine_v4_yields.csv (%d rows)\n", nrow(flat)))

# ============================================================
# 7. Manifest with provenance
# ============================================================
manifest <- list(
  package_name = "Maine FIA v4 Yield Curve Package for Remsoft Woodstock",
  version = "1.0",
  generated = as.character(Sys.time()),
  source_repo = "github.com/holoros/fia-cem-maine",
  source_files = c(
    long_csv = basename(long_csv),
    fits_csv = basename(fits_csv),
    faust_csv = basename(faust_csv)
  ),
  n_strata_treatments = as.integer(nrow(strata)),
  n_yield_rows = as.integer(nrow(long)),
  age_range_yr = c(min(long$age), max(long$age)),
  conversion_factors = list(
    AGB_to_C = 0.45,
    tonac_to_MgHa = 2.2417,
    cuftac_to_m3ha = 0.069972,
    Jenkins_BG_ratio = 0.22
  ),
  contact = "aaron.weiskittel@maine.edu"
)

manifest_json <- paste0("{\n",
  paste(sprintf('  "%s": %s', names(manifest),
    sapply(manifest, function(v) {
      if (is.list(v))
        paste0("{ ", paste(sprintf('"%s": %g', names(v), unlist(v)),
                            collapse = ", "), " }")
      else if (length(v) > 1)
        paste0("[", paste(sprintf('"%s"', v), collapse = ", "), "]")
      else if (is.numeric(v))
        as.character(v)
      else
        sprintf('"%s"', v)
    })), collapse = ",\n"),
  "\n}\n")
writeLines(manifest_json, file.path(out_dir, "manifest.json"))
cat("Wrote manifest.json\n")

cat("\n=== Package summary ===\n")
files <- list.files(out_dir, full.names = TRUE)
for (f in files) {
  fi <- file.info(f)
  cat(sprintf("  %s  %s bytes\n", basename(f),
               format(fi$size, big.mark = ",")))
}
