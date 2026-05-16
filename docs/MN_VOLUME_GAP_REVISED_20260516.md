# MN volume gap: DESIGNCD hypothesis refuted; revised investigation needed

*Generated 16 May 2026 after SLURM job 9676388 (MN 2004 baseline diagnostic) completed and the comparison script `scripts/compare_mn_baselines.R` ran on Cardinal.*

## TLDR

The MN 2004 baseline diagnostic produces 21.8 Bcuft statewide volume — essentially identical to the MN p1 1999 baseline result of 21.6 Bcuft. Both sit at 77 to 78 percent of EVALIDator's 28 Bcuft target. **The DESIGNCD periodic plot exclusion is NOT the dominant cause of the -23 percent undercount.** The earlier `MN_VOLUME_GAP_ROOT_CAUSE_20260516.md` analysis attributed the gap to a baseline-year mismatch with MN's annualized FIA inventory start (2004); the diagnostic refutes this attribution.

## What the diagnostic showed

| Run | Baseline year | Year_proj at cycle 1 | Per acre vol | Statewide vol | Pct of EVALIDator |
|---|---:|---:|---:|---:|---:|
| MN p1 | 1999 | 2004 | 1,241 cuft/ac | 21.6 Bcuft | 77% |
| MN diagnostic | 2004 | 2009 | 1,250 cuft/ac | 21.8 Bcuft | 78% |
| EVALIDator target | n/a | n/a | n/a | ~28 Bcuft | 100% |

The two runs differ by less than 1 percent. If the DESIGNCD periodic plot filter were the dominant driver, shifting the baseline to 2004 (when the annualized inventory begins) should have produced a substantially higher per acre and statewide value. It did not.

## Why my earlier hypothesis was wrong

I assumed the DESIGNCD == 1 filter truncated the MN baseline window from 10 years (1999-2008) to 5 years (2004-2008) and biased toward younger stands. The diagnostic shows that even with the baseline window properly aligned to 2004-2009 (no truncation), the per acre volume is the same. This means the subject pool composition that drives the projection is essentially unchanged between the two baseline windows.

Two reasons this might be the case:

1. **MN annualized inventory plot grid is dense enough that the 5 year window 2004-2008 captures most of the represenative forest type variation.** The "missing" periodic plots from 1995-2003 may have been at similar locations and species compositions, just with a different inventory design label.

2. **CEM matching draws from a CONUS donor pool and is not strongly sensitive to the subject pool composition for state level totals.** The total is more sensitive to the donor pool growth trajectories than to which subject plots got included.

## What the actual cause might be

Four candidate mechanisms remain in play, none of which is the DESIGNCD filter:

1. **Lake States donor pool composition.** MN uses ND, SD, IA, WI, MI, IL as donors. The Lake States donor cohort is dominated by managed northern hardwood and aspen-birch stands at lower per acre productivity than MN's actual mix of boreal mixed forest plus heavy aspen. If donor productivity is systematically lower than subject expectation, the projection will trend low.

2. **HCB owner downscale at 74 percent agreement.** The Harris, Caputo, Butler 2025 ownership raster has 74 percent agreement with FIA OWNGRPCD for MN, leaving 26 percent on default multipliers. If the default behaves as more conservative than the actual MN private (NIPF) harvest pattern, the projection over suppresses harvest, leading to slower stand turnover and lower per acre values over time. But this should affect harvest scenarios more than BAU.

3. **MN climate response gating.** `--use_decoupled_climate` is not active for non Maine states because ClimateNA is blocked. The single multiplier climate response may not capture MN cooler climate and shorter growing season correctly.

4. **State_constants.csv MN parameters.** MN row has wildfire baseline 0.010 per cycle (2x Maine), terminal age 110, partial spruce budworm relevance. If any of these are mis-specified relative to actual MN forest behavior, the projection will diverge from observed.

## Recommended next investigation paths

In order of effort:

1. **Per-plot residual analysis.** Compare projection per-plot proj_volcfnet against FIA observed VOLCFNET for those same plots. Identifies which forest types or geographic regions drive the gap. ~2 hour analytical task using existing per_plot RDS outputs.

2. **Donor pool composition audit.** Tabulate MN subject plots' forest type distribution vs the Lake States donor pool's forest type distribution. If the donor pool over-represents lower-productivity types, that's the mechanism. ~3 hour task.

3. **MN-only Maine donor injection.** Run MN with an expanded donor pool including ME and the Northeast cohort (ND, SD, IA, WI, MI, IL, ME, NH, VT, MA). If statewide volume rises toward 28 Bcuft, donor pool composition is confirmed. One production rerun.

4. **State_constants.csv sensitivity.** Vary MN parameters one at a time (wildfire baseline, terminal age, SDImax) and observe per acre response. Identifies which constants drive the bias. Multiple smoke runs.

## Manuscript implication

Update `BIAS_DOCUMENTATION_20260515.md` to remove the DESIGNCD attribution for MN and replace with "structural -23 percent under EVALIDator under both 1999 and 2004 baselines; root cause not yet identified; candidate mechanisms include Lake States donor pool composition, HCB owner downscale, climate response gating, and state_constants calibration."

This is a more honest framing than the DESIGNCD attribution, and it leaves a clear remediation path for a future paper or supplement once the root cause is identified.

## Status

- MN 2004 baseline diagnostic complete (`MN_20260516_rcp45_wear_p1_2004base`)
- Comparison script ran on Cardinal; figures and CSVs at `figures/mn_baseline_comparison.png` and `mn_baseline_comparison.csv`
- DESIGNCD hypothesis refuted
- True root cause requires further investigation in a future session
- The prior `MN_VOLUME_GAP_ROOT_CAUSE_20260516.md` should be considered superseded by this revision

## Cross reference

- `docs/MN_VOLUME_GAP_ROOT_CAUSE_20260516.md` (now superseded; the DESIGNCD attribution was wrong)
- `docs/BIAS_DOCUMENTATION_20260515.md` (manuscript bias note; needs update)
- `figures/mn_baseline_comparison.png` (the diagnostic comparison figure)
- `figures/mn_baseline_comparison.csv` (per cycle delta data)
- `osc/submit_mn_2004baseline_diagnostic.sh` (the submit script used)
- `scripts/compare_mn_baselines.R` (the comparison script)
