#!/usr/bin/env python3
"""
Patch: emit harvested carbon by product to per_plot (R-hwpEmit).

Adds harv_c_total / harv_c_saw / harv_c_pulp / harv_c_residue (per-acre carbon)
to the projection output so the state expansion can EXPNS-weight them into the
WPsCS input (Year, Biomass, Pulpwood, Sawlog). Computed in the harvested branch
where carbon_ag, gr_carbon, .cm, harvest_intensity, and vol_removed_* are in
scope. The non-harvested and unmatched branches set them to 0 so every scenario
carries the columns. run_projection keep_cols is extended so they reach
per_plot_projections.rds.

Harmless when unused (extra zero columns); no flag needed. Idempotent.
"""
import os, datetime, shutil, sys

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-hwpEmit"

def backup(p):
    b = f"{p}.bak.hwpEmit_{DATE}"
    if not os.path.exists(b):
        shutil.copy2(p, b); print(f"  backup -> {b}")

def req(s, a, p):
    if a not in s: sys.exit(f"ANCHOR NOT FOUND in {p}:\n---\n{a}\n---")

# ---- R/06_projection_engine.R --------------------------------------------
p06 = os.path.join(ROOT, "R", "06_projection_engine.R")
s = open(p06).read()
if MARK in s:
    print("06 already patched, skipping")
else:
    backup(p06)
    # 1. harvested branch: compute removed carbon by product (after proj_qmd)
    a = """      proj_qmd      = qmd * gr_qmd * sqrt(1 - harvest_intensity * 0.3),
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = TRUE,"""
    req(s, a, p06)
    s = s.replace(a, """      proj_qmd      = qmd * gr_qmd * sqrt(1 - harvest_intensity * 0.3),
      harv_c_total   = carbon_ag * gr_carbon * .cm * harvest_intensity,                                          # R-hwpEmit
      harv_c_saw     = ifelse(coalesce(vol_removed_total, 0) > 0, harv_c_total * coalesce(vol_removed_sawtimber, 0) / vol_removed_total, 0),  # R-hwpEmit
      harv_c_pulp    = ifelse(coalesce(vol_removed_total, 0) > 0, harv_c_total * coalesce(vol_removed_pulpwood,  0) / vol_removed_total, 0),  # R-hwpEmit
      harv_c_residue = pmax(harv_c_total - harv_c_saw - harv_c_pulp, 0),                                          # R-hwpEmit
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = TRUE,""", 1)

    # 2. not-harvested branch: zero defaults
    a = """      proj_qmd      = qmd * gr_qmd,
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = FALSE,
      was_planted   = FALSE,
      was_unmatched = FALSE
    ) |> select(-.sat_age, -.cm),"""
    req(s, a, p06)
    s = s.replace(a, """      proj_qmd      = qmd * gr_qmd,
      harv_c_total = 0, harv_c_saw = 0, harv_c_pulp = 0, harv_c_residue = 0,   # R-hwpEmit
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = FALSE,
      was_planted   = FALSE,
      was_unmatched = FALSE
    ) |> select(-.sat_age, -.cm),""", 1)

    # 3. unmatched branch: zero defaults
    a = """      proj_qmd      = qmd,
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = FALSE,
      was_planted   = FALSE,
      was_unmatched = TRUE
    )"""
    req(s, a, p06)
    s = s.replace(a, """      proj_qmd      = qmd,
      harv_c_total = 0, harv_c_saw = 0, harv_c_pulp = 0, harv_c_residue = 0,   # R-hwpEmit
      cycle         = cycle_num,
      sim           = sim_id,
      was_harvested = FALSE,
      was_planted   = FALSE,
      was_unmatched = TRUE
    )""", 1)
    open(p06, "w").write(s)
    print("06 patched (harv_c_* emitted in all three branches)")

# ---- run_projection.R: keep harv_c_* in per_plot --------------------------
prun = os.path.join(ROOT, "run_projection.R")
s = open(prun).read()
if MARK in s:
    print("run_projection.R already patched, skipping")
else:
    backup(prun)
    a = '                   "is_clearcut", "harvest_intensity",'
    req(s, a, prun)
    s = s.replace(a,
        '                   "is_clearcut", "harvest_intensity",\n'
        '                   "harv_c_total", "harv_c_saw", "harv_c_pulp", "harv_c_residue",  # R-hwpEmit\n',
        1)
    open(prun, "w").write(s)
    print("run_projection.R patched (per_plot keep_cols extended)")

print("DONE")
