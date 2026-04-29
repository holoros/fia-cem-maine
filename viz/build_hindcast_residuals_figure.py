"""
Hindcast residual figure: r17 vs r18 vs r19 against subject-matched observed
FIA inventory at 2004, 2009, 2014, 2019, 2024 across all 4 RCP × overlay
combinations.

Produces:
  fig_hindcast_residuals_r17_r18_r19.png  — 2x2 panel by RCP × overlay
"""
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
OUT  = BASE / "figures"

residuals = pd.read_csv(
    BASE / "subject_matched_cv" / "cv_residuals_r17_r18_r19.csv")
metrics = pd.read_csv(
    BASE / "subject_matched_cv" / "cv_metrics_r17_r18_r19.csv")

print(f"Loaded {len(residuals)} residuals across "
      f"{residuals.tag.nunique()} tags x {len(residuals.groupby(['rcp','econ']))} cells")

tag_color = {"r17": "#1f77b4", "r18": "#d62728", "r19": "#9467bd"}
tag_marker = {"r17": "o", "r18": "s", "r19": "^"}

fig, axes = plt.subplots(2, 2, figsize=(13, 9), sharex=True, sharey=True)
panels = [
    ("45", False, "(a) RCP 4.5, no econ overlay"),
    ("45", True,  "(b) RCP 4.5, Maine econ overlay"),
    ("85", False, "(c) RCP 8.5, no econ overlay"),
    ("85", True,  "(d) RCP 8.5, Maine econ overlay"),
]

for ax, (rcp, econ, title) in zip(axes.flat, panels):
    sub = residuals[(residuals.rcp.astype(str) == rcp) &
                     (residuals.econ.astype(str).str.lower()
                       == str(econ).lower())]
    for tag in ["r17", "r18", "r19"]:
        s = sub[sub.tag == tag].sort_values("year")
        if len(s) == 0: continue
        ax.plot(s.year, s.residual, marker=tag_marker[tag],
                color=tag_color[tag], linewidth=1.8, markersize=8,
                label=tag)
    ax.axhline(0, color="black", linewidth=0.6, alpha=0.5)
    ax.fill_between([2003, 2025], -5, 5, color="grey", alpha=0.15,
                    label="±5 MMT band" if (rcp == "45" and not econ) else None)

    # Overlay metrics text
    cell_metrics = metrics[(metrics.rcp.astype(str) == rcp) &
                            (metrics.econ.astype(str).str.lower()
                              == str(econ).lower())]
    txt = []
    for _, m in cell_metrics.iterrows():
        txt.append(f"{m.tag}: RMSE {m.rmse:.1f}, bias {m.bias:+.1f}")
    ax.text(0.02, 0.04, "\n".join(txt), transform=ax.transAxes,
            fontsize=9, family="monospace", va="bottom",
            bbox=dict(facecolor="white", alpha=0.85, edgecolor="grey"))

    ax.set_title(title, fontsize=11, weight="bold", loc="left")
    ax.grid(True, alpha=0.3)
    if (rcp, econ) == ("45", False):
        ax.legend(loc="upper right", fontsize=9, framealpha=0.92)

for ax in axes[1, :]:
    ax.set_xlabel("Year")
for ax in axes[:, 0]:
    ax.set_ylabel("Projected − observed (MMT AGC)")

fig.suptitle("Hindcast residuals against subject-matched observed FIA "
             "(2004 to 2024)", fontsize=13, weight="bold")
plt.tight_layout()
out_path = OUT / "fig_hindcast_residuals_r17_r18_r19.png"
plt.savefig(out_path, dpi=200, bbox_inches="tight")
print(f"Wrote {out_path}")
