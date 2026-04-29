"""
4-tag attribution figure: r17 -> r18 -> r19 -> r20 disentangling
the owner-stratification mechanism into:
  r17        : uniform-rate baseline (no R12, no R14)
  r18        : + R14 owner stratification (NET RATE + SPATIAL effect)
  r19        : + R12 county offset (small marginal)
  r20        : R14-balanced (SPATIAL effect only; net rate matched to r17)

Decomposition logic:
  (r18 - r17) = NET RATE + SPATIAL effects of ownership
  (r20 - r17) = SPATIAL effect alone (mass-balanced rescale)
  (r18 - r20) = NET RATE effect alone (residual)
  (r19 - r18) = small county refinement (orthogonal)
"""
import argparse, glob
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
SUM  = BASE / "state_summary_progression"
OUT  = BASE / "figures"

OBS_2004 = 268.0


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

    tags_meta = [
        ("r17", "r17 uniform-rate baseline",            "#1f77b4"),
        ("r18", "r18 + R14 owner (rate + spatial)",     "#d62728"),
        ("r19", "r19 + R12 county offset",              "#9467bd"),
        ("r20", "r20 R14-balanced (spatial only)",      "#2ca02c"),
    ]
    pairs = []
    for tag, label, color in tags_meta:
        d = load_tag(tag, args.rcp, "BAU", args.econ)
        if d is None:
            print(f"  [skip] {tag}")
            continue
        pairs.append((tag, label, color, d))

    if len(pairs) < 2:
        print("Need at least 2 tags to compare.")
        return

    fig, axes = plt.subplots(2, 2, figsize=(14, 9))

    # Panel (a): trajectories
    ax = axes[0, 0]
    for tag, label, color, d in pairs:
        d = d.sort_values("year")
        ax.fill_between(d.year, d.mmt_agc_lo, d.mmt_agc_hi, alpha=0.12,
                        color=color, edgecolor="none")
        ax.plot(d.year, d.mmt_agc_mean, color=color, linewidth=2, label=label)
    ax.axhline(OBS_2004, color="black", linestyle="--", linewidth=1, alpha=0.7,
               label=f"Subject-matched obs 2004 ({OBS_2004:.0f} MMT)")
    ax.set_title(f"(a) BAU AGC trajectory, RCP {args.rcp[0]}.{args.rcp[1]}",
                 fontsize=11, weight="bold", loc="left")
    ax.set_ylabel("MMT above-ground live tree carbon")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right", fontsize=8.5, framealpha=0.92)

    # Panel (b): r18 - r17 (net rate + spatial), r20 - r17 (spatial alone)
    ax = axes[0, 1]
    by_tag = {p[0]: p[3].set_index("year").mmt_agc_mean for p in pairs}
    if "r17" in by_tag and "r18" in by_tag:
        common = by_tag["r17"].index.intersection(by_tag["r18"].index)
        net_plus_spatial = (by_tag["r18"] - by_tag["r17"]).loc[common]
        ax.plot(net_plus_spatial.index, net_plus_spatial.values, "o-",
                color="#d62728", linewidth=2, label="r18 − r17 (rate + spatial)")
    if "r17" in by_tag and "r20" in by_tag:
        common = by_tag["r17"].index.intersection(by_tag["r20"].index)
        spatial_only = (by_tag["r20"] - by_tag["r17"]).loc[common]
        ax.plot(spatial_only.index, spatial_only.values, "s-",
                color="#2ca02c", linewidth=2, label="r20 − r17 (spatial only)")
    if "r18" in by_tag and "r20" in by_tag:
        common = by_tag["r18"].index.intersection(by_tag["r20"].index)
        net_alone = (by_tag["r18"] - by_tag["r20"]).loc[common]
        ax.plot(net_alone.index, net_alone.values, "^--",
                color="#1f77b4", linewidth=2, label="r18 − r20 (net rate alone)")
    ax.axhline(0, color="black", linewidth=0.6)
    ax.set_title("(b) Decomposition: spatial vs net-rate effect",
                 fontsize=11, weight="bold", loc="left")
    ax.set_ylabel("Δ MMT AGC (vs r17 / vs r20)")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right", fontsize=8.5, framealpha=0.92)

    # Panel (c): bar of 2074 endpoint
    ax = axes[1, 0]
    rows = []
    for tag, _, color, d in pairs:
        endrow = d[d.year == d.year.max()].iloc[0]
        rows.append((tag, color, endrow.mmt_agc_mean,
                     endrow.mmt_agc_lo, endrow.mmt_agc_hi))
    if rows:
        x = np.arange(len(rows))
        means = [r[2] for r in rows]
        los   = [r[3] for r in rows]
        his   = [r[4] for r in rows]
        colors = [r[1] for r in rows]
        ax.bar(x, means, color=colors, edgecolor="black", alpha=0.85,
               yerr=[np.array(means) - np.array(los),
                     np.array(his)  - np.array(means)],
               capsize=4)
        ax.set_xticks(x)
        ax.set_xticklabels([r[0] for r in rows])
        for i, m in enumerate(means):
            ax.text(i, m + 1.5, f"{m:.1f}", ha="center", fontsize=9, weight="bold")
    ax.axhline(OBS_2004, color="black", linestyle="--", linewidth=1, alpha=0.5)
    ax.set_title("(c) 2074 BAU AGC by r-tag", fontsize=11, weight="bold", loc="left")
    ax.set_ylabel("MMT AGC")
    ax.grid(axis="y", alpha=0.3)

    # Panel (d): summary text + numerical table
    ax = axes[1, 1]
    ax.axis("off")
    txt_lines = ["Decomposition summary (RCP " + args.rcp[0] + "." + args.rcp[1] +
                 (" wear+econ" if args.econ else " wear") + "):", ""]
    if "r18" in by_tag and "r17" in by_tag and "r20" in by_tag:
        last = max(by_tag["r17"].index)
        d_total = by_tag["r18"].loc[last] - by_tag["r17"].loc[last]
        d_spatial = by_tag["r20"].loc[last] - by_tag["r17"].loc[last]
        d_rate = d_total - d_spatial
        txt_lines += [
            f"  Total R14 effect (r18 − r17):      {d_total:+6.1f} MMT",
            f"    Spatial (r20 − r17):             {d_spatial:+6.1f} MMT",
            f"    Net rate (r18 − r20):            {d_rate:+6.1f} MMT",
            "",
            f"  Spatial fraction of total:         {abs(d_spatial)/abs(d_total)*100:5.1f}%",
            f"  Net-rate fraction of total:        {abs(d_rate)/abs(d_total)*100:5.1f}%",
            ""
        ]
    if "r19" in by_tag and "r18" in by_tag:
        last = max(by_tag["r18"].index)
        d_county = by_tag["r19"].loc[last] - by_tag["r18"].loc[last]
        txt_lines += [
            f"  R12 county refinement (r19 − r18): {d_county:+6.1f} MMT",
        ]
    ax.text(0.02, 0.98, "\n".join(txt_lines), transform=ax.transAxes,
            fontsize=11, va="top", family="monospace")

    fig.suptitle("FIA CEM Maine refined-pipeline progression: "
                 "owner stratification decomposition",
                 fontsize=13, weight="bold")
    plt.tight_layout()

    fig_path = OUT / f"fig_r17_r20_attribution_rcp{args.rcp}{'_econ' if args.econ else ''}.png"
    plt.savefig(fig_path, dpi=200, bbox_inches="tight")
    print(f"Wrote {fig_path}")


if __name__ == "__main__":
    main()
