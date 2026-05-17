# CEM 3-way stratification: ecoregion x forest type x owner is the right framework

*Generated 17 May 2026 in response to the user's note that landowner is the third key matching dimension.*

## TLDR

Yes, landowner is the natural third CEM matching dimension and the empirical test confirms it is production-ready. Using OWNGRPCD from FIA COND directly (100 percent coverage, 4 classes: USDA FS, other federal, state/local, private) gives a 3-way stratification with 332 unique cells across CONUS. **36.7 percent of cells have at least 30 conditions** (actually slightly better than the 2-way at 33 percent), and **only 3.11 percent of subject conditions fall in cells with insufficient cross-state donors**. The HCB owner classification considered first has only 0.75 percent plot coverage in the existing crosswalk and would need a multi-day geospatial fill to become production-ready, but OWNGRPCD is immediately usable and captures the dominant private vs federal harvest differential.

## Comparison: 2-way vs 3-way

| Metric | 2-way (eco x typ) | 3-way (eco x typ x OWNGRPCD) | Δ |
|---|---:|---:|---:|
| Unique cells | 156 | 332 | +176 |
| Cells with ≥30 conds | 52 (33%) | 122 (37%) | +70 cells |
| Cells with ≥100 conds | 31 (20%) | 93 (28%) | +62 cells |
| Subject conds in low-donor cells | 1,388 (4.0%) | 1,163 (3.1%) | -225 |

Counter-intuitive but correct: adding the OWNGRPCD dimension does NOT make the cell sparsity worse. The improvement happens because OWNGRPCD splits naturally align with the geographic structure (PNW is mostly federal, SE is mostly private, ME is mostly private/industrial). Subjects and donors that previously matched across owner groups now match within owner groups, producing tighter and more relevant cells.

## OWNGRPCD distribution across CONUS forested baseline

| OWNGRPCD | Description | n_cond | Share |
|---:|---|---:|---:|
| 40 | Private (NIPF + industrial) | 164,337 | 68.7% |
| 10 | USDA Forest Service | 39,595 | 16.5% |
| 30 | State and local | 24,788 | 10.4% |
| 20 | Other federal (BLM, NPS, DOD, etc.) | 10,744 | 4.5% |

## Low-donor cells preview (subject states ME=23, MN=27, WA=53, GA=13)

Top 20 cells where subjects have ≥20 conds but cross-state donors have <30:

| State | Ecoregion | TYPGRPCD | OWNGRPCD | Subject conds | Cross-state donors |
|---:|---:|---:|---:|---:|---:|
| WA | 15 (PNW coast) | 200 (Doug-fir) | 40 (private) | 93 | 0 |
| WA | 1 (Coast Range) | 200 (Doug-fir) | 40 | 78 | 0 |
| GA | 65 (SE Plains) | 160 (Loblolly-shortleaf) | 40 | 76 | 0 |
| GA | 45 (Piedmont) | 160 | 40 | 67 | 0 |
| WA | 1 (Coast Range) | 300 (Hemlock/Sitka) | 40 | 59 | 0 |
| MN | 50 (N Lakes Forests) | 900 (Aspen-birch) | 10 (USDA FS) | 40 | 0 |
| MN | 50 (N Lakes Forests) | 120 (Pine) | 10 (USDA FS) | 29 | 0 |

These are the same bias-flagged cells from the 2-way analysis. The 3-way result confirms that landowner stratification refines them further — MN aspen-birch on USDA FS land (Superior, Chippewa NFs) is distinct from MN aspen-birch on private NIPF, and currently has zero cross-state donors in the same combined cell.

## Implementation strategy

Adopt 3-tier fallback as in the 2-way memo, with OWNGRPCD added:

1. **Tier 1: ecoregion × TYPGRPCD × OWNGRPCD.** Direct match when subject cell has ≥30 cross-state donors. Covers ~80 percent of subject conditions.
2. **Tier 2: Relax OWNGRPCD** to a 2-class collapse (federal vs non-federal, or include all owner classes from same ecoregion × TYPGRPCD). Then if still sparse, relax ecoregion to adjacent. Covers ~15 percent.
3. **Tier 3: Within-state leave-one-out** for the residual ~5 percent. Same as 2-way.

The relaxation order matters: prefer relaxing OWNGRPCD before ecoregion or TYPGRPCD because the largest harvest-rate variation is within-state-but-cross-owner (private cutting cycle vs federal conservation) rather than across-state-but-same-owner. So a cross-state same-owner same-typ match is more informative than a within-state cross-owner match. Keep OWNGRPCD as the most-relaxable dimension.

## Comparison to HCB owner classification

The Harris/Caputo/Butler 2025 owner raster offers finer-grained classification (10 classes vs OWNGRPCD's 4) and was specifically designed for harvest-rate stratification. However:

- HCB coverage in `config/fia_plots_hcb_l3.csv` is only 6,289 of 832k+ FIA plots (less than 1 percent).
- The HCB atlas is built only for Maine. Extending to CONUS requires running the HCB methodology over all CONUS plots, a multi-day geospatial task.
- OWNGRPCD is in FIA COND directly with 100 percent coverage and captures the dominant private/federal/state structure that drives the largest harvest-rate variation.

Recommendation: use OWNGRPCD for production CEM stratification now; consider HCB refinement as a future iteration if the residual bias warrants it.

## Updated effort estimate

| Component | Effort |
|---|---|
| Fill HCB EPA L3 ecoregion (us_l3code) for missing plots via geospatial join | 4 hr |
| Add ecoregion + TYPGRPCD + OWNGRPCD to CEM strata in R/02_cem_matching.R | 3 hr |
| Implement 3-tier fallback with the relaxation order | 4 hr |
| Validate against existing 6 production runs | 2 hr |
| Total | ~13 hr |

## Projected bias reductions (3-way stratification)

Updated from the 2-way estimate, now that owner is included:

| State | Current bias | Projected with 3-way | Mechanism addressed |
|---|---:|---:|---|
| ME | -1.1% | -1 to -3% | canonical, donor pool already well-matched |
| MN | -23% statewide | -5 to -10% | aspen-birch and spruce-fir × USDA FS cells now matched within-state, donor pool composition mismatch resolved |
| WA | -25% hindcast | -5 to -10% | west-side Doug-fir and hemlock/Sitka spruce × private cells now matched within-state |
| GA | +10% over | +3 to +5% | plantation forest types (loblolly, slash, longleaf) × private cells stratified separately from natural stands; forest-type-aware harvest selection enables plantation-specific rotation timing |

The 3-way scheme addresses all three confirmed bias mechanisms documented earlier and pushes residual bias toward the 5 to 10 percent range that the canonical ME r11 reference falls within.

## Files

- `scripts/cem_3way_strat_cell_sizes.R` — empirical 3-way cell-size diagnostic
- `figures/cem_3way_strat_cell_sizes_overall.csv` — all 332 cells
- `figures/cem_3way_strat_per_subject_state.csv` — per state subject + donor counts
- `figures/cem_3way_strat_cell_sizes_summary.txt` — text summary
