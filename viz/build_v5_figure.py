"""
v5 comparison figure: 5-scenario harvest sensitivity with actual differentiation.

Requires: state_summary_r9/ with expansion outputs from r9 jobs.

Inputs:
  state_*_wear_r9_ci.csv (wear, RCP 4.5 and 8.5)
  state_*_wear_econ_r9_ci.csv (wear+econ, RCP 4.5 and 8.5)
  observed_anchor.csv

Outputs:
  fig_comparison_v5.png    2x2 grid: pipeline x RCP, 5 trajectories per panel
  fig_delta_v5.png         delta-from-BAU panel
  comparison_v5_summary.csv
"""
import pandas as pd, matplotlib.pyplot as plt, glob, re
from pathlib import Path

SUM = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results/state_summary_r11")
OUT = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results/figures")

rows = []
for f in sorted(glob.glob(str(SUM / "state_*_ci.csv"))):
    tag = re.sub(r"^state_|_ci\.csv$", "", Path(f).name)
    df = pd.read_csv(f)
    df["tag"] = tag
    df["rcp"] = "RCP 4.5" if "rcp45" in tag else "RCP 8.5"
    df["pipeline"] = "wear + econ" if "wear_econ" in tag else "wear"
    rows.append(df)
ci = pd.concat(rows, ignore_index=True)
obs = pd.read_csv(SUM / "observed_anchor.csv")

scenarios = ["No_harvest", "Harvest_m25_mill", "BAU", "Harvest_p25_pulp", "Harvest_p50_biomass"]
scen_colors = {
    "No_harvest":          "#2ca02c",
    "Harvest_m25_mill":    "#1f77b4",
    "BAU":                 "#555555",
    "Harvest_p25_pulp":    "#ff7f0e",
    "Harvest_p50_biomass": "#d62728"
}
scen_labels = {
    "No_harvest":          "No harvest",
    "Harvest_m25_mill":    "-25% (mill closure)",
    "BAU":                 "BAU",
    "Harvest_p25_pulp":    "+25% (pulp demand)",
    "Harvest_p50_biomass": "+50% (biomass expansion)"
}

# ---- Panel 1: trajectories ----
fig, axes = plt.subplots(2, 2, figsize=(14, 9), sharex=True)
for i, pipe in enumerate(["wear", "wear + econ"]):
    for j, rcp in enumerate(["RCP 4.5", "RCP 8.5"]):
        ax = axes[i, j]
        sub = ci[(ci.pipeline == pipe) & (ci.rcp == rcp)]
        for scen in scenarios:
            s = sub[sub.scenario == scen].sort_values("year")
            if s.empty: continue
            ax.fill_between(s.year, s.mmt_agc_lo, s.mmt_agc_hi,
                             color=scen_colors[scen], alpha=0.12, edgecolor="none")
            ax.plot(s.year, s.mmt_agc_mean, color=scen_colors[scen],
                     linewidth=1.8, label=scen_labels[scen])
        ax.scatter(obs.year, obs.mmt_agc_mean, color="black", s=25, marker="D",
                    zorder=10, label="Observed FIA" if (i==0 and j==0) else None)
        ax.set_title(f"{pipe} / {rcp}", fontsize=11, weight="bold")
        if j == 0: ax.set_ylabel("MMT AGC")
        if i == 1: ax.set_xlabel("Year")
        ax.grid(True, alpha=0.3)
        if i == 0 and j == 1:
            ax.legend(loc="upper right", fontsize=8.5)

fig.suptitle("v5 — Maine forest AGC: 5 harvest scenarios (r9 unified-prep, fixed flags removed)",
              fontsize=13, weight="bold")
plt.tight_layout()
plt.savefig(OUT / "fig_comparison_v5.png", dpi=200, bbox_inches="tight")
plt.savefig(OUT / "fig_comparison_v5.pdf", bbox_inches="tight")
print(f"Wrote {OUT}/fig_comparison_v5.png")

# ---- Panel 2: delta from BAU ----
pivot = ci.pivot_table(index=["pipeline","rcp","year"], columns="scenario",
                        values="mmt_agc_mean").reset_index()
for scen in scenarios:
    if scen in pivot.columns:
        pivot[f"delta_{scen}"] = pivot[scen] - pivot["BAU"]

fig2, axes2 = plt.subplots(1, 2, figsize=(13, 5.5), sharey=True)
for j, rcp in enumerate(["RCP 4.5", "RCP 8.5"]):
    ax = axes2[j]
    for pipe in ["wear", "wear + econ"]:
        sub = pivot[(pivot.pipeline == pipe) & (pivot.rcp == rcp)].sort_values("year")
        ls = "-" if pipe == "wear" else "--"
        for scen in [s for s in scenarios if s != "BAU"]:
            d = f"delta_{scen}"
            if d not in sub.columns: continue
            ax.plot(sub.year, sub[d], color=scen_colors[scen], linestyle=ls,
                     linewidth=1.5,
                     label=f"{scen_labels[scen]} ({pipe})" if j == 1 else None)
    ax.axhline(0, color="black", linewidth=0.6)
    ax.set_title(f"Delta from BAU (AGC) — {rcp}", fontsize=11, weight="bold")
    ax.set_xlabel("Year")
    if j == 0: ax.set_ylabel("MMT AGC (scenario − BAU)")
    ax.grid(True, alpha=0.3)
    if j == 1: ax.legend(loc="upper left", fontsize=7.5, ncol=2)
fig2.suptitle("v5 delta-from-BAU: sensitivity to harvest intensity",
               fontsize=12, weight="bold")
plt.tight_layout()
plt.savefig(OUT / "fig_delta_v5.png", dpi=200, bbox_inches="tight")
print(f"Wrote {OUT}/fig_delta_v5.png")

# ---- Summary table ----
sy = [2004, 2024, 2049, 2074]
tbl = ci[ci.year.isin(sy)][["tag","rcp","pipeline","scenario","year",
                             "mmt_agc_mean","mmt_total_c_mean","n_conditions"]].round(1)
tbl = tbl.sort_values(["rcp","pipeline","year","scenario"])
tbl.to_csv(OUT / "comparison_v5_summary.csv", index=False)
print(f"Wrote {OUT}/comparison_v5_summary.csv")

print("\n=== v5 final AGC by scenario (2074) ===")
print(ci[ci.year==2074].groupby(["pipeline","rcp","scenario"])["mmt_agc_mean"].first().round(1))
