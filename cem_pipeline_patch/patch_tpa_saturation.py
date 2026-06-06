#!/usr/bin/env python3
"""
patch_tpa_saturation.py  (R-tpaSat, 2026-06-06)

Fixes the runaway-ingrowth bug diagnosed in
docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md.

Two surgical edits to R/06_projection_engine.R:

  1. gr_tpa (both the not-harvested and harvested branches) was the ONLY growth
     rate lacking the `* .sat_age` age-saturation term that gr_BA, gr_carbon, etc.
     all carry. Without it, tree count compounds at up to 2.0x/cycle indefinitely,
     even in overmature stands. We wrap it the same way as the other rates so the
     departure from 1.0 ramps down with .sat_age.

  2. apply_sdimax_cap scaled proj_BA / proj_carbon / proj_vol* / proj_drybio by
     sdi_ratio but NEVER scaled proj_tpa, so the inflated TPA drove proj_sdi up,
     collapsed sdi_ratio, and crushed BA/carbon while TPA itself was never bounded.
     We also scale proj_tpa by sdi_ratio. QMD is held (proj_qmd unchanged), so
     scaling TPA and BA by the same ratio keeps SDI = TPA*(QMD/10)^1.605 capped at
     sdimax with TPA/BA/QMD mutually consistent.

Idempotent: refuses to double-apply. Writes a timestamped backup.

Usage:
    python3 patch_tpa_saturation.py /path/to/R/06_projection_engine.R
"""
import sys, os, shutil, datetime

GR_TPA_OLD = "      gr_tpa       = pmin(pmax(if_else(d_tpa_live > 0,  T2_tpa_live / d_tpa_live, 1.0),  0.5), 2.0),"
GR_TPA_NEW = "      gr_tpa       = 1 + (pmin(pmax(if_else(d_tpa_live > 0,  T2_tpa_live / d_tpa_live, 1.0),  0.5), 2.0) - 1) * .sat_age,"

CAP_OLD = "        proj_carbon   = proj_carbon   * sdi_ratio\n      ) |>"
CAP_NEW = ("        proj_carbon   = proj_carbon   * sdi_ratio,\n"
           "        # tpaSat fix (20260606): bind the SDImax cap on tree count too, so\n"
           "        # proj_tpa stays on the Reineke line and TPA/BA/QMD stay consistent.\n"
           "        # QMD is held; TPA and BA both scale by sdi_ratio.\n"
           "        proj_tpa      = proj_tpa      * sdi_ratio\n"
           "      ) |>")

SENTINEL = "tpaSat fix (20260606)"


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: patch_tpa_saturation.py <06_projection_engine.R>")
    path = sys.argv[1]
    src = open(path, encoding="utf-8").read()

    if SENTINEL in src:
        print("Already patched (sentinel present); no change.")
        return

    n_tpa = src.count(GR_TPA_OLD)
    if n_tpa != 2:
        sys.exit(f"ERROR: expected 2 gr_tpa occurrences, found {n_tpa}. Aborting.")
    if CAP_OLD not in src:
        sys.exit("ERROR: apply_sdimax_cap anchor not found. Aborting.")

    bak = path + ".bak.tpaSat_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    shutil.copy2(path, bak)
    print("backup:", bak)

    out = src.replace(GR_TPA_OLD, GR_TPA_NEW)              # both branches
    out = out.replace(CAP_OLD, CAP_NEW, 1)                 # the cap, once

    if out.count(GR_TPA_NEW) != 2 or SENTINEL not in out:
        sys.exit("ERROR: post-edit verification failed; backup retained.")

    open(path, "w", encoding="utf-8").write(out)
    print("Patched: 2 gr_tpa saturations + 1 SDImax-cap proj_tpa binding.")


if __name__ == "__main__":
    main()
