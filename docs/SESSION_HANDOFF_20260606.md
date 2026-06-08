# Session handoff: CEM forward-engine fix, validation, and publish staging

**Date:** 2026-06-06 (evening ET)
**Author:** A. Weiskittel (Cowork, autopilot)
**Branch:** `cem-wa-ga-refinements-20260602` (pushed to origin through commit `d8997d8`)
**Cardinal:** `~/fia_cem_projections`, `~/perseus_db`, account PUOM0008

## One-paragraph orientation

This session reviewed the local repo and Cardinal, found the project was not closed
(the May 26 MEMORY was stale), verified the area-collapse fix, then diagnosed and fixed
the real forward-trajectory bug: a runaway-ingrowth artifact. Two engine patches now make
the CEM forward projections physically sound; the fix is validated at the per-plot level,
production ME output is regenerated, and the PERSEUS publish is validated end to end in
staging. Two decisions remain before the CEM forward series goes live, both yours.

## What is DONE and committed/pushed

1. **Area-collapse fix verified.** The `replace=FALSE` bootstrap fix retains conditions
   (No_harvest 7299 -> 7299; area flat). `docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md`.
2. **Runaway-ingrowth bug fixed (two patches, applied to the live Cardinal engine, backed up):**
   - `cem_pipeline_patch/patch_tpa_saturation.py`: adds `* .sat_age` to `gr_tpa` (both
     branches) and scales `proj_tpa` in `apply_sdimax_cap`. Stops the TPA runaway.
   - `cem_pipeline_patch/patch_qmd_reconcile.py`: derives `proj_qmd` from capped BA and TPA
     so BA = TPA x 0.005454 x QMD^2 holds. Per-plot identity now within 0.95% median error.
   - Net effect (ME): reserve carbon now 234 -> peak 327 (2054) -> 307 (2074), a clean
     accumulate-then-plateau; TPA plausible; the 280 -> 50 crash is gone.
   - The fully patched engine (1267 lines) is synced into
     `cem_pipeline_patch/06_projection_engine.R` (the patch reference).
3. **Pushed to origin** (holoros auth via github-manager): all session commits through
   `d8997d8` on the feature branch.
4. **Fixed ME production produced.** Jobs 11315557 (n_sims=20) + 11315558 (state expansion)
   COMPLETED. Output CI:
   `~/fia_cem_projections/output/state_summary_progression/state_me_fixed_l7b_rcp45_ci.csv`
   (all 5 scenarios, 12 carbon-pool metrics, 2004-2074).
5. **PERSEUS publish validated end to end in staging** (production untouched). On a staging
   copy of the production DB, `ingest_cem_state.R` ingested the fixed ME CI (2700 rows, 5
   scenarios, 12 metrics) and `48_export_api.py` regenerated `series/ME.json` carrying the
   fixed series. The pipeline works; the climate key must be `rcp45_hadgem3` (FK-constrained)
   and the exporter takes positional args `48_export_api.py <project_root> <out_dir>` and
   reads `<root>/db/perseus_results.sqlite`.
6. **Production DB backed up:** `~/perseus_db/db/perseus_results.sqlite.bak_20260606`.

## DECISIONS MADE (6 June, late) + recalibration launched

Aaron's calls this session:
- **Scenario framing:** reserve (No_harvest) = conservation scenario; the county-active-
  management BAU = active-management scenario (kept, labeled as such).
- **Add a FIADB working-fraction managed scenario** for apples-to-apples comparison with the
  YC engine. ME FIADB `harvested_share` = **0.1198** per remeasurement (from
  `zenodo_upload/fia_mgmt_shares_bystate.csv`).

Acted on it: launched a recalibrated ME production (job **11356875**, expansion **11356876**)
that drops `--use_county_harvest` and sets `--fixed_harvest_rate 0.1198`, tag `me_fixed_fiadb`,
writing `output/state_summary_progression/state_me_fiadb_l7b_rcp45_ci.csv`. Its BAU is the
working-fraction managed line; its No_harvest is the same conservation line.

So three publishable CEM ME lines will exist: conservation (No_harvest), active management
(county BAU from `state_me_fixed_l7b_rcp45_ci.csv`), and working-fraction managed (BAU from
`state_me_fiadb_l7b_rcp45_ci.csv`).

**Publish timing note:** as of this writing Aaron has parallel CEM jobs running (the
`cem_rerun` array, `compos_v2_prod`, `cfi_ingfix`). Do the production-DB ingest + the
perseus-repo push only once those settle AND the recalibrated CI lands, to avoid colliding
with his in-flight ingests on the shared `~/perseus_db` and the live repo. The publish is
otherwise staging-validated and ready (see below).

## Original two decisions (now resolved above)

1. **Model reconciliation.** The live DB has ~10 CEM ME models (`cem_wear_nh_rcp45`,
   `cem_wear_rcp45`, `cem_wear_econ_*`, `cem_policy_*`, `cem_v5_anchored`, `cem_flagged`).
   The fixed run is one RCP45 L7B config with 5 scenarios. Decide whether the fixed reserve
   replaces `cem_wear_nh_rcp45` (the existing no-harvest model) in place, or is ingested as a
   new model (e.g. `cem_me_fixed_rcp45`) and the old buggy models retired. Ingesting additively
   without retiring the old ones would show duplicate/conflicting CEM ME lines in the explorer.
2. **Managed harvest calibration** (`docs/HARVEST_CALIBRATION_FLAG_20260606.md`). CEM BAU
   (-21% over 75 yr) uses a county-active-management harvest basis far heavier than the FIADB
   working fraction the YC engine uses (+27%). Reserve is unaffected. Pick: (1) label CEM
   managed as deliberately heavier active management, or (2) recalibrate to the FIADB working
   fraction for an apples-to-apples comparison. The reserve series publishes either way.

## Exact steps to go live (once decisions made)

```bash
# on Cardinal, modules loaded (gcc/12.3.0 then R/4.4.0)
cd ~/perseus_db
# 1. ingest fixed ME CI into PRODUCTION db (choose --model per decision 1)
Rscript adapters/ingest_cem_state.R ~/perseus_db --state ME \
  --csv ~/fia_cem_projections/output/state_summary_progression/state_me_fixed_l7b_rcp45_ci.csv \
  --model <cem_wear_nh_rcp45 OR cem_me_fixed_rcp45> --climate rcp45_hadgem3
# (if retiring old buggy models, delete their rows first; adapter is idempotent per model)
# 2. regenerate api
python3 48_export_api.py ~/perseus_db ~/perseus_db/api
# 3. deploy: copy ~/perseus_db/api/* into the perseus-forest-intelligence repo at its api
#    path, then commit + push to the branch GitHub Pages serves. PULL LATEST FIRST
#    (active parallel commits from the engine ingests; expect possible merge races).
#    Cache-bust / hard refresh to verify (the Pages CDN caches api JSON briefly).
```

## Remaining work (not blocking the ME reserve publish)

- WA/GA forward production on the 3-part engine (reuse the prodW / plantTerm submit scripts),
  then state expansion + ingest, for their fixed CIs.
- Promote the patched engine into the repo canonical `R/06_projection_engine.R` and tag a
  release. The patch reference is already current; this is the deliberate canonical swap.
- Add `total_system_c = ecosystem + HWP` to the state CIs; run `cem_to_hwp.py` for remaining
  scenarios (WA + GA BAU pools already exist).
- Manuscript revisions per `manuscript/REVISION_GUIDANCE_20260606.md` (lead with donor-analog
  gap + GA cohort; gate any forward results on the fix).
- Zenodo `zenodo_upload/` package is staged (June 5); push when ready.

## Cardinal job log this session

| Job | What | State |
|---|---|---|
| 11295651 | ME areafix_verify (2-part) | COMPLETED (prior) |
| 11315075 | area x density decomposition | COMPLETED |
| 11315513 | ME tpasat smoke (n_sims=1) | COMPLETED, TPA runaway gone |
| 11315532 | ME qmdrecon smoke (n_sims=1) | COMPLETED, per-plot identity <1% |
| 11315505/10 | 2-part n_sims=20 verify + decomp | CANCELLED (superseded by 3-part) |
| 11315557 | ME 3-part production n_sims=20 | COMPLETED 1h39 |
| 11315558 | ME state expansion -> fixed CI | COMPLETED |

## Key files (this session)

- `docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md` — area fix verified + root cause
- `docs/TPASAT_SMOKE_RESULT_20260606.md` — both fixes validated, reserve +35%/BAU
- `docs/HARVEST_CALIBRATION_FLAG_20260606.md` — the managed-harvest decision
- `cem_pipeline_patch/patch_tpa_saturation.py`, `patch_qmd_reconcile.py`, `expand_one.R`
- Fixed CI on Cardinal: `output/state_summary_progression/state_me_fixed_l7b_rcp45_ci.csv`
