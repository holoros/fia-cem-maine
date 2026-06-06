# Area fix verified; residual problem is runaway ingrowth, not area or density

**Date:** 2026-06-06
**Author:** A. Weiskittel (Cowork)
**Run analyzed:** `output/ME_20260605_areafix_verify` (job 11295651, replace=FALSE bootstrap, n_sims=20, 15 cycles)
**Decomposition job:** 11315075 (`areafix_decomp.R`, single sim, per-plot level)
**Supersedes the open item in:** `docs/ROOT_CAUSE_AREA_COLLAPSE_20260604.md`

## Headline

The `replace = FALSE` bootstrap fix resolved the area-collapse artifact. It did **not**
resolve the forward trajectory crash, because the crash has a second, larger cause that the
area decomposition now isolates: the projected tree count per condition runs away to
physically impossible values (proj_tpa reaches 9,800 to 21,000 trees/acre by cycle 15) while
basal area and carbon fall. The three stand-state variables (TPA, BA, carbon) have decoupled.
This is a regeneration/ingrowth submodel failure, not an area-loss artifact and not a simple
density decline.

## Evidence 1: the area fix worked

EXPNS-free per-plot area proxy (sum of CONDPROP_UNADJ) is flat across all 15 cycles, and the
No_harvest condition count is now perfectly retained:

| scenario | area_cprop cyc1 -> cyc15 | n_unique_cond cyc1 -> cyc15 |
|---|---|---|
| No_harvest | 5810 -> 5810 (0%) | 7299 -> 7299 (0%) |
| BAU | 5818 -> 5774 (-1%) | 7289 -> 5605 (-23%) |
| Harvest_p25_pulp | 5811 -> 5774 (-1%) | 7281 -> 5237 (-28%) |

Area is conserved. In the No_harvest case condition count is also perfectly conserved, which
is the clean confirmation that the duplicate-collapse bug is gone. The condition-count decline
in the harvest scenarios is harvest removing conditions from the standing pool (expected), and
area_cprop staying flat shows that removed area is conserved, not leaked. Compare the old r19
production run, where conditions and area both collapsed ~75% even in No_harvest.

## Evidence 2: the real problem is runaway ingrowth

Single-sim per-condition means, BAU and No_harvest:

| scenario | metric | cyc1 | cyc5 | cyc9 | cyc15 | cyc1->15 |
|---|---|---:|---:|---:|---:|---:|
| BAU | proj_carbon | 43,605 | 43,198 | 35,282 | 25,337 | -42% |
| BAU | proj_BA | 88.8 | 81.2 | 62.8 | 44.1 | -50% |
| BAU | proj_tpa | 734 | 802 | 1,326 | 9,773 | +1231% |
| BAU | proj_qmd | 6.08 | 7.26 | 8.44 | 11.45 | +88% |
| No_harvest | proj_tpa | 760 | 928 | 1,915 | 20,997 | +2662% |
| No_harvest | proj_carbon | 45,798 | 54,032 | 49,059 | 33,027 | -28% |

A natural stand cannot carry 10,000 to 21,000 trees/acre; mature mixed stands run a few
hundred to low thousands. TPA accelerates (not linear), which is the signature of an
unbounded regeneration loop adding cohorts faster than mortality removes them.

## The smoking gun: internal inconsistency

Basal area must satisfy BA = TPA x 0.005454 x QMD^2. Checking the reported state variables
against that identity (BAU):

| cycle | proj_BA reported | BA implied by proj_tpa, proj_qmd | ratio |
|---:|---:|---:|---:|
| 1 | 88.8 | 147.9 | 1.7x |
| 5 | 81.2 | 230.6 | 2.8x |
| 10 | 59.1 | 720.8 | 12x |
| 15 | 44.1 | 6,990 | 159x |

The reported BA and the BA implied by the reported TPA and QMD diverge by 160x at cycle 15.
The three variables are not being kept on the same stand. proj_tpa is accumulating ingrowth on
one path while proj_BA / proj_carbon decline on another. Whichever variable PERSEUS plots
(carbon), the trajectory is an artifact of this decoupling, not forest biology.

## Diagnosis

The forward regeneration/ingrowth routine adds small-tree cohorts each cycle with no effective
per-acre stocking ceiling, so TPA runs away. The SDImax cap that was wired in earlier throttles
density-dependent growth but is evidently not bounding the ingrowth tree count in the forward
engine, and the TPA path is not reconciled back into the BA/carbon path. The hindcasts passed
because over 5 cycles (25 yr) the runaway has not yet dominated; it dominates by cycle 9 to 15
of the 75 yr forward run, which is exactly where PERSEUS shows the Maine CEM crash.

## Root cause located in code (06_projection_engine.R)

The mechanism is a single missing term. In the growth-rate block (lines ~787 to 794 for the
not-harvested branch, mirrored at ~823 to 830 for harvested), every mass/area variable scales
its growth departure from 1.0 by the age-saturation factor `.sat_age` (which decays to 0 at
terminal age, so mature stands approach zero net growth):

```r
gr_BA     = 1 + (pmin(pmax(T2_BA/d_BA, 0.5), 2.0) - 1) * .sat_age
gr_carbon = 1 + (pmin(pmax(T2_carbon_ag/d_carbon_ag, 0.5), 2.0) - 1) * .sat_age
...
gr_tpa    = pmin(pmax(if_else(d_tpa_live > 0, T2_tpa_live/d_tpa_live, 1.0), 0.5), 2.0)   # <-- NO .sat_age
```

`gr_tpa` is the lone exception: it is a raw [0.5, 2.0] multiplier with no `.sat_age` attenuation.
So tree count keeps multiplying by up to 2.0 per cycle indefinitely, even in overmature stands,
compounding to the observed +1200% to +2660% over 15 cycles. Then `apply_sdimax_cap` (lines
742 to 763) computes `proj_sdi = proj_tpa * (proj_qmd/10)^REINEKE_EXP` and multiplies
`proj_BA`, `proj_carbon`, `proj_volcfnet`, `proj_drybio` by `sdi_ratio = min(1, sdimax/proj_sdi)`
**but never scales `proj_tpa`**. As the unsaturated TPA explodes, `proj_sdi` explodes, `sdi_ratio`
collapses toward 0, and the cap drives BA and carbon down. That is exactly the 160x divergence in
the coherence check: the cap pushes reported BA down while TPA is pushed up on an uncapped path.

## Fix path (revised, now surgical)

1. **Saturate the TPA growth rate.** Add the `.sat_age` term to `gr_tpa` at both lines (~794 and
   ~830) so it mirrors the other state variables:
   `gr_tpa = 1 + (pmin(pmax(if_else(d_tpa_live>0, T2_tpa_live/d_tpa_live, 1.0), 0.5), 2.0) - 1) * .sat_age`.
2. **Let the SDImax cap bind on tree count too.** In `apply_sdimax_cap`, also scale
   `proj_tpa = proj_tpa * sdi_ratio` (and recompute `proj_qmd` from capped BA and TPA), so the
   stand is held on the Reineke line and TPA, QMD, BA, carbon stay mutually consistent.
3. **Re-verify** on the ME area-fix config. No_harvest is the clean test: TPA must stabilize at a
   plausible few-hundred to low-thousand, carbon must rise then plateau, and BA implied by
   TPA and QMD must match reported BA within a few percent.
4. Only then run forward production for ME/WA/GA and ingest the forward series into PERSEUS.

Both changes are a few lines in `cem_pipeline_patch/06_projection_engine.R` (the live Cardinal
r21 engine). Recommend a new patch script `patch_tpa_saturation.py` alongside the others, default
ON, with a one-sim ME smoke before the full verify.

## Status of fronts

- Area artifact: FIXED and verified (this memo).
- Ingrowth runaway: diagnosed here, fix not yet applied. This now gates the CEM forward series.
- Hindcast bias work (WA prodW -22.9%, GA plantTerm +0.3%): unaffected and sound; those are
  5-cycle subject-matched comparisons that do not reach the runaway regime.
- PERSEUS publication of CEM **forward** series stays gated. Hindcast-validated state bias
  numbers and the YC engine remain publishable.
