#!/usr/bin/env python3
"""
Patch: EXPNS-weight harvested carbon by product in state expansion (R-hwpExp).

Aggregates the per-plot harv_c_saw/pulp/residue (emitted by R-hwpEmit) to state
totals and writes <prefix>_harvest_by_product.csv (scenario, year, Sawlog,
Pulpwood, Biomass in MMT C) -- the exact input contract for cem_to_hwp.py.
NA-safe: if a per_plot predates R-hwpEmit, the columns are seeded to 0 so the
expansion still runs. Idempotent.
"""
import os, datetime, shutil, sys

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-hwpExp"
p10 = os.path.join(ROOT, "R", "10_state_expansion.R")
s = open(p10).read()
if MARK in s:
    print("10 already patched, skipping"); sys.exit(0)

bak = f"{p10}.bak.hwpExp_{DATE}"
if not os.path.exists(bak):
    shutil.copy2(p10, bak); print(f"  backup -> {bak}")

def req(a):
    if a not in s: sys.exit(f"ANCHOR NOT FOUND:\n---\n{a}\n---")

# 1. guard columns + 2. per-plot mutate (insert before the sim_totals mutate)
a = "  # Per-sim state totals (7 carbon pools + biomass + volumes)\n  sim_totals <- per_plot |>\n    mutate("
req(a)
s = s.replace(a, """  # R-hwpExp: ensure harvested-carbon-by-product columns exist (0 if pre-R-hwpEmit)
  for (.hc in c("harv_c_saw", "harv_c_pulp", "harv_c_residue"))
    if (!.hc %in% names(per_plot)) per_plot[[.hc]] <- 0

  # Per-sim state totals (7 carbon pools + biomass + volumes)
  sim_totals <- per_plot |>
    mutate(""", 1)

a = """      plot_volcs_ft3    = volcs_ft3_per_acre              * area_acres
    ) |>"""
req(a)
s = s.replace(a, """      plot_volcs_ft3    = volcs_ft3_per_acre              * area_acres,
      plot_harv_saw_lb     = coalesce(harv_c_saw, 0)     * area_acres,
      plot_harv_pulp_lb    = coalesce(harv_c_pulp, 0)    * area_acres,
      plot_harv_residue_lb = coalesce(harv_c_residue, 0) * area_acres
    ) |>""", 1)

# 3. summarise: add mmt_harv_* (after merch_vol_mcf line)
a = "      merch_vol_mcf   = sum(plot_volcs_ft3,   na.rm = TRUE) * FT3_TO_MCF,"
req(a)
s = s.replace(a, """      merch_vol_mcf   = sum(plot_volcs_ft3,   na.rm = TRUE) * FT3_TO_MCF,
      mmt_harv_saw     = sum(plot_harv_saw_lb,     na.rm = TRUE) * LB_TO_MMT,   # R-hwpExp
      mmt_harv_pulp    = sum(plot_harv_pulp_lb,    na.rm = TRUE) * LB_TO_MMT,   # R-hwpExp
      mmt_harv_residue = sum(plot_harv_residue_lb, na.rm = TRUE) * LB_TO_MMT,   # R-hwpExp""", 1)

# 4. write harvest-by-product after year is added to sim_totals
a = """  sim_totals <- sim_totals |>
    mutate(year = anchor_year + cycle * cycle_length_yrs)"""
req(a)
s = s.replace(a, a + """

  # R-hwpExp: write WPsCS input (state harvested carbon by product, MMT C)
  if (all(c("mmt_harv_saw", "mmt_harv_pulp", "mmt_harv_residue") %in% names(sim_totals))) {
    hbp <- sim_totals |>
      group_by(scenario, year) |>
      summarise(Sawlog   = mean(mmt_harv_saw,     na.rm = TRUE),
                Pulpwood = mean(mmt_harv_pulp,    na.rm = TRUE),
                Biomass  = mean(mmt_harv_residue, na.rm = TRUE), .groups = "drop") |>
      arrange(scenario, year)
    write_csv(hbp, paste0(output_prefix, "_harvest_by_product.csv"))
    cat(sprintf("  Wrote %s_harvest_by_product.csv (WPsCS HWP input)\\n", output_prefix))
  }""", 1)

open(p10, "w").write(s)
print("10_state_expansion.R patched (harvest-by-product EXPNS aggregation)")
print("DONE")
