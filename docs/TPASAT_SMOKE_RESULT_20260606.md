# TPA-saturation fix: smoke result (primary bug fixed, two residuals)

**Date:** 2026-06-06
**Author:** A. Weiskittel (Cowork, autopilot)
**Run:** `output/ME_20260606_tpasat_smoke` (job 11315513, n_sims=1, 15 cycles, ME,
same full config as the area-fix verify, on the engine patched by
`patch_tpa_saturation.py`). Full n_sims=20 confirmation (job 11315505) still running
with an auto-dependent decomposition (job 11315510).
**Patch:** saturate `gr_tpa` with `.sat_age` (both branches) + scale `proj_tpa` by
`sdi_ratio` in `apply_sdimax_cap`. See `docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md`.

## Primary result: the runaway is gone

| scenario | proj_tpa cyc1 -> cyc15 | BROKEN run cyc15 | carbon cyc1 -> cyc15 (shape) |
|---|---|---|---|
| No_harvest | 739 -> 631 (-15%) | 20,997 | 45,722 -> 58,435 (peak c5) -> 50,381; **+10%, rise then plateau** |
| BAU | 714 -> 484 (-32%) | 9,773 | 43,552 -> 45,950 (peak c5) -> 31,684; -27% |
| Harvest_m25_mill | 724 -> 558 | n/a | -21% |
| Harvest_p25_pulp | 716 -> 436 | n/a | -33% |

TPA now declines gently with stand age to physically plausible values (a few hundred
trees/acre) instead of exploding into the tens of thousands. The No_harvest carbon
trajectory is now the correct accumulate-then-senesce shape. Area remains retained
(area_cprop flat; No_harvest n_uid 7299 throughout). The `.sat_age` term on `gr_tpa`
is the decisive change.

## Residual 1: BA / QMD coherence improved 26x but not closed

The BA identity check (BA = TPA x 0.005454 x QMD^2) at cycle 15:

| scenario | BA reported | BA implied | ratio | broken-run ratio |
|---|---:|---:|---:|---:|
| BAU | 56.1 | 339.8 | 6.0x | 159x |
| No_harvest | 85.3 | 542.0 | 6.4x | n/a (TPA had exploded) |

The 159x decoupling collapsed to ~6x, but the three variables are still not on one
stand. Cause: `proj_qmd` is computed on an independent growth path (`qmd * gr_qmd`,
QMD rising +106% over 75 yr) and is never reconciled with the capped `proj_BA` and
`proj_tpa`. This does NOT affect the carbon output PERSEUS plots (carbon is on the
saturated+capped mass path, not the QMD path), but it should be closed for internal
consistency. **Proposed fix:** in `apply_sdimax_cap`, after scaling BA and TPA,
recompute `proj_qmd = sqrt(proj_BA / (proj_tpa * 0.005454))` so QMD is derived from
the capped state rather than an independent path. One line; defer until after the
n_sims=20 confirmation so the running verify is not invalidated.

## Residual 2: managed (BAU) carbon still declines ~27%, sign-conflicts with YC

BAU carbon falls 27% over 75 yr under the fixed 10%/cycle harvest. This is no longer
the 82% artifact crash, and it is now driven by real harvest removal, but it conflicts
in sign with the recalibrated PERSEUS YC engine, which shows ME managed-harvest at
**+27%** after the FIADB working-fraction recalibration (see PERSEUS_yield_curve_memo.md).
The likely cause is the CEM BAU applying harvest to a much larger share of the land
base than the FIADB ~0.8%-of-plots-per-remeasurement observed rate, the same
over-aggressive-harvest issue the YC engine already corrected. **Action before
publishing managed forward series:** reconcile the CEM BAU harvest intensity against
the FIADB working fractions in `zenodo_upload/fia_mgmt_shares_bystate.csv`.

## Bottom line

- Primary runaway-ingrowth bug: FIXED. Reserve/No_harvest forward carbon is now
  defensible (correct shape, plausible TPA, area retained).
- Managed/BAU forward carbon: shape is now sensible but the harvest intensity needs a
  FIADB calibration check before publication (parallels the YC fix).
- QMD coherence: 26x better, close it with the one-line QMD recompute after the
  n_sims=20 verify confirms.
- PERSEUS forward-series publication: reserve scenario unblocked pending the n_sims=20
  confirmation; managed scenarios gated on the harvest calibration.
