# Autopilot status 18 May 2026

*Snapshot at 11:25 AM ET while p2 production runs and p3 jobs pend.*

## TLDR

- Crosswalk v3 deployed: cond_full coverage 38.8% → 100.0% (the missing piece for Layer 8b iter 2 match anomaly).
- p2 production set (6 jobs, v2 crosswalk) RUNNING; ~35 min elapsed of ~6-10 h expected.
- p3 production set (6 jobs, v3 crosswalk) QUEUED with `--dependency=afterany:p2_jobs`; auto-fires when p2 finishes.
- Layer 8b smoke (ME us_l3_smoke2) validated cycle 1 gr_ratio 3.135 (2.888, 3.370) matching RPA 3.32 within 5%.

## Active SLURM jobs

| Job ID | Name | State | Crosswalk | Tag |
|---|---|---|---|---|
| 9936857 | fia_mn_p2 | RUNNING | v2 | rcp45_wear_p2 |
| 9936858 | fia_mn_p2_85 | RUNNING | v2 | rcp85_wear_p2 |
| 9936859 | fia_wa_p2 | RUNNING | v2 | rcp45_wear_p2 |
| 9936860 | fia_wa_p2_85 | RUNNING | v2 | rcp85_wear_p2 |
| 9936861 | fia_ga_p2 | RUNNING | v2 | rcp45_wear_p2 |
| 9936862 | fia_ga_p2_85 | RUNNING | v2 | rcp85_wear_p2 |
| 9939142 | fia_mn_p3 | PENDING (dep) | v3 | rcp45_wear_p3 |
| 9939143 | fia_mn_p3_85 | PENDING (dep) | v3 | rcp85_wear_p3 |
| 9939144 | fia_wa_p3 | PENDING (dep) | v3 | rcp45_wear_p3 |
| 9939145 | fia_wa_p3_85 | PENDING (dep) | v3 | rcp85_wear_p3 |
| 9939146 | fia_ga_p3 | PENDING (dep) | v3 | rcp45_wear_p3 |
| 9939147 | fia_ga_p3_85 | PENDING (dep) | v3 | rcp85_wear_p3 |

## What changed today

1. **Diagnosed iter 2 anomaly** (CEM_LAYER7_DEPLOYMENT memo iter 2 was 64.8% of remaining): root cause is v2 crosswalk used `slice_max(INVYR)` per plot identity, leaving cond_full's measurement-specific PLT_CNs with 38.8% coverage. Donors not in v2 defaulted to NA us_l3code, breaking the iter 2 section key.
2. **Built v3 crosswalk** (`scripts/build_hcb_l3_crosswalk_v3.R`): one row per PLT_CN. SLURM 9938372 finished exit 0 in ~2 minutes.
3. **Validated v3**: 904,215 rows across 21 states, 98.8% with us_l3code. Direct join against `~/FIA/ENTIRE_COND.csv` (21 states subset, 1,065,363 rows) shows 100.0% coverage vs v2's 38.8%.
4. **Swapped v3 into config/**: backed up v2 as `fia_plots_hcb_l3.v2_backup.csv`. Safe because p2 already past data-prep phase.
5. **Queued p3 production set** with dependency on p2.
6. **Committed locally**: ac858ab (v3 build scripts), ba8d831 (validation memo), recent commit for p3 submitters.

## What p3 should show

If v3 fixes the iter 2 bottleneck:

| Iteration | p2 expected (v2) | p3 expected (v3) |
|---|---:|---:|
| 1 (fine, L3 + FORTYPCD + OWNGRPCD) | ~91.8% | ~95%+ |
| 2 (medium, section + FORTYPCD + OWNGRPCD) | ~64.8% of remaining | ~85%+ of remaining |
| 3 (coarse, drop ecoregion) | ~90% of remaining | ~95%+ of remaining |

If bias mechanisms hold (CURRENT_STATE_SYNTHESIS_20260517.md):

| State | p2 (v2 strata, loose) | p3 (v3 strata, tight) | Direction |
|---|---:|---:|---|
| MN hindcast bias | -5.7% | -3 to 0% | Tighter |
| WA hindcast bias | -25% | -10 to -5% | Tighter |
| GA hindcast bias | +10% | +3 to +5% | Tighter |
| ME canonical | -1.1% | -1.1% | Unchanged |

## Files touched (Cardinal)

- `~/fia_cem_projections/scripts/build_hcb_l3_crosswalk_v3.R` (new)
- `~/fia_cem_projections/scripts/submit_crosswalk_v3.sh` (new)
- `~/fia_cem_projections/config/fia_plots_hcb_l3.csv` (replaced with v3)
- `~/fia_cem_projections/config/fia_plots_hcb_l3.v2_backup.csv` (backup)
- `~/fia_cem_projections/config/v3_staging/` (intermediate, can be archived later)
- `~/fia_cem_projections/osc/submit_{mn,wa,ga}_p3_{rcp45,rcp85}.sh` (new)

## Files touched (local)

- `scripts/build_hcb_l3_crosswalk_v3.R`
- `scripts/submit_crosswalk_v3.sh`
- `osc/submit_{mn,wa,ga}_p3_{rcp45,rcp85}.sh`
- `docs/CROSSWALK_V3_VALIDATION_20260518.md`
- `docs/AUTOPILOT_STATUS_20260518.md` (this file)
- Local repo at 53+ commits ahead of origin/main (push pending)

## Next on autopilot

While p2/p3 run (~10-20 h wall total), useful work:

1. **Pull p2 raw_mc summaries when each finishes** and snapshot iter1/2/3 match rates for the manuscript bias attribution table.
2. **After p3 launches**, capture p3 iter rates as the first quantitative test of whether v3 fixes the iter 2 bottleneck.
3. **Build p2 vs p3 comparison figure scripts** in R (one per state, BAU trajectory with both p2 and p3 lines) so the figure renders the moment p3 outputs land.
4. **Refresh hindcast_multistate.R** to consume both p2 and p3 directories and emit a 12-row residual table.

## Open questions still pending user

1. Manuscript framing (Option A framework validation vs Option B bias-attribution methodology) — see CURRENT_STATE_SYNTHESIS_20260517.md.
2. RPA aggregation framing decision (extend / reweight / reframe) for the p_harvest saturation flag.
3. STDORGCD plantation-vs-natural CEM matching for GA bias — pending decision on Option A vs Option B.
4. Reporting horizon: cycle 5 vs cycle 15.
