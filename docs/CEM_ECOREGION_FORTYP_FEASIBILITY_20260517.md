# CEM stratification with both ecoregion and forest type: feasible but needs cell-collapse fallback

*Generated 17 May 2026 in response to the methodological question: can the CEM matching incorporate both ecoregion AND forest type group as covariates simultaneously?*

## Short answer

**Yes, and it is the right direction.** Both ecoregion and forest type are standard CEM covariates and using them together addresses the shared mechanism behind the WA -25 percent and MN -23 percent biases (geographic + species composition donor pool mismatch). It also enables the forest-type-aware harvest selection that would address the GA +10 percent bias. The cross-stratification is what the bias documentation has been pointing toward.

**Empirical caveat:** at EPA L3 ecoregion granularity, 4 percent of subject conditions in the multistate p1 set (1,388 of 37,337) fall into cells with zero cross-state donors. The matching would need a cell-collapse fallback (within-state donors or relaxed ecoregion/typgrp) for those cells.

## Empirical cell-size test (17 May 2026, SLURM 9854516)

Built from full CONUS ENTIRE_COND.csv (239,464 forested baseline conditions) joined to the HCB EPA L3 ecoregion crosswalk (us_l3code column). Cross-tabulated to (ecoregion, TYPGRPCD) cells.

| Metric | Value |
|---|---:|
| Unique EPA L3 ecoregions in coverage | 24 |
| Unique TYPGRPCDs | 32 |
| Unique cells observed | 156 |
| Cells with at least 30 conds | 52 (33%) |
| Cells with at least 100 conds | 31 (20%) |
| Cells with at least 500 conds | 25 (16%) |

The cell-size distribution is heavily right skewed: median cell size 7, 75th percentile 57.5, max 67,108. About a third of cells have enough conditions to support standard CEM matching directly.

## Subject cells with no cross-state donors

For each subject state in the multistate p1 set (ME, MN, WA, GA), tabulated the ecoregion × TYPGRPCD cells where the subject has at least 20 conditions but the donor pool (other states in the same cell) has fewer than 30. The diagnostic identified 28 such cells, covering 1,388 of 37,337 subject conditions (3.72 percent of total).

The cells exactly match the bias mechanism story:

| Subject state | Ecoregion | TYPGRPCD | Subject conds | Cross-state donor conds |
|---|---:|---:|---:|---:|
| WA | 15 (PNW coast) | 200 (Doug-fir) | 111 | 0 |
| WA | 1 (Coast Range) | 200 (Doug-fir) | 97 | 0 |
| WA | 1 (Coast Range) | 300 (Hemlock/Sitka) | 82 | 0 |
| GA | 45 (Piedmont) | 160 (Loblolly-shortleaf) | 78 | 0 |
| GA | 65 (Southeast Plains) | 160 (Loblolly-shortleaf) | 77 | 0 |
| MN | 50 (Northern Lakes Forests) | 900 (Aspen-birch) | 47 | 0 |
| MN | 50 (Northern Lakes Forests) | 120 (White-red-jack pine) | 30 | 0 |

These cells are exactly what the bias diagnostics flagged: WA west-side Doug-fir and hemlock/Sitka, MN northern boreal aspen-birch, GA Piedmont loblolly. The ecoregion × FORTYPCD scheme correctly identifies the donor pool gap.

## Coverage gap in HCB L3 crosswalk

The HCB EPA L3 crosswalk at `config/fia_plots_hcb_l3.csv` covers 104,628 plots, but the full CONUS forested baseline cohort is 239,464 conditions. About 56 percent of plots have NA `us_l3code` after the join. The diagnostic still ran by treating those plots' ecoregion as "UNKNOWN_ECOREGION" (a 24th ecoregion category), but a production CEM implementation would need to fill in L3 attributions for the missing 134,836 plots first.

## Recommended implementation

Three-tier matching fallback to handle the cell sparsity:

1. **Tier 1: ecoregion × TYPGRPCD.** Use when subject cell has at least 30 cross-state donor conditions. Covers ~85 percent of subject conditions.

2. **Tier 2: ecoregion only OR TYPGRPCD only.** When Tier 1 cell is sparse, relax one dimension. Typically prefer keeping TYPGRPCD (species composition is more determinative of growth than geography within a region) and relax to adjacent ecoregions. Covers ~10 percent more.

3. **Tier 3: within-state leave-one-out.** When Tiers 1 and 2 are sparse, use within-state donors with leave-one-out matching to avoid leakage. Covers the residual ~4 percent (the bias-flagged cells like WA west-side Doug-fir).

This is the methodologically clean direction the diagnostics have been pointing toward, and the empirical cell sizes confirm it is feasible.

## Effort to implement

| Component | Effort |
|---|---|
| Fill in HCB L3 for 135k missing plots (geospatial join) | 4 hr |
| Add ecoregion + TYPGRPCD to CEM matching strata in `R/02_cem_matching.R` | 2 hr |
| Implement three-tier fallback | 4 hr |
| Validate against existing 6 production runs (ME, MN, WA, GA both RCPs) | 2 hr |
| Total | ~12 hr |

## What this would change for the manuscript

If this lands and the production p1 set is rerun with stratified matching:

- WA bias should drop from -25 percent toward -10 percent or better (donor pool no longer dominated by interior pines)
- MN bias should drop from -5.7 percent hindcast / -23 percent statewide volume toward -5 percent statewide (donor pool finally captures boreal aspen-birch and spruce-fir)
- GA bias should drop from +10 percent toward +3 to +5 percent (plantation forest types stratified, harvest selection forest-type-aware)
- ME bias unchanged (canonical reference, donor pool already well-matched)

The manuscript would gain a methodology section showing the bias reduction is principled and reproducible. The remaining residual biases (5 to 10 percent) would be attributable to climate response gating, owner downscale, and remaining model components.

## Files

- `scripts/cem_ecoregion_fortyp_cell_sizes.R` — empirical cell-size diagnostic
- `figures/cem_strat_cell_sizes_overall.csv` — all 156 ecoregion × TYPGRPCD cells with counts
- `figures/cem_strat_per_subject_state.csv` — per-state subject cell counts
- `figures/cem_strat_cell_sizes_summary.txt` — text summary
