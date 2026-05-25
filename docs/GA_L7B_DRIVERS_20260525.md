# GA RCP85 wear_l7b Bias Drivers: Cohort Decomposition

Date: 2026-05-25
Status: Identifies the cohort that drives the GA RCP85 l7b cycle 4 +41.2 percent overshoot, complementing the May 17 donor pool diagnostic.

## Question

The GA RCP85 wear_l7b cycle 4 (2019) projection overshoots observed AGC by +41.2 percent (256.2 vs 181.5 MMT, an excess of 74.7 MMT). Adding the L3 ecoregion key to GA widens the bias from the p1 baseline of +25 percent. What cohort drives the excess, and why does the ecoregion key make GA worse instead of better as it does for ME?

## Method

Per plot projections from the GA RCP85 wear_l7b production run (job 10310330, n_sims = 25, 177M rows, 8.5 GB RDS) were filtered to cycle 4 (2019) BAU scenario and collapsed to mean projected AGC, basal area, and trees per acre by PLT_CN. Each plot was classified as plantation indicative (FORTYPCD in 141, 142, 161 through 168, the loblolly, slash, longleaf, and southern pine plantation types) or other forest type, and binned into stand age classes of 20 year width. Aggregates were computed within the 105,123 plot record cycle 4 pool, which contains both subject and donor plots routed through the projection engine. Run via SLURM job 10428127 on cpu partition with 400 GB memory and 16 cores; RDS load took 13:39 min, decomposition took under 1 min. Results live at output/ga_l7b_residual_20260524/.

## Top level result

| Plantation class | n plots | mean proj AGC | median STDAGE | share of total proj |
|---|---:|---:|---:|---:|
| plantation indicative | 39,273 | 44,638 | 34 yrs | **42.5 pct** |
| other forest type | 65,850 | 34,633 | 57 yrs | 57.5 pct |

Plantation indicative plots produce 1.29 times the mean projected AGC of other forest types despite being 40 percent younger (median age 34 vs 57). They are 37 percent of the plot count but 42.5 percent of the total projected AGC. The disproportion is the signature of the overshoot.

## Where the excess concentrates: age x cohort cross-tab

Mean projected AGC and share of cycle 4 total by age class and plantation class:

| Age class | other (mean) | other (share) | plantation (mean) | plantation (share) | ratio plant to other |
|---|---:|---:|---:|---:|---:|
| 0-20 | 23,123 | 3.0 pct | 26,833 | 3.3 pct | 1.16x |
| 21-40 | 30,456 | 10.8 pct | **48,883** | **22.5 pct** | **1.61x** |
| 41-60 | 31,709 | 12.9 pct | 47,091 | 10.7 pct | 1.49x |
| 61-80 | 38,276 | 16.7 pct | 44,077 | 4.4 pct | 1.15x |
| 81-100 | 42,094 | 10.6 pct | 39,390 | 1.3 pct | 0.94x |
| 100+ | 43,028 | 3.5 pct | 30,964 | 0.2 pct | 0.72x |

The 21-40 year plantation cohort alone accounts for 22.5 percent of total cycle 4 projected AGC, more than any other single cell in the table. Mean projected AGC for this cell (48,883) is 60 percent higher than the same age class in other forest types (30,456). This is the cohort that drives the +41 percent overshoot.

The pattern reverses past age 80: plantations project lower than other forest types at age 80 and above, consistent with planted pine stands reaching senescence earlier than mixed natural stands. The model captures this biological pattern; the bias is therefore not a uniform model defect but a concentrated overshoot in the 21-40 year plantation cohort.

## Why the L3 ecoregion key amplifies this in GA

The May 17 GA donor pool diagnostic established three relevant facts. First, plantation indicative plots have median STDAGE of 20 years, with 74 percent under age 30 and 95 percent under age 60. Second, 95 percent of plantation indicative plots have sat_age = 1.0, the saturation factor that triggers unattenuated growth in the projection engine. Third, the GA donor pool is regionally homogeneous compared to the heterogeneous ME donor pool. The implication is that adding the L3 ecoregion key to GA matching pulls subjects toward donors within the same Omernik L3 ecoregion, and within that ecoregion the donor composition is dominated by young high productivity plantations whose sat_age is 1.0. The engine then projects those subjects at the full unattenuated growth rate of the plantation cohort. This is the mechanism by which ecoregion matching, which helped ME, hurts GA: in ME it routes subjects to ecologically appropriate slower growing donors, but in GA it routes them to faster growing plantation donors that already dominate the regional pool.

## Comparison to ME

ME L3 stratification narrowed cycle 4 bias by routing subjects to ecologically aligned northern hardwood and spruce fir donors. The ME donor pool is diverse in growth rate composition, so the ecoregion key selects donors with the right growth potential rather than amplifying any single cohort. GA does not have that diversity. The L3 key cannot find a slower growing donor within the ecoregion because all donors within the ecoregion grow at similar rates, dominated by managed pine plantations on the GA piedmont.

This explains the direction reversal between states without needing a state specific tuning parameter. The ecoregion key is direction agnostic; the donor pool composition determines whether the key helps or hurts.

## Implications for the manuscript

This decomposition adds quantitative weight to the donor analog gap conclusion from PRODUCTIVITY_MATCHING_RESULT_20260522.md. The closing story is no longer just "WA has no donor analog" but a more general statement: the CEM matching framework amplifies whatever growth rate asymmetry exists in the regional donor pool. In WA the asymmetry runs against the subjects (donors grow slower than subjects, producing minus 25 percent underprediction with no fix from any matching key). In GA the asymmetry runs with the subjects but in the wrong direction (donors include a high productivity plantation cohort that the L3 key concentrates in subject projections, producing plus 41 percent overprediction). In ME the donor pool is diverse enough that the L3 key selects a growth rate match, producing plus 12 percent. The framework works when the donor pool is diverse and the matching key has discriminating power, and fails in two different directions when either condition is absent.

This is a sharper finding than the original "v3 clean win" framing and is consistent with the existing PRODUCTIVITY_MATCHING_RESULT and CONUS_DONOR_NULL memos. The manuscript Section 3.5 and Discussion should integrate this cohort attribution as the specific GA case study.

## Open question: bias reduction options for GA

The GA overshoot lives in a specific cohort, so a cohort specific correction is feasible. Three options to consider as future work, none built yet:

1. Stratify GA matching by STDAGE class explicitly, forcing the model to match plantation subjects against plantation donors of similar age.
2. Apply a plantation specific sat_age cap below 1.0 for ages under 40, attenuating growth for the cohort that the May 17 diagnostic identified as having no attenuation.
3. Remove plantation indicative donors from the GA donor pool entirely and accept the smaller matched subject pool, similar to the productivity matching approach for WA.

None of these is in scope for the current manuscript. The decomposition documents the bias drivers; the corrections are the next round of work.

## Artifacts

- Cardinal output: `~/fia_cem_projections/output/ga_l7b_residual_20260524/`
- Local mirror: `output/ga_l7b_residual_20260524/`
- Scripts: `scripts/ga_l7b_cohort_analysis.R`, `scripts/submit_ga_l7b_cohort.sh`
- SLURM jobs: 10421015 (OOM at 32 GB), 10428127 (COMPLETED on cpu 400 GB)
- Cohort summary CSV: `output/ga_l7b_residual_20260524/ga_l7b_cohort_proj_summary.csv`
- Age x cohort cross-tab CSV: `output/ga_l7b_residual_20260524/ga_l7b_cohort_proj_age_xstab.csv`
- Top 50 plots by projected AGC: `output/ga_l7b_residual_20260524/ga_l7b_cohort_top50_plots.csv`
