#!/usr/bin/env python3
"""
patch_sdimax_guard.py  (R-sdiGuard, 2026-06-08)

Hardens the Reineke SDImax cap against noisy BRMS posterior tails. The per-plot
SDImax (english) posterior has implausible extremes (min 36, max 1478 trees/acre;
imperial SDImax should sit ~300-600). Using a plot value of 36 would cap that plot's
density catastrophically low; 1478 would never bind. See docs/SDIMAX_UNITS_CHECK_20260608.md.

Fix: in apply_sdimax_cap, accept a plot- or fortyp-level SDImax only if it falls in a
sane imperial band [SDIMAX_LO, SDIMAX_HI]; otherwise fall through to the next source
(fortyp, then the state default). Units are unchanged (english / trees-per-acre); this
is a data-quality guard, not a units change.

Band: [150, 800] trees/acre (english). Catches the egregious tails while preserving
legitimate between-type variation (ME fortyp means ~450-495, plot mean ~380).

Idempotent. Requires the engine to already contain the coalesce on sdimax_eng_plot.

Usage:
    python3 patch_sdimax_guard.py /path/to/R/06_projection_engine.R
"""
import sys, re, shutil, datetime

SENTINEL = "sdiGuard fix (20260608)"
LO, HI = 150, 800

# Match the existing coalesce across the two lines, tolerant of whitespace.
PAT = re.compile(
    r"sdimax_eng\s*=\s*dplyr::coalesce\(\s*sdimax_eng_plot\s*,\s*sdimax_eng_fortyp\s*,\s*GLOBAL_SDIMAX_DEFAULT_ENG\)"
)

NEW = (
    "sdimax_eng = dplyr::coalesce(\n"
    f"          # sdiGuard fix (20260608): accept plot/fortyp SDImax only within a sane\n"
    f"          # imperial band [{LO}, {HI}] trees/acre; else fall through to the default.\n"
    f"          dplyr::if_else(dplyr::between(sdimax_eng_plot,   {LO}, {HI}), sdimax_eng_plot,   NA_real_),\n"
    f"          dplyr::if_else(dplyr::between(sdimax_eng_fortyp, {LO}, {HI}), sdimax_eng_fortyp, NA_real_),\n"
    "          GLOBAL_SDIMAX_DEFAULT_ENG)"
)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: patch_sdimax_guard.py <06_projection_engine.R>")
    path = sys.argv[1]
    src = open(path, encoding="utf-8").read()
    if SENTINEL in src:
        print("Already patched (sentinel present); no change.")
        return
    m = PAT.search(src)
    if not m:
        sys.exit("ERROR: SDImax coalesce anchor not found. Aborting.")
    bak = path + ".bak.sdiGuard_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    shutil.copy2(path, bak)
    print("backup:", bak)
    out = src[:m.start()] + NEW + src[m.end():]
    if SENTINEL not in out:
        sys.exit("ERROR: post-edit verification failed; backup retained.")
    open(path, "w", encoding="utf-8").write(out)
    print(f"Patched: SDImax band guard [{LO}, {HI}] trees/acre added to apply_sdimax_cap.")


if __name__ == "__main__":
    main()
