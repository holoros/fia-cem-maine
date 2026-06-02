#!/usr/bin/env python3
"""
Patch: wire per-state terminal age into the age-class saturation (R-stateTerm).

Bug fixed: R/06_projection_engine.R line ~649 reads `cfg$terminal_age %||% 120`,
but `cfg$terminal_age` is never assigned anywhere and the per-state terminal_age
column in config/state_constants.csv is fetched into `state_const` yet never used
for saturation (only dT, fire baseline, and SDImax default are read from it). So
every state silently used Maine's 120-year terminal age in the growth ramp.

This activates the intended per-state values:
  ME 120 (unchanged, equals the old default), GA 80, WA 200, MN 110.
Direction is correct for the known biases: GA (overpredicts) attenuates growth
sooner at 80; WA (underpredicts) keeps mature growth longer at 200.

`state_const` is already in scope at the edit site (assigned earlier in the same
function). Idempotent; backs up the file before editing.
"""
import os, datetime, shutil, sys

ROOT = os.path.expanduser("~/fia_cem_projections")
DATE = datetime.date.today().strftime("%Y%m%d")
MARK = "R-stateTerm"
p06 = os.path.join(ROOT, "R", "06_projection_engine.R")

with open(p06) as f:
    s = f.read()

if MARK in s:
    print("06_projection_engine.R already patched, skipping")
    sys.exit(0)

bak = f"{p06}.bak.stateTerm_{DATE}"
if not os.path.exists(bak):
    shutil.copy2(p06, bak)
    print(f"  backup -> {bak}")

anchor = "  terminal_age     <- cfg$terminal_age     %||% 120"
if anchor not in s:
    sys.exit(f"ANCHOR NOT FOUND:\n{anchor}")

s = s.replace(
    anchor,
    "  terminal_age     <- cfg$terminal_age     %||% state_const$terminal_age %||% 120  # R-stateTerm: per-state terminal age (GA 80, WA 200, MN 110); ME 120 unchanged",
    1)

with open(p06, "w") as f:
    f.write(s)
print("06_projection_engine.R patched (per-state terminal age wired)")
print("DONE")
