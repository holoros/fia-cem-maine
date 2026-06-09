# Session handoff: CEM forward fixes complete, SDImax CONUS rerun launched, publish pending

**Date:** 2026-06-08
**Author:** A. Weiskittel (Cowork, autopilot)
**Branch:** `cem-wa-ga-refinements-20260602`, pushed to origin (latest `3cd740d` + this commit)
**Supersedes:** `docs/SESSION_HANDOFF_20260606.md` for current state.

## Orientation

The CEM forward-trajectory bug is fully fixed and the engine is at r22 with three patches.
A CONUS-wide rerun on the fixed engine with the maximum-SDI constraint enabled is now running
(39 states). The PERSEUS publish runs after that rerun completes; the exact steps are below.

## Engine state (r22, canonical)

Three patches, all applied to the live Cardinal engine and promoted to the repo canonical
`R/06_projection_engine.R` (1267 lines), backups retained:

1. `patch_tpa_saturation.py` (tpaSat): adds `* .sat_age` to `gr_tpa` (both branches) and scales
   `proj_tpa` in `apply_sdimax_cap`. Stops the runaway ingrowth (the forward-crash root cause).
2. `patch_qmd_reconcile.py` (qmdRecon): derives `proj_qmd` from capped BA and TPA so
   BA = TPA x 0.005454 x QMD^2 holds. Per-plot identity verified to 0.95% median error.
3. `patch_sdimax_guard.py` (sdiGuard): accepts a plot/fortyp SDImax only within [150, 800]
   trees/acre (english), else falls through. Guards against noisy BRMS posterior tails
   (the lookup ranged 36 to 1478; imperial SDImax should be ~300-600).

Validation: ME reserve carbon now rises 234 -> 327 (2054) -> 307 (2074), a clean
accumulate-then-plateau; TPA plausible; the 280 -> 50 crash is gone. SDImax units verified
imperial-consistent end to end (`docs/SDIMAX_UNITS_CHECK_20260608.md`).

## Decisions resolved this session

- **Scenarios:** reserve (No_harvest) = conservation; county-rate BAU = active management
  (kept, labeled). Both legitimate, distinct scenarios.
- **Harvest recalibration:** recalibrating ME managed to the FIADB working fraction (0.1198)
  does NOT reconcile CEM with the YC engine (CEM -31% vs YC +27%). The gap is structural
  (CEM projects harvested-condition regrowth; YC blends a reserve fraction), not a rate issue.
  The reserve/conservation line is the robust cross-engine series. See
  `docs/HARVEST_CALIBRATION_FLAG_20260606.md`.
- **SDImax constraint:** important and now enabled with the band guard. Units verified.

## CONUS rerun in flight (the publish input)

- `run_cem_conus_rerun_sdimax.slurm` -> array **11387267** (`--array=0-37%12`, 38 states,
  n_sims=100, `--scenario_set harvest --save_per_plot --use_brms_sdimax`, tag
  `conus_harmonized_sdimax_<ST>`). GA excluded from the array (OOMs at 48G).
- **GA** runs separately on hugemem: job **11387249** (48 CPUs ~930G, same SDImax config, tag
  `conus_harmonized_sdimax_GA`). The hugemem QOS caps memory per CPU (MaxMemPerCPU~19.8G), so
  request CPUs proportional to memory there.
- The superseded non-SDImax array (11356648) was cancelled.
- ETA: several days (12 concurrent, ~20h/state). Some large states may OOM at 48G like GA;
  resubmit those on hugemem with the 48-CPU pattern.

## PERSEUS publish plan (run AFTER the rerun completes)

Production DB backed up: `~/perseus_db/db/perseus_results.sqlite.bak_20260606`. Pipeline is
staging-validated (climate key must be `rcp45_hadgem3`; exporter is positional
`48_export_api.py <root> <out>`). Steps, on Cardinal with modules loaded:

1. **State expansion** per completed state: run `expand_to_state()` (see `expand_one.R` for the
   pattern) on each `output/<ST>_*_conus_harmonized_sdimax_<ST>/per_plot_projections.rds` to
   produce a CI with `output_prefix=state_<ST>_conus_sdimax`.
2. **Ingest** each CI: `Rscript adapters/ingest_cem_state.R ~/perseus_db --state <ST>
   --csv <ci.csv> --model cem_conus_sdimax_rcp45 --climate rcp45_hadgem3`. Idempotent per
   (state, model, scenario, year).
3. **Model reconciliation:** retire the old buggy CEM models for each state (delete rows for
   `cem_wear_rcp45/85`, `cem_wear_econ_*`, `cem_wear_nh_*`, `cem_policy_*`, `cem_v5_anchored`,
   `cem_flagged`) so the explorer shows the single corrected CEM, not duplicates.
4. **Export:** `python3 48_export_api.py ~/perseus_db ~/perseus_db/api`.
5. **Deploy:** copy `~/perseus_db/api/*` into the perseus-forest-intelligence repo and push to
   the gh-pages branch. PULL LATEST FIRST (active parallel commits; merge-race risk). Cache-bust
   to verify (the Pages CDN caches the api JSON briefly).

Publish the conservation (reserve) line with confidence; label the managed line as a CEM
active-management projection, not directly comparable to the YC managed bucket.

## Remaining (not blocking)

- WA/GA per-state donor tuning (prodW, plantTerm) is intentionally NOT in the harmonized
  config; decide whether the paper/explorer uses harmonized or per-state-tuned CEM.
- Manuscript revisions per `manuscript/REVISION_GUIDANCE_20260606.md`.
- Release tag once PR #3 merges to main.
- `total_system_c = ecosystem + HWP` on the CIs; `cem_to_hwp.py` for remaining scenarios.
- Zenodo `zenodo_upload/` staged (June 5).

## Key job log

| Job | What | State |
|---|---|---|
| 11315557/58 | ME 3-part production + expansion -> fixed CI | COMPLETED |
| 11356875/76 | ME FIADB working-fraction run + expansion | COMPLETED |
| 11387247 | ME sdiGuard smoke (confirmatory) | running at handoff |
| 11387249 | GA conus_harmonized_sdimax (hugemem 48cpu) | RUNNING |
| 11387267 | CONUS sdimax array, 38 states | PENDING/RUNNING |
| 11356648 | superseded non-SDImax CONUS array | CANCELLED |
