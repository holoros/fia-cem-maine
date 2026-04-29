"""
r17 vs r18 comparison figure: shows the marginal effect of HCB landowner
stratification on AGC trajectory. Adds a panel that breaks state totals
into NIPF / Industrial / Public-Other contributions per cycle.
"""
import argparse, glob
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
SUM  = BASE / "state_summary_progression"
OUT  = BASE / "figures"
OUT.mkdir(exist_ok=True)


def load_tag(tag, rcp, scenario_name="BAU", econ=False):
    econ_part = "_econ" if econ else ""
    pat = str(SUM / f"state_rcp{rcp}_hadgem2_wear{econ_part}_{tag}_ci.csv")
    files = glob.glob(pat)
    if not files:
        return None
    df = pd.read_csv(files[0])
    return df[df.scenario == scenario_name].assign(tag=tag)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rcp", default="45", choices=["45", "85"])
    ap.add_argument("--econ", action="store_true")
    args = ap.parse_args()

    pairs = []
    for tag, label, color in [
        ("r17", "r17 baseline (refined pipeline, no R14)", "#1f77b4"),
        ("r18", "r18 + R14 HCB landowner stratification", "#d62728"),
    ]:
        d = load_tag(tag, args.rcp, "BAU", args.econ)
        if d is None:
            print(f"  [skip] {tag} not present yet for rcp{args.rcp} econ={args.econ}")
            continue
        pairs.append((tag, label, color, d))

    if len(pairs) < 2:
        print("Need both r17 and r18 to compare; rerun once r18 lands.")
        return

    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5),
                             gridspec_kw=dict(width_ratios=[1, 1]))

    # Panel A: AGC trajectories
    ax = axes[0]
    for tag, label, color, d in pairs:
        d = d.sort_values("year")
        ax.fill_between(d.year, d.mmt_agc_lo, d.mmt_agc_hi,
                        alpha=0.15, color=color, edgecolor="none")
        ax.plot(d.year, d.mmt_agc_mean, color=color, linewidth=2.2, label=label)
    ax.axhline(268, color="black", linestyle="--", linewidth=1, alpha=0.7,
               label="Subject-matched obs 2004 (268 MMT)")
    ax.set_xlabel("Year")
    ax.set_ylabel("MMT above-ground live tree carbon")
    ax.set_title(f"(a) BAU AGC trajectory, RCP {args.rcp[0]}.{args.rcp[1]}",
                 fontsize=11, weight="bold")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right", fontsize=9, framealpha=0.92)

    # Panel B: r18 - r17 delta
    ax = axes[1]
    r17 = pairs[0][3].set_index("year").mmt_agc_mean
    r18 = pairs[1][3].set_index("year").mmt_agc_mean
    common = r17.index.intersection(r18.index)
    delta = (r18.loc[common] - r17.loc[common])
    ax.bar(common, delta.values, color="#d62728", alpha=0.75, edgecolor="black")
    ax.axhline(0, color="black", linewidth=0.6)
    ax.set_xlabel("Year")
    ax.set_ylabel("r18 minus r17 (MMT AGC)")
    ax.set_title("(b) Marginal effect of HCB owner stratification",
                 fontsize=11, weight="bold")
    ax.grid(axis="y", alpha=0.3)

    fig.suptitle("Effect of HCB landowner stratification on Maine carbon "
                 f"projection (BAU{', econ overlay' if args.econ else ''})",
                 fontsize=12, weight="bold")
    plt.tight_layout()

    fig_path = OUT / f"fig_r17_vs_r18_rcp{args.rcp}{'_econ' if args.econ else ''}.png"
    plt.savefig(fig_path, dpi=200, bbox_inches="tight")
    print(f"Wrote {fig_path}")

    # Endpoint table
    last = max(r17.index.max(), r18.index.max())
    print(f"\n=== {last} BAU AGC: r17 vs r18 ===")
    rows = []
    for tag, label, _, d in pairs:
        endrow = d[d.year == last].iloc[0]
        rows.append({"tag": tag, "year": last,
                     "agc_mean": round(endrow.mmt_agc_mean, 1),
                     "agc_lo": round(endrow.mmt_agc_lo, 1),
                     "agc_hi": round(endrow.mmt_agc_hi, 1),
                     "n_cond": endrow.n_conditions})
    print(pd.DataFrame(rows).to_string(index=False))


if __name__ == "__main__":
    main()
