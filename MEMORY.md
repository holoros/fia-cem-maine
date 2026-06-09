# Project Memory

*Created May 9, 2026 — last updated 8 June 2026 PM ET*

> **Current authoritative handoff: `docs/SESSION_HANDOFF_20260608.md`.**
> Engine at r22 (three patches: tpaSat, qmdRecon, sdiGuard), promoted to canonical `R/`.
> SDImax-enabled CONUS rerun launched (array 11387267 + GA hugemem 11387249); PERSEUS publish
> runs after it completes (steps in the 0608 handoff). The sections below are prior context.

## Current state (6 June 2026)

**Active, not closed.** The May 26 "project closed" note was superseded by three
weeks of work: state bias refinements (WA, GA), PERSEUS CONUS integration, HWP
storage wiring, and the discovery + partial fix of a forward-trajectory bug. The
gating open item is a single-line engine bug now fully diagnosed (see below).

### The forward-trajectory bug (the thing that gates everything)

PERSEUS showed the Maine CEM managed-harvest carbon crashing (280 -> ~50 Tg),
the lone outlier among engines. Investigation (June 4 to 6) found TWO causes:

1. **Area/condition collapse (artifact) - FIXED and VERIFIED 6 June.** The
   `--bootstrap_plots` resample-with-replacement collapsed duplicate conditions
   in the matching join. Fix: `replace = FALSE`. Verified in
   `ME_20260605_areafix_verify` (job 11295651) + decomposition (job 11315075):
   area (sum CONDPROP) is now flat across 15 cycles, and No_harvest condition
   count is perfectly retained (7299 -> 7299). See
   `docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md`.
2. **Runaway ingrowth (modeling bug) - DIAGNOSED, fix not yet applied.** The
   residual crash is NOT density decline and NOT area loss: `proj_tpa` runs away
   to physically impossible values (No_harvest reaches 20,997 TPA/acre by cycle
   15) while BA and carbon fall. Root cause located in
   `cem_pipeline_patch/06_projection_engine.R`: `gr_tpa` (lines ~794 and ~830) is
   the only growth rate missing the `* .sat_age` saturation term, so tree count
   compounds at up to 2.0x/cycle forever; `apply_sdimax_cap` then scales BA and
   carbon down by `sdi_ratio` (driven by the inflated `proj_sdi`) but never scales
   `proj_tpa`, so the three state variables decouple (160x BA divergence by cycle
   15). Surgical fix in the memo: saturate `gr_tpa`, and make the SDImax cap bind
   on `proj_tpa` too.

**This gates PERSEUS publication of the CEM forward series.** Hindcast bias numbers
(5-cycle, subject-matched) do not reach the runaway regime and remain sound.

## State refinement results (full n_sims=100, trustworthy)

| State | config | hindcast bias | status |
|---|---|---|---|
| ME | r11/L7B | RMSE 16 MMT (6%), bias -1.1% | reference, good |
| WA | prodW bw100 | -22.9% / -21.2% (RCP45/85) | canonical; donor levers exhausted |
| GA | plantTerm rot35 + prod L7B | **+0.3%** (RMSE 19.2%) | SOLVED (was +20.4%) |
| MN | L7B | within +/-10% | good |

WA underprediction is a donor-analog gap (west-side maritime Douglas fir has no
FIA analog); closing it needs a structural instrument (Cascades-split key or a
process/empirical PNW growth model), not more donor tuning. GA overprediction is
solved by the stand-origin-aware plantation rotation (STDORGCD=1 -> 35 yr).

## PERSEUS integration (CONUS)

- Explorer: github.com/holoros/perseus-forest-intelligence, live at
  holoros.github.io/perseus-forest-intelligence. Static read layer over
  `~/perseus_db` on Cardinal (SQLite -> `48_export_api.py` -> api JSON).
- State-general adapter `perseus_integration/ingest_cem_state.R` is built and, as
  of 6 June, **dry-run validated end to end** against a copy of the production DB:
  WA prodW and GA plantTerm each ingest 2475 rows (5 scenarios x 11 metrics, 2004
  to 2074) cleanly. Production DB untouched.
- **Held:** do not publish the CEM forward series to production until the ingrowth
  bug is fixed (the 2024 to 2074 window carries the artifact). The YC hybrid engine
  and hindcast-validated bias numbers remain publishable.
- The PERSEUS FIA yield-curve engine (separate from CEM) was unified onto one
  hybrid Chapman-Richards form and the managed scenarios recalibrated to FIADB
  working fractions; see `PERSEUS_session_handoff.md` and `PERSEUS_yield_curve_memo.md`.

## HWP long-term storage

- CEM harvest stream wired to Wei's WPsCS-Estimator. Bridge:
  `perseus_integration/hwp/cem_to_hwp.py`. First pools produced: WA RCP45 BAU
  (`wa_hwp_rcp45_bau.csv`) and GA RCP45 BAU (`ga_hwp_rcp45_bau.csv`).
- Next: add `total_system_c = ecosystem_c + hwp_total` to the state-summary CI so
  managed-vs-reserve is a fair comparison; expose `hwp_total` in PERSEUS.

## Repository state (6 June)

- Active branch `cem-wa-ga-refinements-20260602` (PR #3 to holoros/fia-cem-maine),
  in sync with origin; HEAD `ac22efe`.
- Uncommitted June work present locally: `PERSEUS_session_handoff.md`,
  `PERSEUS_yield_curve_memo.md`, `yc_engine_outputs/`, `zenodo_upload/`, plus the
  new `docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md`. Commit these.
- Reproducibility item: the patched Cardinal r21 engine
  (`cem_pipeline_patch/06_projection_engine.R`, 1236 lines) is newer than the repo
  canonical `R/06_projection_engine.R` (1109 lines). **Do NOT promote the engine
  yet** - promoting now would canonicalize the known ingrowth bug. Promote + tag a
  release only after the `gr_tpa` saturation fix is in and re-verified.
- gh auth is via the github-manager skill (not active in a fresh session).

## Cardinal snapshot (6 June)

- One active job `tm_total` (11314579) belongs to PERSEUS TreeMap, not CEM.
- `~/fia_cem_projections` is 104 GB. Account PUOM0008.
- Module load order is mandatory: `gcc/12.3.0` first, then R/4.4.0.

## Manuscript inventory

Main draft assembled (Abstract, Intro, Methods, Results 3.1 to 3.6, Discussion,
Conclusion, supplements S1 to S8). Drafts live in `manuscript/`.

**Required revisions** before submission (see
`manuscript/REVISION_GUIDANCE_20260606.md`):
1. Lead Section 3.5, Discussion, and Abstract with the donor-analog-gap framing
   (WA) plus the GA cohort/plantation-rotation result, replacing the old "v3 clean
   win" framing.
2. The manuscript reports HINDCAST validation, which is sound. Do NOT present CEM
   forward (2024 to 2074) trajectories as results until the ingrowth fix lands; if
   forward projections are in scope, gate them on the fix.

## Ingrowth fix status (6 June PM)

**Applied and smoke-verified.** `patch_tpa_saturation.py` is on the live Cardinal
engine (backup retained). The n_sims=1 smoke (`ME_20260606_tpasat_smoke`, job
11315513) confirms the primary bug is fixed: proj_tpa now declines gently to a few
hundred TPA (BAU 714->484, No_harvest 739->631) instead of exploding to 9,773/20,997,
and No_harvest carbon now rises then plateaus (+10%). The n_sims=20 confirmation (job
11315505) is running with an auto-dependent decomposition (job 11315510). Two
residuals remain, see `docs/TPASAT_SMOKE_RESULT_20260606.md`:
- proj_qmd is on an independent path; BA/TPA/QMD coherence improved 159x -> 6x but is
  not closed. One-line fix: recompute proj_qmd from capped BA and TPA in
  apply_sdimax_cap. Do AFTER the n_sims=20 verify so it is not invalidated.
- BAU/managed carbon still declines ~27%, sign-conflicting with the recalibrated YC ME
  managed-harvest (+27%). Likely CEM BAU harvest intensity exceeds the FIADB working
  fraction (same issue YC already corrected). Reconcile against
  zenodo_upload/fia_mgmt_shares_bystate.csv before publishing managed forward series.

## 6 June PM update: both engine fixes done, pushed, production launched

- **Engine is now 3-part fixed:** areafix + tpaSat + qmdRecon. Both new patch scripts
  (`patch_tpa_saturation.py`, `patch_qmd_reconcile.py`) are applied to the live Cardinal
  engine and committed. Per-plot BA identity holds (median 0.95% err). Reserve carbon +35%,
  BAU -16%, TPA stable. See `docs/TPASAT_SMOKE_RESULT_20260606.md`.
- **Pushed to origin:** branch `cem-wa-ga-refinements-20260602` pushed through commit
  `a436a74` (all today's work, including the patched engine synced into the patch reference).
- **Production launched:** ME 3-part production (job 11315557, n_sims=20) + chained state
  expansion (11315558) will write `output/state_summary_progression/state_me_fixed_l7b_rcp45_ci.csv`,
  the publishable ME CI. ~90 min + 40 min.
- **Harvest calibration is a DECISION for Aaron**, not a bug: CEM BAU (-16%) uses a
  county-active-management harvest basis far heavier than the FIADB working fraction the YC
  engine uses (+27%). Reserve scenario is unaffected. See
  `docs/HARVEST_CALIBRATION_FLAG_20260606.md` for the two options.

## Next session pickup checklist

1. When job 11315557 -> 11315558 finish, the ME fixed CI lands. Ingest its **reserve
   (No_harvest)** series to PERSEUS production via `perseus_db/adapters/ingest_cem_state.R`,
   run `48_export_api.py`, publish (respect the gh-pages/main desync in the perseus README).
2. Decide the harvest calibration (option 1 label vs option 2 recalibrate); then publish the
   managed CEM series.
3. Re-run WA/GA forward production on the 3-part engine (reuse the prodW / plantTerm submit
   scripts) for their fixed CIs, then ingest.
4. Promote the patched engine into the repo canonical `R/` and tag a release (the patch
   reference `cem_pipeline_patch/06_projection_engine.R` is already current at 1267 lines).
5. Add `total_system_c` to state CIs; run `cem_to_hwp.py` for remaining scenarios.
6. Finish manuscript revisions per `manuscript/REVISION_GUIDANCE_20260606.md`.
7. Zenodo: `zenodo_upload/` package is staged (June 5); push when ready.

## Original relocation note

Moved from `~/Documents/Claude/` root into the active-projects tree May 9, 2026.
See `README.md` / `HANDOFF.md` for full project context.
