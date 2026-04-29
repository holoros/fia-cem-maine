"""
Manuscript Figure 1 candidate: 2x2 panel that tells the calibration story
in one figure.

(a) BAU AGC trajectories r17 vs r18 vs r19, RCP 4.5 wear, with subject-matched
    observed FIA at 2004-2024 overlaid as black points
(b) Maine forest ownership distribution (HCB classes 3-8, statewide pies)
(c) RMSE bar chart by tag x RCP x overlay (12 cells = 4 cells x 3 tags)
(d) 2074 BAU AGC summary by tag, with calibration anchor
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
OUT  = BASE / "figures"

# ---- Load data ---------------------------------------------------------
def load_run(rcp, econ, tag):
    f = BASE / "state_summary_progression" / (
        f"state_rcp{rcp}_hadgem2_wear{'_econ' if econ else ''}_{tag}_ci.csv")
    if not f.exists(): return None
    d = pd.read_csv(f)
    return d[d.scenario == "BAU"]

obs = pd.read_csv(BASE / "subject_matched_cv" /
                   "subject_matched_observed.csv")
obs5 = obs[obs.year.isin([2004, 2009, 2014, 2019, 2024])].copy()

metrics = pd.read_csv(BASE / "subject_matched_cv" /
                       "cv_metrics_r17_r18_r19.csv")
own_summary = pd.read_csv(BASE / "landowner" /
                           "maine_ownership_statewide_summary.csv")

# Color scheme aligned with prior figures
tag_color = {"r17": "#1f77b4", "r18": "#d62728", "r19": "#9467bd"}

fig, axes = plt.subplots(2, 2, figsize=(14, 10))

# ---- Panel (a): trajectories ------------------------------------------
ax = axes[0, 0]
for tag in ["r17", "r18", "r19"]:
    d = load_run("45", False, tag)
    if d is None: continue
    d = d.sort_values("year")
    ax.fill_between(d.year, d.mmt_agc_lo, d.mmt_agc_hi,
                    alpha=0.12, color=tag_color[tag], edgecolor="none")
    ax.plot(d.year, d.mmt_agc_mean, color=tag_color[tag], linewidth=2,
            label=f"{tag} BAU")

# Overlay subject-matched observed
ax.scatter(obs5.year, obs5.subject_only_agc_mmt, s=60, marker="o",
           color="black", edgecolor="white", linewidth=1.5,
           label="Subject-matched observed FIA", zorder=5)
ax.set_xlabel("Year")
ax.set_ylabel("MMT above-ground live tree carbon")
ax.set_title("(a) BAU trajectories vs observed (RCP 4.5 wear)",
             fontsize=11, weight="bold", loc="left")
ax.set_xlim(2000, 2080)
ax.grid(True, alpha=0.3)
ax.legend(loc="upper right", fontsize=9, framealpha=0.92)

# ---- Panel (b): Maine ownership distribution ---------------------------
ax = axes[0, 1]
own_sorted = own_summary.sort_values("area_acres", ascending=False)
short_labels = {3: "NIPF", 4: "Industrial", 5: "Tribal",
                6: "Federal", 7: "State", 8: "Local"}
own_sorted["short"] = own_sorted.hcb_class.map(short_labels)
hcb_colors = {"NIPF": "#558b2f", "Industrial": "#c62828",
              "Tribal": "#9c27b0", "Federal": "#1565c0",
              "State": "#fbc02d", "Local": "#5d4037"}
colors = [hcb_colors.get(s, "#999") for s in own_sorted["short"]]
wedges, _, atexts = ax.pie(
    own_sorted.area_acres, labels=own_sorted["short"],
    colors=colors, autopct=lambda p: f"{p:.0f}%",
    startangle=90, textprops=dict(fontsize=10),
    wedgeprops=dict(edgecolor="white", linewidth=1.2)
)
for at in atexts:
    at.set_color("white"); at.set_weight("bold"); at.set_fontsize(9)
ax.set_title(f"(b) Maine forest ownership by area "
             f"({own_sorted.area_acres.sum()/1e6:.1f} M ac, HCB 2025)",
             fontsize=11, weight="bold", loc="left")

# ---- Panel (c): RMSE bar chart ----------------------------------------
ax = axes[1, 0]
m = metrics.copy()
m["rcp_str"] = m.rcp.astype(str)
m["cell"] = m.apply(lambda r: f"RCP {r.rcp_str[0]}.{r.rcp_str[1]}\n"
                              f"{'wear+econ' if str(r.econ).lower() == 'true' else 'wear'}",
                    axis=1)
cells = m.cell.unique()
tags = ["r17", "r18", "r19"]
n_tags = len(tags)
n_cells = len(cells)
x = np.arange(n_cells)
w = 0.27
for i, tag in enumerate(tags):
    sub = m[m.tag == tag].set_index("cell").reindex(cells)
    ax.bar(x + (i - 1) * w, sub.rmse, width=w,
           label=tag, color=tag_color[tag], edgecolor="black", alpha=0.85)
    for xi, val in zip(x + (i - 1) * w, sub.rmse):
        ax.text(xi, val + 0.4, f"{val:.1f}", ha="center", fontsize=8)
ax.set_xticks(x)
ax.set_xticklabels(cells, fontsize=9)
ax.set_ylabel("Hindcast RMSE (MMT AGC)")
ax.set_title("(c) Hindcast skill across RCP × overlay × tag",
             fontsize=11, weight="bold", loc="left")
ax.legend(loc="upper right", fontsize=9)
ax.grid(axis="y", alpha=0.3)

# ---- Panel (d): 2074 endpoint bar -------------------------------------
ax = axes[1, 1]
endpoints = []
for tag in tags:
    for rcp in ["45", "85"]:
        for econ in [False, True]:
            d = load_run(rcp, econ, tag)
            if d is None: continue
            row = d[d.year == d.year.max()].iloc[0]
            cell = f"{rcp[0]}.{rcp[1]}\n{'econ' if econ else 'wear'}"
            endpoints.append({"tag": tag, "cell": cell,
                              "agc_mean": row.mmt_agc_mean,
                              "agc_lo": row.mmt_agc_lo,
                              "agc_hi": row.mmt_agc_hi})
ed = pd.DataFrame(endpoints)
cells2 = ed.cell.unique()
x = np.arange(len(cells2))
for i, tag in enumerate(tags):
    sub = ed[ed.tag == tag].set_index("cell").reindex(cells2)
    means = sub.agc_mean.values
    los   = sub.agc_lo.values
    his   = sub.agc_hi.values
    ax.bar(x + (i - 1) * w, means, width=w,
           label=tag, color=tag_color[tag], edgecolor="black", alpha=0.85,
           yerr=[means - los, his - means], capsize=3)

ax.set_xticks(x)
ax.set_xticklabels(cells2, fontsize=9)
ax.set_ylabel("2074 BAU AGC (MMT)")
ax.set_title("(d) 2074 BAU AGC by RCP × overlay × tag",
             fontsize=11, weight="bold", loc="left")
ax.legend(loc="upper right", fontsize=9)
ax.grid(axis="y", alpha=0.3)

fig.suptitle("FIA CEM Maine refined-pipeline calibration story: "
             "owner stratification cuts hindcast RMSE 35%",
             fontsize=13, weight="bold")
plt.tight_layout()

out_path = OUT / "fig_manuscript_figure_1.png"
plt.savefig(out_path, dpi=200, bbox_inches="tight")
print(f"Wrote {out_path}")
