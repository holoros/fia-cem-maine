#!/usr/bin/env python3
"""
patch_qmd_reconcile.py  (R-qmdRecon, 2026-06-06)

Closes residual 1 from docs/TPASAT_SMOKE_RESULT_20260606.md: proj_qmd was on an
independent growth path (qmd * gr_qmd) and never reconciled with the capped proj_BA
and proj_tpa, leaving a ~6x gap between reported BA and the BA implied by TPA and QMD.

Fix: inside apply_sdimax_cap, after BA and TPA are both scaled by sdi_ratio, derive
proj_qmd from the capped state so BA = TPA * 0.005454 * QMD^2 holds exactly
(QMD = sqrt(BA / (TPA * 0.005454)), BA in sq ft/acre, QMD in inches).

Requires patch_tpa_saturation.py to have been applied first (it adds the
`proj_tpa = proj_tpa * sdi_ratio` line this patch anchors on). Idempotent.

Usage:
    python3 patch_qmd_reconcile.py /path/to/R/06_projection_engine.R
"""
import sys, shutil, datetime

OLD = ("        proj_tpa      = proj_tpa      * sdi_ratio\n"
       "      ) |>")
NEW = ("        proj_tpa      = proj_tpa      * sdi_ratio,\n"
       "        # qmdRecon fix (20260606): derive QMD from the capped BA and TPA so\n"
       "        # BA = TPA * 0.005454 * QMD^2 holds exactly (closes the BA/QMD decoupling).\n"
       "        proj_qmd      = dplyr::if_else(proj_tpa > 0,\n"
       "                                       sqrt(proj_BA / (proj_tpa * 0.005454)),\n"
       "                                       proj_qmd)\n"
       "      ) |>")
SENTINEL = "qmdRecon fix (20260606)"


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: patch_qmd_reconcile.py <06_projection_engine.R>")
    path = sys.argv[1]
    src = open(path, encoding="utf-8").read()
    if SENTINEL in src:
        print("Already patched (sentinel present); no change.")
        return
    if "tpaSat fix (20260606)" not in src:
        sys.exit("ERROR: patch_tpa_saturation.py must be applied first. Aborting.")
    if OLD not in src:
        sys.exit("ERROR: anchor (proj_tpa scaling line) not found. Aborting.")
    bak = path + ".bak.qmdRecon_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    shutil.copy2(path, bak)
    print("backup:", bak)
    out = src.replace(OLD, NEW, 1)
    if SENTINEL not in out:
        sys.exit("ERROR: post-edit verification failed; backup retained.")
    open(path, "w", encoding="utf-8").write(out)
    print("Patched: proj_qmd reconciled from capped BA and TPA in apply_sdimax_cap.")


if __name__ == "__main__":
    main()
