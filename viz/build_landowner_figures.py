"""
Build Phase 1 visualization deliverables for the landowner integration:
- fig_maine_ownership_pie_by_county.png   small-multiples pie chart
- fig_maine_ownership_bars.png            stacked bar of % by county

Color scheme aligned with the HCB legend.
"""
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec
from pathlib import Path

BASE = Path("/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results")
LD   = BASE / "landowner"
OUT  = BASE / "figures"
OUT.mkdir(exist_ok=True)

atlas = pd.read_csv(LD / "maine_ownership_atlas.csv")
legend = pd.read_csv(LD / "owner_class_legend.csv")

# Maine county FIPS to name
county_names = {
    1: "Androscoggin", 3: "Aroostook", 5: "Cumberland", 7: "Franklin",
    9: "Hancock", 11: "Kennebec", 13: "Knox", 15: "Lincoln",
    17: "Oxford", 19: "Penobscot", 21: "Piscataquis", 23: "Sagadahoc",
    25: "Somerset", 27: "Waldo", 29: "Washington", 31: "York",
}
atlas["county"] = atlas.COUNTYCD.map(county_names)

# Restrict to forested classes (3-8)
forest = atlas[atlas.hcb_class.isin([3, 4, 5, 6, 7, 8])].copy()
forest["short_label"] = forest.hcb_class.map({
    3: "NIPF (Family)", 4: "Industrial", 5: "Tribal",
    6: "Federal", 7: "State", 8: "Local"
})

cls_order  = [3, 4, 7, 6, 8, 5]  # by typical area share, large first
cls_colors = {3: "#558b2f", 4: "#c62828", 5: "#9c27b0",
              6: "#1565c0", 7: "#fbc02d", 8: "#5d4037"}
cls_labels = {3: "NIPF (Family)", 4: "Industrial", 5: "Tribal",
              6: "Federal", 7: "State", 8: "Local"}

# ---------- Figure 1: small-multiples pies ----------------------------
counties_ordered = forest.groupby("county").area_acres.sum().sort_values(
    ascending=False).index.tolist()

n_counties = len(counties_ordered)
ncol = 4
nrow = int(np.ceil(n_counties / ncol))
fig = plt.figure(figsize=(13, 3 * nrow + 1))
gs  = GridSpec(nrow, ncol, hspace=0.4, wspace=0.1)

for i, cty in enumerate(counties_ordered):
    ax = fig.add_subplot(gs[i // ncol, i % ncol])
    sub = forest[forest.county == cty].set_index("hcb_class")
    sub = sub.reindex(cls_order)
    vals = sub.area_acres.fillna(0).values
    if vals.sum() == 0: continue
    colors = [cls_colors[c] for c in cls_order]
    ax.pie(
        vals, labels=None, colors=colors, autopct=None,
        startangle=90, wedgeprops=dict(edgecolor="white", linewidth=1)
    )
    ax.set_title(f"{cty}\n{vals.sum()/1e6:.1f} M ac",
                 fontsize=10, weight="bold")

# Legend at bottom
handles = [plt.Rectangle((0, 0), 1, 1, color=cls_colors[c]) for c in cls_order]
labels  = [cls_labels[c] for c in cls_order]
fig.legend(handles, labels, loc="lower center", ncol=6, frameon=False,
           bbox_to_anchor=(0.5, -0.02), fontsize=10)

fig.suptitle("Maine forest ownership by county (Harris-Caputo-Butler 2025 raster, FIA-plot weighted)",
             fontsize=12, weight="bold", y=0.995)
plt.savefig(OUT / "fig_maine_ownership_pie_by_county.png",
            dpi=180, bbox_inches="tight")
print(f"Wrote {OUT / 'fig_maine_ownership_pie_by_county.png'}")

# ---------- Figure 2: stacked bars by county --------------------------
fig, ax = plt.subplots(figsize=(11, 6))

# Build pivot: rows = county (ordered by total ac), cols = class, vals = share
pivot = forest.pivot_table(index="county", columns="hcb_class",
                            values="area_acres", aggfunc="sum",
                            fill_value=0)
pivot = pivot.reindex(columns=cls_order, fill_value=0)
shares = pivot.div(pivot.sum(axis=1), axis=0) * 100
order_by_industrial = shares[4].sort_values(ascending=False).index
shares = shares.loc[order_by_industrial]

bottoms = np.zeros(len(shares))
for c in cls_order:
    ax.bar(range(len(shares)), shares[c].values, bottom=bottoms,
           label=cls_labels[c], color=cls_colors[c],
           edgecolor="white", linewidth=0.6, width=0.8)
    bottoms += shares[c].values

ax.set_xticks(range(len(shares)))
ax.set_xticklabels(shares.index, rotation=35, ha="right", fontsize=9)
ax.set_ylabel("Share of forest area (%)")
ax.set_title("Maine forest ownership share by county (sorted by industrial share)",
             fontsize=11, weight="bold")
ax.set_ylim(0, 102)
ax.set_yticks(range(0, 101, 20))
ax.grid(axis="y", alpha=0.3)
ax.legend(loc="upper right", fontsize=9, framealpha=0.92)

# Annotate counties with high industrial share
for i, cty in enumerate(shares.index):
    ind = shares.iloc[i, 1]  # column 1 = class 4 = industrial
    if ind > 30:
        ax.text(i, 102, f"{ind:.0f}%", ha="center", fontsize=8,
                color=cls_colors[4], weight="bold")

plt.tight_layout()
plt.savefig(OUT / "fig_maine_ownership_bars.png",
            dpi=200, bbox_inches="tight")
print(f"Wrote {OUT / 'fig_maine_ownership_bars.png'}")

# ---------- Statewide summary table -----------------------------------
state = forest.groupby(["hcb_class", "short_label"]).agg(
    n_plots=("n_plots", "sum"),
    area_acres=("area_acres", "sum")
).reset_index()
state["pct_of_forest"] = (100 * state.area_acres / state.area_acres.sum()).round(1)
state["area_M_acres"] = (state.area_acres / 1e6).round(2)
print("\n=== Maine forest ownership distribution ===")
print(state[["hcb_class", "short_label", "n_plots",
             "area_M_acres", "pct_of_forest"]].to_string(index=False))
state.to_csv(LD / "maine_ownership_statewide_summary.csv", index=False)
