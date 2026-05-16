#!/usr/bin/env python3
"""build_rpa_aggregation_figures.py

Python fallback (matplotlib) of build_rpa_aggregation_figures.R. Generates the
same two output figures from the conus_hcs RPA aggregation output.

Inputs:  figures/rpa_by_subregion_20260516.csv
Outputs: figures/rpa_p_harvest_by_subregion.png
         figures/rpa_removal_per_ha_by_subregion.png
         figures/rpa_subregion_panel.png
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
IN_CSV = ROOT / "figures" / "rpa_by_subregion_20260516.csv"
OUT_DIR = ROOT / "figures"
ME_RPA_REF = 0.10

ORDER = ["North_Central", "South_East", "South_Central", "Pacific_Northwest"]
LABEL = {
    "North_Central": "North Central",
    "South_East": "South East",
    "South_Central": "South Central",
    "Pacific_Northwest": "Pacific Northwest",
}

df = pd.read_csv(IN_CSV)
df["rpa_subregion"] = pd.Categorical(df["rpa_subregion"], categories=ORDER, ordered=True)
df = df.sort_values("rpa_subregion").reset_index(drop=True)
labels = [LABEL[s] for s in df["rpa_subregion"]]


def style_axes(ax, title, subtitle, ylabel, ylim=None):
    ax.set_title(title, fontsize=11, fontweight="bold", loc="left", pad=14)
    ax.text(
        0.0, 1.02, subtitle, transform=ax.transAxes,
        fontsize=9, color="#444444", va="bottom"
    )
    ax.set_ylabel(ylabel, fontsize=10)
    ax.set_xlabel("")
    ax.grid(axis="y", linestyle="-", linewidth=0.4, alpha=0.5)
    ax.set_axisbelow(True)
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    if ylim is not None:
        ax.set_ylim(*ylim)


# Panel A: p_harvest
fig_a, ax_a = plt.subplots(figsize=(7, 4), dpi=150)
bars = ax_a.bar(labels, df["p_harvest"], color="#3a78a3", alpha=0.85)
err_lo = df["p_harvest"] - df["p_harvest_lo"]
err_hi = df["p_harvest_hi"] - df["p_harvest"]
ax_a.errorbar(
    labels, df["p_harvest"], yerr=[err_lo, err_hi],
    fmt="none", ecolor="#444444", capsize=4, elinewidth=0.8
)
ax_a.axhline(ME_RPA_REF, color="#c0504d", linestyle="--", linewidth=0.8)
ax_a.text(
    3.4, ME_RPA_REF + 0.04, "ME RPA reference (0.10)",
    color="#c0504d", ha="right", fontsize=9
)
style_axes(
    ax_a,
    "M1 harvest occurrence probability by RPA subregion",
    "Saturation at 0.86 to 0.92 across all subregions reflects re measured panel pair sample bias",
    "P(harvest) per 5 year cycle", ylim=(0, 1.05),
)
fig_a.tight_layout()
fig_a.savefig(OUT_DIR / "rpa_p_harvest_by_subregion.png", bbox_inches="tight")

# Panel B: removal per hectare
fig_b, ax_b = plt.subplots(figsize=(7, 4), dpi=150)
ax_b.bar(labels, df["removal_per_ha"], color="#7a9c6d", alpha=0.85)
style_axes(
    ax_b,
    "Predicted removal per hectare by RPA subregion",
    "Magnitudes within plausible RPA range despite saturated probability",
    "Removal (volume units per ha)",
)
fig_b.tight_layout()
fig_b.savefig(OUT_DIR / "rpa_removal_per_ha_by_subregion.png", bbox_inches="tight")

# Composite
fig_c, axes = plt.subplots(2, 1, figsize=(8, 8), dpi=150)
ax1, ax2 = axes
ax1.bar(labels, df["p_harvest"], color="#3a78a3", alpha=0.85)
ax1.errorbar(
    labels, df["p_harvest"], yerr=[err_lo, err_hi],
    fmt="none", ecolor="#444444", capsize=4, elinewidth=0.8
)
ax1.axhline(ME_RPA_REF, color="#c0504d", linestyle="--", linewidth=0.8)
ax1.text(
    3.4, ME_RPA_REF + 0.04, "ME RPA reference (0.10)",
    color="#c0504d", ha="right", fontsize=9
)
style_axes(
    ax1,
    "M1 harvest occurrence probability by RPA subregion",
    "Saturation at 0.86 to 0.92 across all subregions reflects re measured panel pair sample bias",
    "P(harvest) per 5 year cycle", ylim=(0, 1.05),
)
ax2.bar(labels, df["removal_per_ha"], color="#7a9c6d", alpha=0.85)
style_axes(
    ax2,
    "Predicted removal per hectare by RPA subregion",
    "Magnitudes within plausible RPA range despite saturated probability",
    "Removal (volume units per ha)",
)
fig_c.suptitle(
    "conus_hcs RPA aggregation, SLURM 9717200 (Layer 22, 16 May 2026)",
    fontsize=12, fontweight="bold", x=0.02, ha="left"
)
fig_c.text(
    0.02, 0.005,
    "Four subregions covered (12 STATECD): NC, SE, SC, PNW. Missing: NE, RM, PSW. Pacific_Northwest only 50 plots.",
    fontsize=8, color="#555555"
)
fig_c.tight_layout(rect=(0, 0.03, 1, 0.97))
fig_c.savefig(OUT_DIR / "rpa_subregion_panel.png", bbox_inches="tight")

print("RPA aggregation figures written to figures/")
for name in ("rpa_p_harvest_by_subregion.png", "rpa_removal_per_ha_by_subregion.png", "rpa_subregion_panel.png"):
    print(f"  {name}")
