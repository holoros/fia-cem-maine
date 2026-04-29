"""
Visualize SDImax distribution by Maine ecoregion and forest-type group.

Creates a two-panel figure:
  Left   : violin plot of plot-level BRMS SDImax (trees ha-1) by ecoregion
  Right  : boxplot of plot-level SDImax by forest-type group, coloured by group

Inputs : sdimax_brms_plot.csv (joined to ecoregion/fortype lookup inline here)
Output : figures/fig_sdimax_ecoregion_fortype.png
"""
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
OUT  = BASE / "figures"
OUT.mkdir(exist_ok=True)

df = pd.read_csv(BASE / "sdimax_brms" / "sdimax_brms_plot.csv")
df = df[df.STATECD == 23].copy()  # Maine only
print(f"Maine plots: {len(df)}")

ECO = {
    1: "Central Maine",       3: "Acadian Highlands", 5: "Central Maine",
    7: "Western Mountains",   9: "Eastern/Coastal",  11: "Central Maine",
    13: "Eastern/Coastal",   15: "Eastern/Coastal", 17: "Western Mountains",
    19: "Central Maine",     21: "Acadian Highlands", 23: "Central Maine",
    25: "Western Mountains", 27: "Central Maine",   29: "Eastern/Coastal",
    31: "Central Maine",
}
FORTYPE_GROUP = {
    102: "Softwood", 103: "Softwood", 104: "Softwood", 105: "Softwood",
    121: "Spruce-fir", 122: "Spruce-fir", 123: "Spruce-fir", 124: "Spruce-fir",
    125: "Spruce-fir", 126: "Spruce-fir", 127: "Spruce-fir", 128: "Spruce-fir",
    167: "Softwood", 381: "Softwood",
    401: "Mixed", 402: "Mixed", 409: "Mixed",
    503: "Hardwood", 505: "Hardwood", 506: "Hardwood", 513: "Hardwood",
    515: "Hardwood", 519: "Hardwood", 520: "Hardwood",
    701: "Hardwood", 703: "Hardwood", 704: "Hardwood", 708: "Hardwood",
    801: "Northern hardwood", 802: "Northern hardwood",
    805: "Northern hardwood", 809: "Northern hardwood",
    901: "Aspen-birch", 902: "Aspen-birch", 903: "Aspen-birch", 904: "Aspen-birch",
    922: "Northern hardwood",
}

df["ecoregion"]     = df.COUNTYCD.map(ECO).fillna("Unclassified")
df["fortype_group"] = df.FORTYPCD.map(FORTYPE_GROUP).fillna("Other")

eco_order = ["Acadian Highlands", "Western Mountains",
             "Central Maine", "Eastern/Coastal"]
fg_order  = ["Spruce-fir", "Softwood", "Mixed", "Aspen-birch",
             "Northern hardwood", "Hardwood", "Other"]

eco_colors = {"Acadian Highlands": "#1b5e20",
              "Western Mountains": "#2e7d32",
              "Central Maine":     "#558b2f",
              "Eastern/Coastal":   "#9e9d24"}
fg_colors = {"Spruce-fir": "#1b5e20", "Softwood": "#2e7d32",
             "Mixed": "#9e9d24", "Aspen-birch": "#fbc02d",
             "Northern hardwood": "#ef6c00", "Hardwood": "#c62828",
             "Other": "#616161"}

fig, axes = plt.subplots(1, 2, figsize=(12.5, 5.5),
                         gridspec_kw=dict(width_ratios=[1, 1.2]))

# Panel A: violin by ecoregion
ax = axes[0]
data_eco = [df.loc[df.ecoregion == e, "sdimax_metric_mean"].dropna().values
            for e in eco_order]
parts = ax.violinplot(data_eco, showmeans=False, showmedians=True, widths=0.85)
for i, body in enumerate(parts["bodies"]):
    body.set_facecolor(eco_colors[eco_order[i]])
    body.set_edgecolor("black")
    body.set_alpha(0.65)
parts["cmedians"].set_edgecolor("black")
parts["cbars"].set_edgecolor("0.4")
parts["cmins"].set_edgecolor("0.4")
parts["cmaxes"].set_edgecolor("0.4")
ax.set_xticks(range(1, len(eco_order) + 1))
ax.set_xticklabels(eco_order, rotation=15, ha="right", fontsize=9)
ax.set_ylabel("SDImax (trees ha$^{-1}$, BRMS posterior mean)")
ax.set_title("(a) By ecoregion", fontsize=11, weight="bold", loc="left")
ax.grid(axis="y", alpha=0.3)
ax.set_ylim(0, 2200)

# Sample-size labels above each violin
for i, e in enumerate(eco_order, start=1):
    n = (df.ecoregion == e).sum()
    ax.text(i, 2150, f"n={n}", ha="center", fontsize=8, color="0.3")

# Panel B: box by forest-type group
ax = axes[1]
data_fg = [df.loc[df.fortype_group == g, "sdimax_metric_mean"].dropna().values
           for g in fg_order]
bp = ax.boxplot(data_fg, patch_artist=True, widths=0.6,
                medianprops=dict(color="black", linewidth=1.5),
                flierprops=dict(marker=".", markersize=2, alpha=0.3))
for patch, g in zip(bp["boxes"], fg_order):
    patch.set_facecolor(fg_colors[g])
    patch.set_edgecolor("black")
    patch.set_alpha(0.85)
ax.set_xticks(range(1, len(fg_order) + 1))
ax.set_xticklabels(fg_order, rotation=18, ha="right", fontsize=9)
ax.set_ylabel("SDImax (trees ha$^{-1}$)")
ax.set_title("(b) By forest-type group", fontsize=11, weight="bold", loc="left")
ax.grid(axis="y", alpha=0.3)
ax.set_ylim(0, 2200)

for i, g in enumerate(fg_order, start=1):
    n = (df.fortype_group == g).sum()
    ax.text(i, 2150, f"n={n}", ha="center", fontsize=8, color="0.3")

# Secondary y-axis on right showing English (trees ac-1)
secax = axes[1].secondary_yaxis(
    "right",
    functions=(lambda x: x * 0.4046856,   # ha -> ac
               lambda x: x / 0.4046856))
secax.set_ylabel("SDImax (trees ac$^{-1}$)")

fig.suptitle("Maine plot-level BRMS SDImax distribution (n = "
             f"{len(df):,} FIA plots)", fontsize=12, weight="bold")
plt.tight_layout()

fig_path = OUT / "fig_sdimax_ecoregion_fortype.png"
plt.savefig(fig_path, dpi=200, bbox_inches="tight")
print(f"Wrote {fig_path}")

# Also write a small CSV summary of the means with both unit systems
summary = pd.DataFrame({
    "ecoregion":     [e for e in eco_order for _ in fg_order],
    "fortype_group": [g for _ in eco_order for g in fg_order],
})
summary["sdimax_metric_mean"] = summary.apply(
    lambda r: round(df.loc[(df.ecoregion == r.ecoregion) &
                           (df.fortype_group == r.fortype_group),
                           "sdimax_metric_mean"].mean(), 0)
    if ((df.ecoregion == r.ecoregion) &
        (df.fortype_group == r.fortype_group)).any() else np.nan,
    axis=1)
summary["sdimax_english_mean"] = round(
    summary["sdimax_metric_mean"] * 0.4046856, 0)
summary["n_plots"] = summary.apply(
    lambda r: ((df.ecoregion == r.ecoregion) &
               (df.fortype_group == r.fortype_group)).sum(), axis=1)
summary.to_csv(BASE / "sdimax_brms" / "sdimax_eco_fg_means.csv", index=False)
print(f"Wrote {BASE / 'sdimax_brms' / 'sdimax_eco_fg_means.csv'}")
