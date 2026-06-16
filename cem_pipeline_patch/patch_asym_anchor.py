#!/usr/bin/env python3
"""
Patch: per-plot FIA asymptote anchoring (R-asymAnchor).

The v4 productivity multiplier is Maine-only (cem_productivity_multipliers_v4.csv
cells ME_APH/ME_NCZ/ME_NH; yc_plot_membership has 9 ME cell-keys), so it is a
no-op on WA. This adds a state-general per-plot anchor that mirrors the v4 idea
but uses per-plot FIA empirical asymptotes (asym_agb, covers WA) and the
donor_asym already plumbed into the matching for prodW.

Per cycle, projected BA / carbon / drybio / volume are scaled by
   anchor_pc = clamp( (subject_asym / donor_asym)^(strength / n_cycles), 0.90, 1.12 )
so the cumulative effect over the projection is about (subject_asym/donor_asym)^strength.
When donors grow slower than the subject (WA underprediction), subject_asym >
donor_asym -> anchor > 1 -> the trajectory is lifted toward the subject's own
FIA carrying capacity. NA-safe; identity when either asymptote is missing.

Flags (run_projection.R):
  --use_asym_anchor            enable
  --asym_anchor_strength <x>   cumulative exponent (default 1.0)

Off by default; ME and all prior runs unchanged. Idempotent.
"""
import os, datetime, shutil, sys

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-asymAnchor"

def backup(p):
    b = f"{p}.bak.asymAnchor_{DATE}"
    if not os.path.exists(b):
        shutil.copy2(p, b); print(f"  backup -> {b}")

def req(s, a, p):
    if a not in s: sys.exit(f"ANCHOR NOT FOUND in {p}:\n---\n{a}\n---")

ANCHOR_DEF = """      .anchor_pc    = if (isTRUE(getOption("cem.asym_anchor", FALSE))) {   # R-asymAnchor
                        .ar <- (coalesce(asym_agb, donor_asym) / pmax(coalesce(donor_asym, asym_agb), 1e-6))^(as.numeric(getOption("cem.asym_anchor_strength", 1)) / max(cfg$n_cycles, 1L))
                        .ar[is.na(.ar)] <- 1; pmin(pmax(.ar, 0.90), 1.12)
                      } else 1,
"""

# ---- R/06_projection_engine.R --------------------------------------------
p06 = os.path.join(ROOT, "R", "06_projection_engine.R")
s = open(p06).read()
if MARK in s:
    print("06 already patched, skipping")
else:
    backup(p06)

    # --- not-harvested branch ---
    a = """      .cm          = 1 + (climate_mult - 1) * .sat_age,
      # Apply donor growth rate to subject's own level, times climate multiplier
      proj_BA       = BA * gr_BA * .cm,
      proj_volcfnet = volcfnet * gr_volcfnet * .cm,
      proj_volcsnet = if ("volcsnet" %in% names(not_harvested)) volcsnet * gr_volcsnet * .cm else NA_real_,
      proj_drybio   = drybio_ag * gr_drybio * .cm,
      proj_carbon   = carbon_ag * gr_carbon * .cm,"""
    req(s, a, p06)
    s = s.replace(a, """      .cm          = 1 + (climate_mult - 1) * .sat_age,
""" + ANCHOR_DEF + """      # Apply donor growth rate to subject's own level, times climate multiplier
      proj_BA       = BA * gr_BA * .cm * .anchor_pc,
      proj_volcfnet = volcfnet * gr_volcfnet * .cm * .anchor_pc,
      proj_volcsnet = if ("volcsnet" %in% names(not_harvested)) volcsnet * gr_volcsnet * .cm * .anchor_pc else NA_real_,
      proj_drybio   = drybio_ag * gr_drybio * .cm * .anchor_pc,
      proj_carbon   = carbon_ag * gr_carbon * .cm * .anchor_pc,""", 1)
    # drop .anchor_pc in the not-harvested select
    s = s.replace("      was_unmatched = FALSE\n    ) |> select(-.sat_age, -.cm),",
                  "      was_unmatched = FALSE\n    ) |> select(-.sat_age, -.cm, -.anchor_pc),", 1)

    # --- harvested branch ---
    a = """      .cm          = 1 + (climate_mult - 1) * .sat_age,
      proj_BA       = BA * gr_BA * .cm * (1 - harvest_intensity),
      proj_volcfnet = volcfnet * gr_volcfnet * .cm * (1 - harvest_intensity),
      proj_volcsnet = if ("volcsnet" %in% names(harvested_plots)) volcsnet * gr_volcsnet * .cm * (1 - harvest_intensity) else NA_real_,
      proj_drybio   = drybio_ag * gr_drybio * .cm * (1 - harvest_intensity),
      proj_carbon   = carbon_ag * gr_carbon * .cm * (1 - harvest_intensity),"""
    req(s, a, p06)
    s = s.replace(a, """      .cm          = 1 + (climate_mult - 1) * .sat_age,
""" + ANCHOR_DEF + """      proj_BA       = BA * gr_BA * .cm * .anchor_pc * (1 - harvest_intensity),
      proj_volcfnet = volcfnet * gr_volcfnet * .cm * .anchor_pc * (1 - harvest_intensity),
      proj_volcsnet = if ("volcsnet" %in% names(harvested_plots)) volcsnet * gr_volcsnet * .cm * .anchor_pc * (1 - harvest_intensity) else NA_real_,
      proj_drybio   = drybio_ag * gr_drybio * .cm * .anchor_pc * (1 - harvest_intensity),
      proj_carbon   = carbon_ag * gr_carbon * .cm * .anchor_pc * (1 - harvest_intensity),""", 1)
    # drop .anchor_pc in harvested select (also drops harv_c temp none)
    s = s.replace(") |> select(-.sat_age, -.cm, -.is_cc),",
                  ") |> select(-.sat_age, -.cm, -.is_cc, -.anchor_pc),", 1)

    open(p06, "w").write(s)
    print("06 patched (asym anchor in both growth branches)")

# ---- run_projection.R -----------------------------------------------------
prun = os.path.join(ROOT, "run_projection.R")
s = open(prun).read()
if MARK in s:
    print("run_projection.R already patched, skipping")
else:
    backup(prun)
    a = """      } else if (args[i] == "--use_prod_weighting") {  # R-prodW
        parsed$use_prod_weighting <- TRUE; i <- i + 1"""
    req(s, a, prun)
    s = s.replace(a, a + """
      } else if (args[i] == "--use_asym_anchor") {     # R-asymAnchor
        parsed$use_asym_anchor <- TRUE; i <- i + 1
      } else if (args[i] == "--asym_anchor_strength") {# R-asymAnchor
        parsed$asym_anchor_strength <- as.numeric(args[i + 1]); i <- i + 2""", 1)

    a = """  if (isTRUE(cli_args$use_prod_weighting)) {  # R-prodW"""
    req(s, a, prun)
    s = s.replace(a, """  if (isTRUE(cli_args$use_asym_anchor)) {  # R-asymAnchor
    CONFIG$cem$use_prod_weighting <- isTRUE(CONFIG$cem$use_prod_weighting)  # asym anchor needs donor_asym attached
    CONFIG$use_asym_anchor <- TRUE
    .astr <- if (!is.null(cli_args$asym_anchor_strength)) cli_args$asym_anchor_strength else 1.0
    options(cem.asym_anchor = TRUE, cem.asym_anchor_strength = .astr,
            cem.prod_weighting = isTRUE(getOption("cem.prod_weighting", FALSE)))
    cat(sprintf("Per-plot FIA asymptote anchor enabled (strength=%.2f)\\n", .astr))
  }
""" + a, 1)
    open(prun, "w").write(s)
    print("run_projection.R patched (asym anchor flags)")

print("DONE")
