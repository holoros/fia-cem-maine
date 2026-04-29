"""
Progressive refinement comparison figure: r11 -> r12 -> r13 -> r14 -> r15 -> r16 -> r17.

Auto-discovers which r-tag CIs are present and plots whichever combinations
are available. Default panel = RCP 8.5 wear BAU (most coverage as of r12-r15).
Falls back to RCP 4.5 only when --rcp 45 is requested.

Outputs:
  fig_progression_comparison.png   (multi-line BAU AGC)
  progression_summary_2074.csv     (endpoint table)
  progression_baseline_2004.csv    (baseline table for calibration check)
"""
import argparse, glob, os, sys
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
OUT = BASE / "figures"
OUT.mkdir(exist_ok=True)

# Which directory to search for each tag
TAG_DIRS = {
    "r11": "state_summary_r11",
    "r12": "state_summary_progression",
    "r13": "state_summary_progression",
    "r14": "state_summary_progression",
    "r15": "state_summary_progression",
    "r16": "state_summary_progression",
    "r17": "state_summary_progression",
    "r18": "state_summary_progression",
}
TAG_REFINEMENT = {
    "r11": "r11 baseline (econ + multi-pool, no expansion)",
    "r12": "r12 + R1 subject-pool expansion (incl. periodic)",
    "r13": "r13 + R5 BRMS Reineke SDImax cap",
    "r14": "r14 + R8/R6 decoupled CO2 + disturbance",
    "r15": "r15 + R4 FORTYPCD species climate",
    "r16": "r16 + R4-VCC Potter species climate",
    "r17": "r17 R1-v2 (DESIGNCD-filtered, annualized only)",
    "r18": "r18 + R14 HCB landowner stratification",
}
TAG_COLORS = {
    "r11": "#7f7f7f", "r12": "#1f77b4", "r13": "#2ca02c",
    "r14": "#ff7f0e", "r15": "#9467bd", "r16": "#d62728",
    "r17": "#17becf", "r18": "#e91e63",
}

# Subject-matched observed (from r11 hindcast validation work)
OBS_2004_AGC_MMT = 268.0  # subject-matched average across remeasured panels


def load_tag(tag, rcp, scenario_name="BAU", econ=False):
    dirn = TAG_DIRS[tag]
    econ_part = "_econ" if econ else ""
    pat = str(BASE / dirn / f"state_rcp{rcp}_hadgem2_wear{econ_part}_{tag}_ci.csv")
    files = glob.glob(pat)
    if not files:
        return None
    df = pd.read_csv(files[0])
    df = df[df.scenario == scenario_name]
    df["tag"] = tag
    return df


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rcp", default="85", choices=["45", "85"],
                    help="RCP forcing (default 85 — has best r-tag coverage)")
    ap.add_argument("--econ", action="store_true",
                    help="Use econ-overlay variant (vs uncalibrated BAU)")
    ap.add_argument("--scenario", default="BAU",
                    help="Scenario name to plot (default BAU)")
    args = ap.parse_args()

    rows = []
    found_tags = []
    for tag in TAG_DIRS:
        d = load_tag(tag, args.rcp, args.scenario, args.econ)
        if d is None:
            print(f"  [skip] {tag} not present for rcp{args.rcp} econ={args.econ}")
            continue
        rows.append(d)
        found_tags.append(tag)

    if not rows:
        print(f"No CI files found for rcp{args.rcp} econ={args.econ}.")
        sys.exit(1)

    ci = pd.concat(rows, ignore_index=True)
    print(f"\nLoaded {len(ci)} rows across {len(found_tags)} tags: {found_tags}")

    # Plot
    fig, ax = plt.subplots(figsize=(11, 6.5))
    for tag in found_tags:
        s = ci[ci.tag == tag].sort_values("year")
        ax.fill_between(s.year, s.mmt_agc_lo, s.mmt_agc_hi,
                        alpha=0.10, color=TAG_COLORS[tag], edgecolor="none")
        ax.plot(s.year, s.mmt_agc_mean, color=TAG_COLORS[tag], linewidth=2,
                label=TAG_REFINEMENT[tag])

    # Calibration anchor: subject-matched observed
    ax.axhline(OBS_2004_AGC_MMT, color="black", linestyle="--", linewidth=1,
               alpha=0.7, label=f"Subject-matched obs 2004 ({OBS_2004_AGC_MMT:.0f} MMT)")

    title_econ = " (econ overlay)" if args.econ else ""
    ax.set_xlabel("Year")
    ax.set_ylabel("MMT above-ground live tree carbon")
    ax.set_title(f"Progressive refinement: BAU AGC, RCP {args.rcp[0]}.{args.rcp[1]}{title_econ}",
                 fontsize=12, weight="bold")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right", fontsize=8.5, framealpha=0.92)
    plt.tight_layout()

    out_name = f"fig_progression_rcp{args.rcp}{'_econ' if args.econ else ''}.png"
    fig_path = OUT / out_name
    plt.savefig(fig_path, dpi=200, bbox_inches="tight")
    print(f"Wrote {fig_path}")

    # Endpoint table at last year
    last_year = int(ci.year.max())
    end_tab = (ci[ci.year == last_year]
               [["tag", "mmt_agc_mean", "mmt_agc_lo", "mmt_agc_hi",
                 "mmt_total_c_mean", "n_conditions", "total_area_mha_mean"]]
               .round(1))
    print(f"\n=== {last_year} BAU AGC by r-tag ({args.scenario}, RCP {args.rcp}) ===")
    print(end_tab.to_string(index=False))
    end_tab.to_csv(OUT / f"progression_{last_year}_rcp{args.rcp}{'_econ' if args.econ else ''}.csv",
                   index=False)

    # Baseline table at earliest year
    first_year = int(ci.year.min())
    base_tab = (ci[ci.year == first_year]
                [["tag", "mmt_agc_mean", "mmt_total_c_mean",
                  "n_conditions", "total_area_mha_mean"]]
                .round(1))
    base_tab["delta_vs_obs"] = (base_tab.mmt_agc_mean - OBS_2004_AGC_MMT).round(1)
    print(f"\n=== {first_year} BAU AGC vs observed {OBS_2004_AGC_MMT} MMT ===")
    print(base_tab.to_string(index=False))
    base_tab.to_csv(OUT / f"progression_baseline_{first_year}_rcp{args.rcp}{'_econ' if args.econ else ''}.csv",
                    index=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
