# GA donor pool composition diagnostic: refutes plantation/natural donor mixing as the dominant +10 percent over bias mechanism

*Generated 17 May 2026 from `scripts/ga_donor_pool_diagnostic.R` run on Cardinal.*

## TLDR

The original hypothesis in `BIAS_DOCUMENTATION_20260515.md` attributed the GA +10 percent over bias to "CEM matches a natural stand in GA to a managed plantation donor, the projection inherits the plantation's higher initial productivity." The diagnostic refutes this directional claim. GA's own subject pool is 43 percent plantation-indicative pine forest types (FORTYPCD 141, 142, 161, 165 to 168); the donor pool (FL, SC, TN, AL with NC missing from Cardinal data) is only 30 percent plantation-indicative. **GA has more plantation types than its donor pool, not less.** The simple "natural GA matched to plantation donor" pathway is therefore not the dominant mechanism.

## Method

Source: FIA COND tables at `~/fia_data/<STATE>_COND.csv`. The Cardinal extracts for FL, SC, AL, TN lack the STDORGCD column entirely (abbreviated COND schema for those states); only GA has STDORGCD populated. Pivoted from a direct STDORGCD comparison to a FORTYPCD-based plantation proxy.

Plantation-indicative FORTYPCD set: 141 (longleaf/slash), 142 (slash pine), 161 (loblolly pine), 165 (longleaf pine), 166 (longleaf/loblolly), 167 (loblolly/shortleaf), 168 (shortleaf/scrub oak). These are the FIA forest types most often associated with intensively managed pine plantations in the southeast.

Filter: COND_STATUS_CD == 1 (forested), INVYR in 1999-2008, valid FORTYPCD. GA: 10,317 conditions. Donor pool: 20,559 conditions across FL + SC + TN + AL.

## Headline finding

| Plant origin proxy | GA share | Donor share | Gap (GA - donor) |
|---|---:|---:|---:|
| Pine plantation indicative | 42.9% | 30.1% | **+12.8 pp** |
| Other forest types | 57.1% | 69.9% | -12.8 pp |

GA's own subject pool is substantially more plantation-heavy than its donor pool. The mechanism is the inverse of what the original hypothesis described.

GA subject STDORGCD distribution standalone (when the column is populated for GA only):

| STDORGCD | Description | Share of GA |
|---:|---|---:|
| 0 | Natural origin | 69.1% |
| 1 | Planted | 30.9% |

So roughly a third of GA conditions are planted by direct STDORGCD evidence; the FORTYPCD proxy is broader and captures plantation-indicative types regardless of explicit STDORGCD value.

## What is the actual GA +10 percent bias mechanism then?

The data refute the simple plantation donor mixing pathway. Candidate alternative mechanisms in order of plausibility:

1. **Growth ratio multiplicative effect on GA's high baseline.** CEM matching applies donor growth ratios `(T2 / T1)` to subject baseline. If donor pool baseline is lower (cooler southern states like TN, less intensive AL) and growth ratios are computed in donor-baseline-relative terms, applying those ratios to GA's higher productivity baseline can over-predict absolute growth even when relative growth is similar.

2. **Carbon-to-volume ratio over-estimation in plantation types.** The v4 productivity multiplier (`config/cem_productivity_multipliers_v4.csv`) may apply higher per-cuft carbon factors to plantation types that don't match GA's actual plot-level branch and bark fraction.

3. **Disturbance schedule mis-specification.** GA's state_constants.csv settings (wildfire baseline, terminal age) may underestimate harvest and disturbance frequency on GA plantations, allowing the projection to accumulate growth that real GA stands lose to harvest.

4. **Stand age distribution.** GA plantations are often on 25-35 year rotations; the projection may not be applying age-class saturation (`sat_for_age`) aggressively enough for these young intensively managed stands.

## Manuscript implication

Update `BIAS_DOCUMENTATION_20260515.md` to remove the simple "plantation donor mixing" attribution and replace with "candidate mechanisms under investigation: growth-ratio multiplicative effect on high-productivity GA baseline, carbon to volume ratio over-prediction in plantation types, disturbance schedule mis-specification, and stand age distribution effects. The simple plantation/natural donor pool mixing hypothesis was refuted by the 17 May 2026 GA donor pool diagnostic showing GA has more plantation-indicative types (43 percent) than its donor pool (30 percent)."

## Cardinal data caveat

NC, FL, SC, TN, AL COND files on Cardinal use an abbreviated schema without STDORGCD or CONDPROP_UNADJ. The Lake States donor cohort for MN (ND, SD, IA, WI, MI, IL) is missing entirely from Cardinal. Comprehensive donor pool diagnostics for all states require pulling full COND extracts from the FIA DataMart.

## Files

- `scripts/ga_donor_pool_diagnostic.R` — analysis script with STDORGCD + FORTYPCD plantation proxy
- `figures/ga_donor_pool_diagnostic.png` — STDORGCD comparison bar
- `figures/ga_donor_pool_stdorgcd_comparison.csv` — STDORGCD shares (GA only, donors NA)
- `figures/ga_donor_pool_plantation_proxy.csv` — FORTYPCD plantation indicative comparison
- `figures/ga_donor_per_state_stdorgcd.csv` — per donor state STDORGCD column availability
- `figures/ga_donor_pool_diagnostic_summary.txt` — text summary
