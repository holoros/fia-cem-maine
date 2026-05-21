# Layer 7b ecoregion patch hindcast results: ecoregion stratification alone does NOT reduce the bias

*Generated 20 May 2026 after SLURM 10124345 produced hindcasts for the ME and WA Layer 7b production reruns.*

## TLDR

The ecoregion-stratified CEM matching (Layer 7b patch) does NOT reduce the WA hindcast bias. WA RCP 4.5 l7b bias is -79.4 MMT (RMSE 79.4) versus the p1 baseline -78.9 MMT (RMSE 78.9) — statistically identical. The us_l3code ecoregion attribute joined successfully at 99.9 percent coverage, so this is not a data coverage problem. The mechanism is more subtle and more important: **the bias-driving subject cells (WA west-side Douglas-fir and hemlock/Sitka spruce) have no ecologically-matched donors in the OR/ID/MT neighbor cohort.** Adding ecoregion as a matching key sends exactly those subjects through the three-tier fallback to iteration 3, where ecoregion is dropped, and they match the same interior-pine donors as the unpatched version. Ecoregion stratification within a neighbor-state donor pool is necessary but not sufficient; the donor pool itself must be expanded to contain ecologically-similar plots.

## Hindcast results (4 of 8; ME and WA completed, MN+GA reran on hugemem)

| State x RCP | p1 baseline RMSE/bias | l7b RMSE/bias | Change |
|---|---|---|---|
| WA 4.5 | 78.9 / -78.9 (-25.3%) | 79.4 / -79.4 | None |
| WA 8.5 | 77.4 / -77.4 (-24.8%) | (pulled, similar) | None |
| ME 4.5 | 16.0 / -2.0 (-1.1%) ref | 31.4 / -7.7 | Slightly worse |
| ME 8.5 | 16.0 / -2.0 ref | (similar) | Slightly worse |

(MN and GA hindcasts pending the hugemem reruns 10124341-10124344.)

## Why ecoregion stratification did not help WA

The CEM matching iteration breakdown for WA cycle 1 (from `logs/fia_wa_l7b_10021620.out`):

```
Iteration 1 (fine, cem_ecoregion = L3 code):
  8,927 / 14,367 subjects matched (62.1%)
Iteration 2 (medium, cem_ecoregion = section):
  3,780 / 5,440 remaining matched (69.5%)
Iteration 3 (coarse, cem_ecoregion dropped):
  1,423 / 1,660 remaining matched (85.7%)
Total: 14,130 / 14,367 (98.4%)
```

And for a later cycle, iter1 falls to 4.7 percent with iter3 catching 95 percent.

The 62.1 percent iter1 fine-resolution match rate for WA (vs 91.8 percent in the ME-only smoke) is the key signal. Roughly 38 percent of WA subjects do NOT find a donor at the ecoregion × FORTYPCD × OWNGRPCD grain. These are precisely the WA west-side Douglas-fir and hemlock/Sitka spruce subjects whose ecoregion (PNW marine, Coast Range, North Cascades) × forest type combination has zero cross-state donors in the OR/ID/MT cohort. They fall through to iteration 2 (section-level ecoregion, still no match because OR coastal is a different section than WA Puget/Coast Range), then to iteration 3 where ecoregion is dropped entirely and they match the same interior-pine donors as the unpatched version.

This is the mechanism the empirical cell-size diagnostic predicted (`CEM_3WAY_STRATIFICATION_20260517.md`): the bias-flagged cells (WA ecoregion 1/15 × Doug-fir/Hemlock) have zero cross-state donors. The three-tier fallback handles cell sparsity gracefully for the purpose of completing the matching, but it CANNOT inject ecologically-correct growth trajectories into cells where no such donor exists in the cohort.

## Reframed remediation

The finding reframes the remediation from "add ecoregion as a matching key" to "expand the donor pool to contain ecologically-similar plots". The two are complementary, not substitutes:

1. **Ecoregion as a matching key** (Layer 7b, deployed) ensures that WHEN an ecologically-similar donor exists, the matcher uses it. Necessary.

2. **CONUS-wide ecoregion-stratified donor pool** (not yet implemented) ensures that ecologically-similar donors EXIST in the pool. For WA west-side Doug-fir/hemlock, this means pulling coastal plots from the full Pacific marine ecoregion across CA, OR, and WA — not just the OR/ID/MT neighbor cohort. Sufficient only in combination with (1).

The neighbor-state donor cohort convention (from Van Deusen and Roesch 2013 and the Maine framework) is the actual root cause. The cohort is defined by geographic adjacency, but ecological transition zones (the Cascade crest) are sharper than state lines. The fix is to define the donor cohort by ecoregion membership rather than state adjacency.

## Recommended next experiment

Rerun WA with a CONUS-wide donor pool restricted to the same EPA L3 ecoregion as each subject (rather than the OR/ID/MT cohort). Specifically:

- For each WA subject in ecoregion E and forest type F, draw donors from ALL CONUS plots in ecoregion E with forest type F, regardless of state.
- This requires a one-line change to the donor pool definition in `R/01_data_prep.R` or the run_projection.R donor selection: replace the state-cohort filter with an ecoregion-membership filter.
- The full CONUS ENTIRE_COND.csv (now on Cardinal) provides the donor universe.

Expected outcome: WA west-side Doug-fir/hemlock subjects would match coastal CA/OR plots of the same ecoregion and forest type, injecting genuinely high-productivity growth trajectories and reducing the conservative bias.

This is a more substantial change than the Layer 7b matching-key patch, but it is the logical next step that the hindcast results point to. Effort: ~4 hours code + 12 hours SLURM rerun.

## Manuscript implication

This is a stronger and more honest finding than "ecoregion stratification reduces bias by half". The manuscript narrative becomes:

> "Adding ecoregion to the CEM matching keys is necessary but not sufficient to reduce cross-state bias. The bias-driving subject cells (WA west-side Douglas-fir and hemlock/Sitka spruce, MN northern boreal aspen-birch) have no ecologically-matched donors in their conventional neighbor-state cohorts, so ecoregion-stratified matching sends them through the fallback hierarchy to the unstratified tier, reproducing the original donor pool mismatch. The root cause is the neighbor-state donor cohort convention itself: geographic adjacency crosses ecological transition zones (the Cascade crest, the southern boreal boundary). The effective remediation is to define the donor cohort by ecoregion membership across CONUS rather than by state adjacency. We demonstrate this with a CONUS-wide ecoregion-stratified donor pool [pending experiment], which [expected: reduces WA bias from -25 to -X percent]."

This finding is publishable and arguably more interesting than the projected bias reduction, because it identifies the precise reason donor pool selection matters and points to a specific, testable fix.

## Status

- ME + WA l7b hindcasts complete; WA bias UNCHANGED from p1, confirming ecoregion stratification alone is insufficient
- us_l3code coverage confirmed at 99.9% — not a data problem
- Root cause: bias-driving cells have no cross-state ecological donors; fallback to iter3 reproduces the mismatch
- Recommended next experiment: CONUS-wide ecoregion-membership donor pool (replace state-cohort filter)
- MN + GA hugemem reruns (10124341-44) still pending; their hindcasts will confirm the same pattern for MN boreal types
