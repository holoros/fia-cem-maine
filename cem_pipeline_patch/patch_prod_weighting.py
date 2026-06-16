#!/usr/bin/env python3
"""
Patch: soft productivity-weighted donor draw (R-prodW).

Adds a config-gated option that weights the per-subject donor draw within each
CEM cell by a Gaussian kernel on asymptotic-AGB closeness, instead of forcing a
shared productivity bin (the existing hard `--use_productivity` key, which drops
~37% of WA subjects that find no productivity-matched donor). Soft weighting
keeps the full subject pool while still steering high-productivity subjects
toward high-productivity donors.

Flags added to run_projection.R:
  --use_prod_weighting          enable soft weighting
  --prod_weight_bw <Mg/ha>      kernel bandwidth on asymptotic AGB (default 50)

ME behavior is unchanged when the flag is off (default).
Idempotent: re-running is a no-op once markers are present.
Backs up each file to <file>.bak.prodW_<date> before first edit.
"""
import os, sys, datetime, shutil

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-prodW"

def backup_and_read(path):
    bak = f"{path}.bak.prodW_{DATE}"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
        print(f"  backup -> {bak}")
    with open(path) as f:
        return f.read()

def write(path, txt):
    with open(path, "w") as f:
        f.write(txt)

def require(src, anchor, path):
    if anchor not in src:
        sys.exit(f"ANCHOR NOT FOUND in {path}:\n---\n{anchor}\n---")

# ---------------------------------------------------------------------------
# 1. R/02_cem_matching.R
# ---------------------------------------------------------------------------
p02 = os.path.join(ROOT, "R", "02_cem_matching.R")
s = backup_and_read(p02)
if MARK in s:
    print("02_cem_matching.R already patched, skipping")
else:
    # 1a. broaden productivity-attach gate so donor asym_agb is present for weighting
    a = "  if (isTRUE(cfg$cem$use_productivity)) {"
    require(s, a, p02)
    s = s.replace(
        a,
        "  if (isTRUE(cfg$cem$use_productivity) || isTRUE(cfg$cem$use_prod_weighting)) {  # R-prodW",
        1)

    # 1b. carry donor asym_agb (renamed donor_asym) into matched_pairs
    a = """    inner_join(
      don_c |>
        mutate(donor_idx = row_number()) |>
        select(cem_key, donor_idx),
      by = "cem_key",
      relationship = "many-to-many"
    )"""
    require(s, a, p02)
    s = s.replace(a, """    inner_join(
      {  # R-prodW: carry donor asymptotic AGB for soft productivity weighting
        .dk <- don_c |> mutate(donor_idx = row_number())
        if ("asym_agb" %in% names(.dk))
          dplyr::select(.dk, cem_key, donor_idx, donor_asym = asym_agb)
        else dplyr::select(.dk, cem_key, donor_idx)
      },
      by = "cem_key",
      relationship = "many-to-many"
    )""", 1)
    write(p02, s)
    print("02_cem_matching.R patched")

# ---------------------------------------------------------------------------
# 2. R/05_scenario_biasing.R
# ---------------------------------------------------------------------------
p05 = os.path.join(ROOT, "R", "05_scenario_biasing.R")
s = backup_and_read(p05)
if MARK in s:
    print("05_scenario_biasing.R already patched, skipping")
else:
    # 2a. BAU branch of apply_scenario_bias: weighted key when enabled
    a = """  if (is.null(bias_params) || all(unlist(bias_params$Q_values) == 1.0)) {
    # BAU scenario: random selection
    return(
      matches |>
        group_by(subject_row) |>
        mutate(rv = runif(n())) |>
        slice_max(rv, n = 1, with_ties = FALSE) |>
        ungroup() |>
        select(-rv)
    )
  }"""
    require(s, a, p05)
    s = s.replace(a, """  # R-prodW: soft productivity-weighted donor draw (Efraimidis-Spirakis key
  # rv = u^(1/w), w = exp(-0.5*((donor_asym - asym_agb)/bw)^2)). When disabled
  # or columns absent, falls back to the original uniform draw.
  use_pw <- isTRUE(getOption("cem.prod_weighting", FALSE)) &&
            all(c("asym_agb", "donor_asym") %in% names(matches))
  bw_pw <- as.numeric(getOption("cem.prod_bw", 50))

  if (is.null(bias_params) || all(unlist(bias_params$Q_values) == 1.0)) {
    # BAU scenario: random (optionally productivity-weighted) selection
    return(
      matches |>
        group_by(subject_row) |>
        mutate(rv = if (use_pw) {
                 w <- exp(-0.5 * ((donor_asym - asym_agb) / bw_pw)^2)
                 w[is.na(w)] <- 1
                 runif(n())^(1 / pmax(w, 1e-6))
               } else runif(n())) |>
        slice_max(rv, n = 1, with_ties = FALSE) |>
        ungroup() |>
        select(-rv)
    )
  }""", 1)

    # 2b. multi-event branch: weight the base random variate too
    a = """  # Start with base random variates
  match_data <- match_data |>
    mutate(rv = runif(n()))"""
    require(s, a, p05)
    s = s.replace(a, """  # Start with base random variates (R-prodW: optional productivity weighting)
  .use_pw <- isTRUE(getOption("cem.prod_weighting", FALSE)) &&
             all(c("asym_agb", "donor_asym") %in% names(match_data))
  .bw_pw <- as.numeric(getOption("cem.prod_bw", 50))
  match_data <- match_data |>
    mutate(rv = if (.use_pw) {
             w <- exp(-0.5 * ((donor_asym - asym_agb) / .bw_pw)^2)
             w[is.na(w)] <- 1
             runif(n())^(1 / pmax(w, 1e-6))
           } else runif(n()))""", 1)
    write(p05, s)
    print("05_scenario_biasing.R patched")

# ---------------------------------------------------------------------------
# 3. run_projection.R
# ---------------------------------------------------------------------------
prun = os.path.join(ROOT, "run_projection.R")
s = backup_and_read(prun)
if MARK in s:
    print("run_projection.R already patched, skipping")
else:
    # 3a. CLI parsing
    a = """      } else if (args[i] == "--use_productivity") {
        parsed$use_productivity <- TRUE; i <- i + 1"""
    require(s, a, prun)
    s = s.replace(a, """      } else if (args[i] == "--use_productivity") {
        parsed$use_productivity <- TRUE; i <- i + 1
      } else if (args[i] == "--use_prod_weighting") {  # R-prodW
        parsed$use_prod_weighting <- TRUE; i <- i + 1
      } else if (args[i] == "--prod_weight_bw") {      # R-prodW
        parsed$prod_weight_bw <- as.numeric(args[i + 1]); i <- i + 2""", 1)

    # 3b. CONFIG wiring + global options
    a = "  if (isTRUE(cli_args$use_productivity)) CONFIG$cem$use_productivity <- TRUE"
    require(s, a, prun)
    s = s.replace(a, """  if (isTRUE(cli_args$use_productivity)) CONFIG$cem$use_productivity <- TRUE
  if (isTRUE(cli_args$use_prod_weighting)) {  # R-prodW
    CONFIG$cem$use_prod_weighting <- TRUE
    CONFIG$cem$prod_weight_bw <- if (!is.null(cli_args$prod_weight_bw)) cli_args$prod_weight_bw else 50
    options(cem.prod_weighting = TRUE, cem.prod_bw = CONFIG$cem$prod_weight_bw)
    cat(sprintf("Productivity-weighted donor draw enabled (bandwidth=%.0f Mg/ha asymptotic AGB)\\n",
                CONFIG$cem$prod_weight_bw))
  }""", 1)
    write(prun, s)
    print("run_projection.R patched")

print("DONE")
