# CEM on Cardinal: project map and output catalog (START HERE)

**Last built:** 2026-06-08. Regenerate the catalog anytime with
`~/fia_cem_projections/CATALOG/refresh_catalog.sh`.

## The short answer to "where is everything"

There is ONE home for the CEM model on Cardinal: **`~/fia_cem_projections`**. All the code,
config, and output already live under it. The confusion is not scattered code; it is 200 run
folders (110 GB) inside `output/`, most of them superseded attempts. This map plus the catalog
fix that. The other project folders in `~` (Disturbance, fvs-conus, cbm_maine, perseus_db,
LANDIS, etc.) are SEPARATE projects, not CEM.

## Two CONUS engines feed PERSEUS (know which home you are in)

PERSEUS compares engines. Two of them are generated under separate Cardinal homes, and both
ingest into `~/perseus_db`:

- **CEM** lives in `~/fia_cem_projections` (this map). State CIs in
  `output/state_summary_progression/`.
- **YC** (FIA hybrid yield curves, FIADB + TreeMap expansions) lives in
  `~/yield_curves_conus`. Canonical CIs in `~/yield_curves_conus/canonical/`
  (`ci_yc_{fiadb,treemap}_<st>_{rcp45,rcp85}.csv`), 48 states x 2 expansions x 2 RCPs = 192,
  completed 2026-06-08. Its publish is staged in `~/yield_curves_conus/ingest_yc_production.sh`
  (registers models `yc_fiadb_rcp45/85`, `yc_treemap_rcp45/85`, class YC; has a collision guard
  that aborts while CEM/compos/ingest jobs run; validated on `staging_yc/`).

A unified index of every publishable CI across both engines is at
`CATALOG/PUBLISHABLE_CIS.csv` (regenerate with `CATALOG/refresh_publishable_cis.sh`); 236 CIs
as of 2026-06-08 (CEM 44, YC 192).

## Canonical layout (everything is already here)

```
~/fia_cem_projections/
  CATALOG/                      <- START HERE each session
    PROJECT_MAP.md              this file
    OUTPUT_CATALOG.csv          every output/ run, parsed (state,date,tag,per_plot,CI,mtime)
    refresh_catalog.sh          rebuild the catalog
  run_projection.R              MAIN driver (the model entry point)
  R/                            pipeline modules 00..15 (00 config, 02 matching, 06 engine, 10 state expansion, ...)
  config/                       state_constants.csv, sdimax_brms_*.csv, maine_county_harvest_calibration.csv
  scripts/                      helper R scripts
  osc/                          SLURM submit scripts (submit_*.sh, *.slurm)
  docs/                         memos, handoffs, results (authoritative narrative)
  output/                       ALL run outputs, one folder per run
    state_summary_progression/  state-expanded CIs (the PUBLISHABLE series, *_ci.csv)
    <STATE>_<YYYYMMDD>_<tag>/    per-run: per_plot_projections.rds, table_*.csv, figures
  logs/                         SLURM job logs
```

Naming convention for runs: `STATE_YYYYMMDD_tag` (e.g., `ME_20260606_me_fixed_prod`). State CIs:
`state_<descriptor>_ci.csv`.

## Canonical / current runs (r22 fixed engine) — use these

The engine is r22 (fixes: tpaSat + qmdRecon + sdiGuard; see docs/SESSION_HANDOFF_20260608.md).
Anything produced before 2026-06-06 predates the forward-trajectory fix and is superseded for
forward projections (hindcast bias numbers from those remain valid).

| Purpose | Canonical output | Notes |
|---|---|---|
| CONUS, all states (fixed + SDImax) | `output/<ST>_*_conus_harmonized_sdimax_<ST>/` | array 11387267 + GA hugemem; in progress |
| CONUS state CIs (publish input) | `output/state_summary_progression/state_<ST>_conus_sdimax_ci.csv` | built by expand_conus_sdimax.R |
| ME conservation + active mgmt | `state_me_fixed_l7b_rcp45_ci.csv` | county harvest = active management |
| ME working-fraction managed | `state_me_fiadb_l7b_rcp45_ci.csv` | FIADB 0.1198; YC-comparison line |

## Superseded (archive candidates) — do NOT use for forward projections

- All `output/<ST>_2026{04,05}*` runs and the early-June pre-fix runs (p1/p2/p3/p3hindcast/
  p3lite/l7b/prodW/plantTerm/asymAnchor experiments). These were the bias-tuning and
  diagnostic campaign; their forward trajectories carry the pre-r22 bugs.
- `state_summary_progression/state_rcp{45,85}_hadgem2_wear*_r12..r20_ci.csv` (the r12-r20
  calibration series).
- The non-SDImax `conus_harmonized_<ST>` runs (superseded by `conus_harmonized_sdimax_<ST>`).

## Proposed cleanup (do AFTER the running jobs finish, with approval)

Do not move anything while the CONUS array (11387267), GA (11387249), or the expansion job
(11395111) are running; they read and write these paths. Once idle, the recommended tidy-up,
which I can execute on approval, is additive and reversible:

1. `mkdir output/_ARCHIVE` and move every superseded run folder into it (keeps them, just out
   of the way). Frees mental and disk clutter; ~80-100 folders.
2. `mkdir output/_CANONICAL` and symlink the canonical runs + CIs into it, so the blessed
   outputs are one `ls` away.
3. Keep `state_summary_progression/` as the CI home; move the r12-r20 CIs into an
   `state_summary_progression/_archive/`.

No deletions are proposed; everything is preserved under `_ARCHIVE`. Disk (110 GB) can be
reduced later by deleting confirmed-superseded `per_plot_projections.rds` (the large files),
but only with explicit per-item approval.

## Future-session routine

1. `cat ~/fia_cem_projections/CATALOG/PROJECT_MAP.md` (this file) and the latest
   `docs/SESSION_HANDOFF_*.md`.
2. `~/fia_cem_projections/CATALOG/refresh_catalog.sh` then open `OUTPUT_CATALOG.csv` to see
   the current run inventory and status.
3. Work from `run_projection.R` + `R/`; submit via `osc/`; outputs land in `output/`.
