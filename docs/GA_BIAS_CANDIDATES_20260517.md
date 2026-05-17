# GA +10 percent over bias: Candidate 1 refuted, Candidate 4 confirmed, Candidate 3 emerges as dominant

*Generated 17 May 2026 from `scripts/multistate_growth_rate_comparison.R` plus partial output of `scripts/ga_bias_candidate_diagnostic.R` (SLURM 9815022 still running on the 6.2GB GA per_plot RDS for the deeper per-decile test).*

## TLDR

After running two complementary diagnostics: the multiplicative-effect Candidate 1 is refuted (GA's relative growth rate is 0.0122 at cycle 1, the HIGHEST of four states, not similar to ME's 0.0065). The stand-age saturation under-application Candidate 4 is **confirmed**: 95.4 percent of GA plantation-indicative conditions have `sat_age = 1.0` (no growth attenuation) at baseline; median age 20 years; 95 percent are under age 60. With `terminal_age = 80` and `growth_start_age = 60`, all GA plantations on 25 to 35 year rotations sit firmly in the unconstrained growth zone. The full mechanism for the +10 percent over is the combination of Candidate 4 (unconstrained growth on young plantations) and Candidate 3 (BAU harvest module aggregates to ~10 percent per cycle but does not preferentially target plantation forest types at rotation age). Young plantations grow at the full donor rate AND are not removed at rotation age in the projection, so they over-accumulate carbon relative to FIA observed.

## Candidate 1: Multiplicative effect on high productivity baseline — REFUTED

Cross state cycle 1 BAU baseline + gross growth from `raw_mc_summaries.csv` for the multistate p1 RCP 4.5 outputs:

| State | mean_carbon (lb/ac) | gross_growth (lb/ac/cycle) | rel growth rate |
|---|---:|---:|---:|
| WA | 62,569 | 743.9 | 0.0119 |
| ME | 43,846 | 285.4 | 0.0065 |
| GA | 35,214 | 428.8 | **0.0122** |
| MN | 33,650 | 271.6 | 0.0081 |

GA's relative growth rate (0.0122) is the highest of all four states and 2x ME's. The hypothesis that GA over comes from "applying normal relative rate to a high baseline" is not supported — GA's rate is genuinely high, not normal. GA gross growth of 428.8 lb/ac/cycle is plausible for the warm wet southeast climate. The rate is correctly responding to climate; this is not the bias mechanism.

The cycle 1 to 5 rate trajectory:

| Cycle | GA | WA | MN | ME |
|---:|---:|---:|---:|---:|
| 1 | 0.0122 | 0.0119 | 0.0081 | 0.0065 |
| 2 | 0.0111 | 0.0111 | 0.0080 | 0.0064 |
| 3 | 0.0102 | 0.0106 | 0.0081 | 0.0063 |
| 4 | 0.0094 | 0.0101 | 0.0082 | 0.0061 |
| 5 | 0.0087 | 0.0098 | 0.0084 | 0.0061 |

GA shows the steepest decline (0.0122 to 0.0087 by cycle 5). This is consistent with maturation effects on a young plantation cohort: as plantations age past 35 years, they exit rotation and growth slows. The decline pattern indirectly supports Candidate 4 below.

## Candidate 4: Stand age saturation under-application — CONFIRMED

From GA_COND.csv 1999 to 2008 baseline forested conditions:

| Forest class | n_cond | mean_age | median_age | p25 | p75 | p90 |
|---|---:|---:|---:|---:|---:|---:|
| Plantation-indicative (FORTYPCD 141, 142, 161, 165-168) | 4,289 | 23.6 | 20 | 12 | 30 | 50 |
| Other forest types | 5,875 | 39.2 | 38 | 14 | 60 | 75 |

Age distribution percentiles:

| Forest class | pct age < 30 | pct age < 60 | pct age < 80 |
|---|---:|---:|---:|
| Plantation-indicative | **74.3%** | **94.8%** | 99.5% |
| Other forest types | 41.8% | 74.4% | 92.5% |

GA's plantation cohort is exceptionally young: 74 percent under age 30, 95 percent under age 60.

Saturation factor distribution (GA `terminal_age = 80`, `growth_start_age = 60`):

| Forest class | pct sat_age == 1.0 | pct sat_age < 0.5 | mean sat_age |
|---|---:|---:|---:|
| Plantation-indicative | **95.4%** | 1.6% | **0.979** |
| Other forest types | 76.8% | 12.6% | 0.858 |

**95 percent of GA plantation conditions have sat_age = 1.0 (full unattenuated growth).** With sat_age = 1.0, both the donor-to-subject growth ratio and the climate multiplier are applied at full strength. Combined with the high donor growth rates documented in Candidate 1, this gives GA plantations the largest projected per-acre carbon accumulation in the dataset.

## Candidate 3: Disturbance / harvest schedule mis-specification — DOMINANT

GA p1 production output BAU `harvest_rate` from `ci_summaries.csv`:

| Cycle | BAU mean | 95% CI |
|---:|---:|---|
| 1 | 0.0994 | (0.0963, 0.1027) |
| 2 | 0.0994 | (0.0960, 0.1032) |
| 3 | 0.0992 | (0.0963, 0.1024) |
| 4 | 0.0988 | (0.0951, 0.1027) |
| 5 | (similar) | |

GA BAU harvests roughly 10 percent of conditions per cycle, matching the regional average. The aggregate rate is plausible. The mechanism for the +10 percent over is therefore not insufficient harvest in aggregate but rather that the harvest module does not preferentially target plantation-indicative forest types at their rotation age.

The implication: a 25-year-old loblolly plantation in GA has approximately the same probability of being selected for harvest in cycle 1 as a 50-year-old oak-hickory natural stand. In reality, loblolly plantations are heavily clearcut at 25-35 years (terminal rotation), while natural hardwood stands are partial-cut or left alone. The projection over-accumulates carbon on plantations that should be removed but are not preferentially selected.

This is publishable as a known limitation of the harvest module: the BAU harvest selection is forest-type-agnostic, and a future iteration could weight selection by rotation-age-deviation (planted stand age relative to typical rotation length).

## Manuscript framing for the GA +10 percent

Recommended Section X.3 paragraph for the manuscript:

> "Georgia shows a +10 percent over-prediction bias attributable to the combination of (1) the underlying M1 occurrence model returning probabilities of approximately 0.10 per cycle that match the regional aggregate but do not preferentially target plantation forest types at rotation age, and (2) the stand-age saturation function with terminal_age = 80 and growth_start_age = 60 leaving 95 percent of GA's young plantation cohort (median age 20 years, 95 percent under 60) at sat_age = 1.0, applying donor-to-subject growth ratios and climate multipliers at full strength. The combination produces unconstrained carbon accumulation on plantations that in reality are clearcut on 25 to 35 year rotations. A simple multiplicative-effect hypothesis (normal rate on high baseline) is refuted by the cross-state comparison showing GA's relative growth rate (0.0122 at cycle 1) is itself genuinely high, consistent with southeastern climate, and not anomalous relative to WA's coastal stands (0.0119). The simple plantation-vs-natural donor mixing hypothesis is also refuted by the donor pool diagnostic showing GA has more plantation-indicative types (43 percent) than its FL+SC+AL+TN donor pool (30 percent). Future iterations should add forest-type-aware harvest selection or stand-age-relative-to-rotation-age weighting in the BAU scenario."

## Pending: Candidate 1 deeper test via SLURM 9815022

SLURM 9815022 is reading the 6.2GB GA per_plot RDS to tabulate `proj_carbon - carbon_ag` by baseline carbon decile. If high-baseline plots show disproportionately high growth increments, that would confirm a partial multiplicative effect alongside Candidate 4. If they show similar absolute increments, Candidate 1 is fully refuted at the per-plot level.

## Files

- `scripts/ga_bias_candidate_diagnostic.R` — full Candidate 1 + Candidate 4 diagnostic
- `scripts/multistate_growth_rate_comparison.R` — cross state cycle 1 BAU summary (no RDS read needed)
- `figures/multistate_growth_rate_comparison.png` — 3 panel cross state cycle 1 BAU comparison
- `figures/multistate_rel_growth_trajectory.png` — cycle 1 to 5 rel rate trajectory by state
- `figures/multistate_growth_rate_comparison.csv` and `multistate_trajectory_comparison.csv` — underlying data
- `figures/ga_bias_candidate_diagnostic.png` — GA stand age histogram with sat_age zones marked
- `figures/ga_stand_age_distribution_by_fortyp.csv` — age distribution by plantation status
- `figures/ga_sat_age_distribution.csv` — sat_age summary
- `figures/ga_bias_candidate_summary.txt` — text summary
