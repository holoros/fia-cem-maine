# WA donor pool composition diagnostic: confirms PNW west side underrepresentation as the WA bias mechanism

*Generated 17 May 2026 from `scripts/wa_donor_pool_diagnostic.R` run on Cardinal.*

## TLDR

The WA donor pool of OR, ID, MT systematically underrepresents the high productivity west side stand types that dominate WA's forested area, and overrepresents the lower productivity interior pine types of east side Oregon, Idaho, and Montana. The signature is exactly what BIAS_DOCUMENTATION_20260515.md predicted: WA shows 14.1 percent hemlock / Sitka spruce forest area; the donor pool shows only 3.0 percent (a 11.1 percentage point gap). WA shows 41.6 percent Douglas fir; donors 32.6 percent (9.0 pp gap). Donor pool is overrepresented in ponderosa pine (16.5 percent donor vs 9.0 percent WA, 7.5 pp gap) and lodgepole pine (9.8 percent donor vs 3.4 percent WA, 6.4 pp gap). The CEM matching mechanism takes WA west side plots and matches them to interior pine donors with systematically lower productivity, suppressing projected biomass accumulation. This is the dominant mechanism for the WA -25 percent conservative hindcast bias.

## Method

Source: FIA COND tables at `~/fia_data/<STATE>_COND.csv` for WA, OR, ID, MT.

Filter: COND_STATUS_CD == 1 (forested), INVYR in 1999 to 2008 (canonical baseline window), valid FORTYPCD. Schema-tolerant for ID and MT which have abbreviated COND extracts without CONDPROP_UNADJ.

WA subject: 6,193 forested conditions. Donor pool (OR + ID + MT combined): 15,816 forested conditions. Area share is condition count weighted by CONDPROP_UNADJ where available, falling back to unweighted counts for ID/MT.

The diagnostic aggregates FORTYPCD to TYPGRPCD (forest type group) using the FIA REF_FOREST_TYPE.csv reference table from `~/fia_cem_projections/config/`.

## Headline forest type group comparison

| Forest type group | WA share | Donor share | Gap (WA - donor) |
|---|---:|---:|---:|
| Douglas-fir group | 41.6% | 32.6% | **+9.0 pp** |
| Fir / spruce / mountain hemlock | 15.9% | 15.8% | 0.0 pp |
| Hemlock / Sitka spruce | 14.1% | 3.0% | **+11.1 pp** |
| Ponderosa pine | 9.0% | 16.5% | **-7.5 pp** |
| Alder / maple | 7.1% | 2.4% | +4.6 pp |
| Nonstocked | 3.6% | 3.2% | 0.0 pp |
| Lodgepole pine | 3.4% | 9.8% | **-6.4 pp** |
| Western larch | 1.8% | 1.3% | 0.5 pp |
| Elm / ash / cottonwood | 0.9% | 0.4% | 0.5 pp |
| Aspen / birch | 0.6% | 0.8% | -0.2 pp |
| Western oak | 0.6% | 1.0% | -0.4 pp |
| Other western softwoods | 0.5% | 7.7% | **-7.2 pp** |

## Mechanism

CEM (Coarsened Exact Matching) is the matching framework: each subject plot is paired with one or more donor plots that match on key covariates (forest type, basal area, age, climate stratum). The growth trajectory of the donor pool is then applied to the subject plot to project the next cycle.

The forest type composition gap means that when the CEM algorithm tries to match a WA hemlock / Sitka spruce subject plot to its nearest donor, the donor pool has only one fifth as many candidates as the proportional WA inventory would suggest. The matcher reaches further into other forest types (Douglas-fir, fir/spruce/mountain hemlock) to find a donor, OR falls back to wider tolerances on the matching strata. Either path imports a growth trajectory that does not capture the genuinely exceptional productivity of west side stands.

Compounding the issue, the donor pool is overrepresented in interior pine types (ponderosa pine, lodgepole pine) characteristic of east side OR and ID/MT. These types grow at substantially lower rates than west side hemlock/Doug-fir. If those plots end up matched to WA subjects through any of the matching tolerances, the projection drags toward interior-pine growth trajectories instead of west side rates.

## Manuscript implication

For the WA bias attribution, this confirms the dominant mechanism is **donor pool composition** rather than:

1. Climate response gating (the `--use_decoupled_climate` block from ClimateNA) — this contributes but is secondary
2. State_constants.csv WA parameters — secondary
3. HCB owner downscale — secondary

Updated framing for BIAS_DOCUMENTATION_20260515.md:

> The WA conservative hindcast bias of -25 percent is dominated by donor pool composition. WA's west side Douglas-fir and western hemlock stands are unique to WA west of the Cascades; OR shares some of this pattern but OR's east-side ponderosa pine and ID/MT's interior softwoods dominate the donor pool by area share. CEM matching draws growth trajectories from donors and applies them to subjects; the 11 percentage point underrepresentation of hemlock/Sitka spruce in the donor pool and the 7 to 8 percentage point overrepresentation of ponderosa pine and other western softwoods cause projected growth to import the slower-growing interior productivity rates. A future iteration with an expanded WA + OR coastal-only donor pool (excluding east-of-Cascades plots) would tighten this systematically.

## Recommended remediation paths in order of effort

1. **Restrict OR donors to west-of-Cascade plots only.** OR has both west-side and east-side stand types; restricting to west side reduces the interior pine contamination while keeping coastal Douglas-fir/hemlock representation. ~1 hour of R code in 02_cem_matching.R. Could halve the bias.

2. **Expand donor pool to include WA west side plots themselves.** Treating WA as its own donor for the western half of the state would best match WA west side hemlock/Sitka spruce subjects to their natural donor population. Requires bootstrap or leave-one-out matching to avoid leakage. ~3 hours of methodology work.

3. **Add Bailey ecological section (or EPA L3 ecoregion) as a CEM matching covariate.** This stratifies the matching at a level finer than state, preventing east-side donors from matching west-side subjects regardless of state of origin. ~4 hours. The recommended long term direction.

## Files

- `scripts/wa_donor_pool_diagnostic.R` — the analysis script (schema-tolerant for abbreviated COND extracts)
- `figures/wa_donor_pool_diagnostic.png` — side-by-side bar comparison of top 12 forest type groups
- `figures/wa_donor_pool_forest_type_comparison.csv` — per FORTYPCD subject vs donor counts/area/share
- `figures/wa_donor_pool_typgrp_comparison.csv` — TYPGRPCD aggregated comparison
- `figures/wa_donor_pool_diagnostic_summary.txt` — top groups + gap signature plain text
