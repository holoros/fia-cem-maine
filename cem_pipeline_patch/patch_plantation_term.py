#!/usr/bin/env python3
"""
Patch: stand-origin-aware plantation rotation age (R-plantTerm).

The per-state terminal age (R-stateTerm) moved GA only +20.4% -> +19.5%. The
GA cohort decomposition shows planted stands (STDORGCD==1, ~42% of projected
carbon) over-accumulating AGC at ages 41-80, well past loblolly's real 25-35yr
rotation. This patch lets planted stands use a shorter rotation age in the
age-class saturation ramp, so plantation growth attenuates near rotation age
instead of the natural terminal age.

Off by default (plantation_terminal_age NULL) -> sat_for_age behaves exactly as
before for every state, so ME/WA/MN are unchanged unless the flag is passed.

New flags in run_projection.R:
  --plantation_terminal_age <yr>   rotation age for planted stands (e.g. 35)
  --plantation_growth_start <yr>   ramp start for planted stands (default 15)

Idempotent; backs up R/06 and run_projection.R before editing.
"""
import os, datetime, shutil, sys

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-plantTerm"

def backup(path):
    bak = f"{path}.bak.plantTerm_{DATE}"
    if not os.path.exists(bak):
        shutil.copy2(path, bak); print(f"  backup -> {bak}")

def req(s, a, path):
    if a not in s:
        sys.exit(f"ANCHOR NOT FOUND in {path}:\n---\n{a}\n---")

# ---- R/06_projection_engine.R --------------------------------------------
p06 = os.path.join(ROOT, "R", "06_projection_engine.R")
s = open(p06).read()
if MARK in s:
    print("06 already patched, skipping")
else:
    backup(p06)
    # 1. replace sat_for_age definition with per-row capable version + helpers
    anchor = """  growth_start_age <- cfg$growth_start_age %||% 60
  sat_for_age <- function(age) {
    age <- pmin(pmax(coalesce(age, 0), 0), terminal_age)
    pmax(0, pmin(1, (terminal_age - age) / (terminal_age - growth_start_age)))
  }"""
    req(s, anchor, p06)
    s = s.replace(anchor, """  growth_start_age <- cfg$growth_start_age %||% 60
  # R-plantTerm: optional stand-origin-aware rotation age. Planted stands
  # (STDORGCD==1) use a shorter terminal/rotation age so plantation carbon does
  # not over-accumulate toward the natural terminal age. NULL -> unchanged.
  plant_term   <- cfg$plantation_terminal_age
  plant_gstart <- cfg$plantation_growth_start %||% 15
  .row_term <- function(stdorg) if (is.null(plant_term)) rep(terminal_age, length(stdorg)) else dplyr::if_else(dplyr::coalesce(stdorg, 0L) == 1L, as.numeric(plant_term), as.numeric(terminal_age))
  .row_gstart <- function(stdorg) if (is.null(plant_term)) rep(growth_start_age, length(stdorg)) else dplyr::if_else(dplyr::coalesce(stdorg, 0L) == 1L, as.numeric(plant_gstart), as.numeric(growth_start_age))
  sat_for_age <- function(age, term = terminal_age, gstart = growth_start_age) {
    term  <- pmax(term, gstart + 5)
    age   <- pmin(pmax(coalesce(age, 0), 0), term)
    pmax(0, pmin(1, (term - age) / (term - gstart)))
  }""", 1)

    # 2. call site A (not-harvested)
    a2 = "      .sat_age     = sat_for_age(STDAGE),"
    req(s, a2, p06)
    s = s.replace(a2, "      .sat_age     = sat_for_age(STDAGE, .row_term(STDORGCD), .row_gstart(STDORGCD)),  # R-plantTerm", 1)

    # 3. call site B (harvested branch)
    a3 = "      .sat_age     = if_else(.is_cc, sat_for_age(0), sat_for_age(pmax(0, STDAGE - 40))),"
    req(s, a3, p06)
    s = s.replace(a3, "      .sat_age     = if_else(.is_cc, sat_for_age(0, .row_term(STDORGCD), .row_gstart(STDORGCD)), sat_for_age(pmax(0, STDAGE - 40), .row_term(STDORGCD), .row_gstart(STDORGCD))),  # R-plantTerm", 1)

    open(p06, "w").write(s)
    print("06 patched (plantation rotation age)")

# ---- run_projection.R ----------------------------------------------------
prun = os.path.join(ROOT, "run_projection.R")
s = open(prun).read()
if MARK in s:
    print("run_projection.R already patched, skipping")
else:
    backup(prun)
    # CLI parsing (insert after the prod_weight_bw block added earlier, or after use_productivity)
    a = """      } else if (args[i] == "--prod_weight_bw") {      # R-prodW
        parsed$prod_weight_bw <- as.numeric(args[i + 1]); i <- i + 2"""
    if a in s:
        s = s.replace(a, a + """
      } else if (args[i] == "--plantation_terminal_age") {  # R-plantTerm
        parsed$plantation_terminal_age <- as.numeric(args[i + 1]); i <- i + 2
      } else if (args[i] == "--plantation_growth_start") {  # R-plantTerm
        parsed$plantation_growth_start <- as.numeric(args[i + 1]); i <- i + 2""", 1)
    else:
        a = """      } else if (args[i] == "--use_productivity") {
        parsed$use_productivity <- TRUE; i <- i + 1"""
        req(s, a, prun)
        s = s.replace(a, a + """
      } else if (args[i] == "--plantation_terminal_age") {  # R-plantTerm
        parsed$plantation_terminal_age <- as.numeric(args[i + 1]); i <- i + 2
      } else if (args[i] == "--plantation_growth_start") {  # R-plantTerm
        parsed$plantation_growth_start <- as.numeric(args[i + 1]); i <- i + 2""", 1)

    # CONFIG wiring
    a = "  if (isTRUE(cli_args$use_productivity)) CONFIG$cem$use_productivity <- TRUE"
    req(s, a, prun)
    s = s.replace(a, a + """
  if (!is.null(cli_args$plantation_terminal_age)) {  # R-plantTerm
    CONFIG$plantation_terminal_age <- cli_args$plantation_terminal_age
    if (!is.null(cli_args$plantation_growth_start)) CONFIG$plantation_growth_start <- cli_args$plantation_growth_start
    cat(sprintf("Plantation rotation age enabled: planted stands (STDORGCD=1) terminal age=%.0f, growth_start=%.0f\\n",
                CONFIG$plantation_terminal_age, CONFIG$plantation_growth_start %||% 15))
  }""", 1)
    open(prun, "w").write(s)
    print("run_projection.R patched")

print("DONE")
