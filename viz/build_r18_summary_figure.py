"""
Headline summary figure for the r17 refined-pipeline result.
2x2 panel: RCP 4.5 / 8.5 x BAU / Harvest scenarios at full r17 stack.
Includes calibration anchor, all 5 scenarios, and 95% CI bands.
"""
import argparse, glob
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
SUM  = BASE / "state_summary_progression"
OUT  = BASE / "figures"

OBS_2004 = 268.0   # subject-matched observed AGC, 2004

scenario_colors = {
    "No_harvest":            "#1b5e20",
    "Harvest_Q0p5":          "#558b2f",
    "BAU":                   "#2e7d32",
    "Harvest_p25":           "#fbc02d",
    "Harvest_p50_biomass":   "#c62828",
}
scenario_labels = {
    "No_harvest":            "No harvest",
    "Harvest_Q0p5":          "Q=0.5 (half BAU)",
    "BAU":                   "BAU",
    "Harvest_p25":           "+25% BAU",
    "Harvest_p50_biomass":   "+50% biomass",
}


def load_run(rcp, econ):
    tag_path = SUM / f"state_rcp{rcp}_hadgem2_wear{'_econ' if econ else ''}_r18_ci.csv"
    if not tag_path.exists():
        return None
    return pd.read_csv(tag_path)


def main():
    fig, axes = plt.subplots(2, 2, figsize=(13, 9), sharex=True, sharey=True)
    panels = [
        ("45", False, "(a) RCP 4.5, no econ overlay"),
        ("45", True,  "(b) RCP 4.5, Maine econ overlay"),
        ("85", False, "(c) RCP 8.5, no econ overlay"),
        ("85", True,  "(d) RCP 8.5, Maine econ overlay"),
    ]
    summary_rows = []
    for ax, (rcp, econ, title) in zip(axes.flat, panels):
        df = load_run(rcp, econ)
        if df is None:
            ax.set_title(title + " (pending)")
            ax.text(0.5, 0.5, "data not yet present",
                    transform=ax.transAxes, ha="center", va="center",
                    fontsize=10, color="#888")
            continue
        scens = [s for s in scenario_colors if s in df.scenario.unique()]
        for s in scens:
            d = df[df.scenario == s].sort_values("year")
            color = scenario_colors[s]
            ax.fill_between(d.year, d.mmt_agc_lo, d.mmt_agc_hi,
                            alpha=0.15, color=color, edgecolor="none")
            ax.plot(d.year, d.mmt_agc_mean, color=color, linewidth=1.8,
                    label=scenario_labels[s])
            row = d[d.year == d.year.max()].iloc[0]
            summary_rows.append({
                "rcp": rcp, "econ": econ, "scenario": s,
                "agc_2004": round(d[d.year == d.year.min()].iloc[0].mmt_agc_mean, 1),
                "agc_2074": round(row.mmt_agc_mean, 1),
                "agc_2074_lo": round(row.mmt_agc_lo, 1),
                "agc_2074_hi": round(row.mmt_agc_hi, 1),
            })
        ax.axhline(OBS_2004, color="black", linestyle="--", linewidth=1, alpha=0.6)
        ax.set_title(title, fontsize=11, weight="bold", loc="left")
        ax.grid(True, alpha=0.3)
        ax.legend(loc="upper right", fontsize=8.5, framealpha=0.92)

    for ax in axes[1, :]:
        ax.set_xlabel("Year")
    for ax in axes[:, 0]:
        ax.set_ylabel("MMT above-ground live tree carbon")

    fig.suptitle("Maine forest carbon trajectories under climate × harvest scenarios "
                 "(r18, refined pipeline + R14 owner stratification)", fontsize=13, weight="bold")
    plt.tight_layout()
    out_path = OUT / "fig_r18_summary_2x2.png"
    plt.savefig(out_path, dpi=200, bbox_inches="tight")
    print(f"Wrote {out_path}")

    if summary_rows:
        sdf = pd.DataFrame(summary_rows)
        sdf.to_csv(OUT / "r18_summary_2x2.csv", index=False)
        print("\n=== r18 endpoint table ===")
        print(sdf.to_string(index=False))


if __name__ == "__main__":
    main()
