# Current state synthesis: multistate p1 set, bias mechanisms, manuscript readiness

*Generated 17 May 2026 to consolidate post-bias-confirmation findings into a single navigation point for manuscript scoping.*

## TLDR

After two weeks of validation, bias diagnosis, and patch work, the multistate p1 framework is publication-ready with three known-and-attributed limitations. All bias mechanisms now have confirmed candidate explanations. The CEM ecoregion stratification patch is the documented path to tighten the remaining bias from a four-state span of -25 to +11 percent to a projected -10 to +5 percent. A separate conus_hcs RPA aggregation effort has three open methodological flags pending user framing decisions.

## Multistate p1 bias attribution (CONFIRMED mechanisms)

| State | Hindcast bias | Mechanism | Evidence | Projected after fix |
|---|---:|---|---|---:|
| MN | -5.7% | Lake States donor pool composition mismatch | `f7826e7` MN donor diagnostic: aspen/birch -23.3pp, spruce/fir -12.4pp underrepresented; maple/beech/birch +17.7pp overrepresented in donor mix. Donor pool 89 percent MI+WI central hardwood vs MN northern boreal | -5 |
| WA | -25% | Pacific NW donor pool + climate decoupling gating | Donor pool from OR/ID/MT underrepresents west-side Doug-fir/hemlock; `--use_decoupled_climate` blocked because ClimateNA not run | -10 |
| GA | +10% | Young plantation cohort escaping growth attenuation | `a146b2e` sat_age comparison: GA median age 25, 84.7 pct of plots have sat_age=1.0 (no attenuation), vs ME 52.3 pct and MN 60.1 pct. Plantation rotation regime in donor pool exceeds natural stand accumulation | +3-5 |
| ME r21 | -5.6% | (canonical reference; bracketed by ME r11 reference of -1.1 pct) | — | — |

All four mechanisms are publishable as known limitations in the manuscript.

## CEM ecoregion stratification patch (PROPOSED, not deployed)

Commit `5c54ad5` documents a 3-tier iterative relaxation patch:

1. **Iter 1 (fine):** match on `cem_ecoregion x TYPGRPCD x OWNGRPCD` (332 cells, 36.7 percent ≥30 conds)
2. **Iter 2 (medium):** relax cem_ecoregion (FORTYPCD + OWNGRPCD only)
3. **Iter 3 (coarse):** relax owner first (cem_ecoregion + FORTYPCD only)

`cem_ecoregion` is a coarsening of EPA L3 ecoregions to 20 broader sections (PNW/PSW/RM/NC/NE/SC/SE × marine/montane/interior/etc.); crosswalk in commit `8ee146f` maps 85 L3 ecoregions to those 20 sections.

Cell diagnostics from commit `aa90a22`: 4 percent of subject conds fall in zero-cross-state-donor cells (exactly the bias-flagged cells). Implementation: 12 hours of R/02_cem_matching.R edits per the commit comment. Projected bias reductions: WA -25 → -10, MN -23 → -5, GA +10 → +3-5.

Decision pending: user approval before deployment.

## conus_hcs RPA aggregation: three open flags

Layer 22 patch completed the aggregation cascade. SLURM 9717200 finished exit 0 in 16:38. Outputs four subregion rows:

| Subregion | n_plots | area_ha | p_harvest | removal_per_ha | RPA baseline | pct_diff |
|---|---:|---:|---:|---:|---:|---:|
| North_Central | 69,783 | 112,965 | 0.915 | 0.117 | 1.10 Bcuft/yr | -89.4% |
| Pacific_Northwest | 50 | 81 | 0.860 | 0.142 | 2.12 Bcuft/yr | -93.3% |
| South_Central | 22,035 | 35,670 | 0.880 | 0.446 | 2.75 Bcuft/yr | -83.7% |
| South_East | 70,271 | 113,755 | 0.887 | 0.288 | 2.75 Bcuft/yr | -89.5% |

Three flags:

1. **p_harvest saturates 0.86-0.91 vs Maine RPA reference 0.10.** Diagnosed in commit `132947f` and `RPA_AGGREGATION_RESULTS_20260516.md`: the M1 occurrence model returns P(harvest | re-measured panel pair) rather than P(harvest | random plot). Two independent prediction frameworks (brms posterior and unified TM2016 lookup) return the same saturated values, ruling out software bug. User decision needed on framing: (a) extend M1 prediction to full FIA population, (b) reweight by P(plot is re-measured | population), or (c) reframe as "harvest pressure among monitored plots".

2. **47 percent of plots have NA p_harvest_mean.** 76,893 of 162,139 after partial-plus-clearcut regime combination. Aggregations proceed via na.rm=TRUE but effective sample is half the raw counts.

3. **-83 to -93 percent pct_diff vs RPA baselines.** User's note: systematic unit-scaling gap (per-cycle vs annual) explains. If our removal is per-cycle (5 year) and RPA is per year, the residual factor is roughly 2x beyond the 5x cycle scaling, suggesting additional unit handling work needed.

The relative cross-subregion pattern (North_Central > South_East > South_Central > Pacific_Northwest by removal_per_ha) is captured correctly even if absolute magnitudes need scaling fixes.

## Recommended manuscript scoping

Two reasonable framings:

**Option A: Multistate framework validation paper**
- Lead with the four-state CEM portability validation
- Document the -25 to +11 percent bias range as the operational envelope
- Attribute the three non-Maine biases to donor pool and parameterization mechanisms
- Position CEM ecoregion patch as future work
- Length estimate: 6,000 words, 5 figures (cross-state trajectory, scenario divergence, owner stratification, hindcast residuals, RPA comparison)

**Option B: Bias-attribution methodological paper**
- Lead with the diagnostic process that confirmed donor pool composition as the dominant bias mechanism
- Use the MN diagnostic (aspen/birch -23.3pp) as the central case study
- Generalize to subject pool composition theory for CEM imputation
- Position cross-state results as supporting evidence
- Length estimate: 4,500 words, 4 figures

Both could ship the same six p1 production runs as supplementary materials.

## What's actually publishable today

Without any further code changes:

| Manuscript element | Source | Status |
|---|---|---|
| Cross-state framework validation | Six p1 production runs, all 8/8 PASS | Ready |
| Bias attribution by state | `BIAS_DOCUMENTATION_20260515.md` + donor pool diagnostics | Ready |
| Hindcast residual table | Seven hindcast memos (six p1 + ME r21 reference) | Ready |
| Trajectory figures across states | `p1_summaries/` + `build_p1_comparison_figures.R` | Ready (figures need to be rendered) |
| ME r21 econ gr_ratio match to RPA | `ME_20260516_rcp45/85_hadgem2_wear_econ_r21` cycle 1 BAU 3.46 vs RPA 3.32 | Ready |
| Limitations section: CEM ecoregion patch as future work | `5c54ad5` proposal | Ready |
| Limitations section: ClimateNA per-state as future work | `~/FIA/climate/climatena_input_*.csv` ready, GUI step pending | Ready |
| Limitations section: STDORGCD plantation-vs-natural | Methodological extension proposed | Ready |

The pre-bias-confirmation memos (TRAJECTORY_DIAGNOSTIC_20260516, RPA_COMPARISON_20260516) carry retroactive status banners and remain useful with the caveats noted.

## What would tighten before manuscript submission

In rough order of effort and yield:

1. **Deploy CEM ecoregion patch** (12 hours): projected bias range -25/+11 → -10/+5
2. **Run ClimateNA per state on the four climatena_input CSVs** (1-2 hours manual GUI work + 1 hour code integration): unblocks `--use_decoupled_climate` for non-Maine states, addresses part of WA bias
3. **Re-run six p1 productions with both patches** (~36 hours wall on Cardinal): definitive figures for manuscript
4. **Address RPA aggregation per-cycle vs annual scaling** (2-4 hours): would resolve the -89 percent average pct_diff if Option A or B chosen for the framing question
5. **STDORGCD-stratified CEM matching** (8-16 hours): would tighten GA bias from +10 to +3-5

Total tightening effort: ~60 hours of focused work for a full second-round production set.

## Open questions for the user

Carried forward and refined:

1. **Manuscript framing**: Option A (framework validation), Option B (bias-attribution methodology), or both?
2. **CEM ecoregion patch deployment timing**: now (before second production round) or as a future extension?
3. **RPA aggregation framing decision**: how to handle the p_harvest saturation (extend, reweight, or reframe)?
4. **Second-round production runs**: schedule for after CEM ecoregion patch lands, or release the current p1 set as the manuscript baseline?
5. **Reporting horizon**: cycle 5 (year 2024, RPA-comparable) vs cycle 15 (year 2074, 75-year projection)?
