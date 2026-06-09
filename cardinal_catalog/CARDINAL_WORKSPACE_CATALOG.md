# Cardinal workspace catalog: the PERSEUS multi-model carbon effort

**Built:** 2026-06-09. User: crsfaaron. Total effort footprint ~410 GB across ~27 dirs.
**Integration truth:** the PERSEUS database `~/perseus_db/db/perseus_results.sqlite` is the
single registry of which engines/models exist. Everything below feeds it.

## What this effort is

PERSEUS Forest Intelligence compares independent forest-carbon models for CONUS. Each model
("engine class") is generated under its own Cardinal home, then ingested into `~/perseus_db`,
exported to API JSON by `48_export_api.py`, and served at
holoros.github.io/perseus-forest-intelligence. There are nine engine classes.

## Engine homes (class -> Cardinal home -> PERSEUS models)

| Class | Home dir(s) | Size | PERSEUS model_codes | Role / where outputs live |
|---|---|---:|---|---|
| **CEM** | `fia_cem_projections` | 128G | cem_wear_rcp45/85, cem_wear_econ_*, cem_wear_nh_*, cem_policy_*, cem_v5*, cem_flagged (+ new cem_conus_sdimax) | Coarsened exact matching carbon projection. Engine in `R/`; CIs in `output/state_summary_progression/`. See CATALOG/PROJECT_MAP.md. |
| **YC** | `yield_curves_conus` (309M); `yield_curves` (14M, old) | 0.3G | fia_yc, fvs_yc | FIA hybrid Chapman-Richards yield curves (FIADB + TreeMap expansions). 192 canonical CIs in `canonical/`; publish staged in `ingest_yc_production.sh`. |
| **CBM** | `cbm_maine` (8.4G), `cbm_states` (7.5G), `cbm_conus` (25M) | 16G | libcbm, libcbm_native, libcbm_cross_state_v2, libcbm_oat, libcbm_v3pc, gcbm_ag/native/total | Carbon Budget Model (libCBM + GCBM). |
| **FVS** | `fvs-conus` (185G), `fvs-modern` (4.9G), `fvs-modern-exp` | 190G | fvs_acd_native/anchored/calibrated/jenkins/nsvbe, fvs_ne_* (same suite) | Forest Vegetation Simulator. Largest footprint on disk. |
| **FIA** | `fia_data` (28G, raw), `Disturbance` (11G), `disturbance-ne-staging` (456M), `FIA` (empty) | 40G | fia_observed, fia_state_observed, fia_lsog_v5_1, aaron_disturbance_pipeline, aaron_disturbance_v5 | FIA observed anchors + the disturbance pipeline (separate project memory). |
| **HCM** | `conus_hcs` (3.3G), `conus_hcs_products` (7.5G) | 11G | hcm | Holt Carbon Model / HCS products. |
| **LANDIS** | `landis2` (stub, 4K) | tiny | landis_maine_v2, landis_maine_subtile, landis_t2, landis_local_prism, landis_washington_thinning | LANDIS-II. Outputs already in perseus_db; heavy data lives off-home / in landis2HPC repo. |
| **OSM** | `OSM` | 4.0G | osm_jenkins | OSM engine. |
| **VCC** | (lookup in `perseus_db`/config; `build_brms_sdimax_lookup` context) | n/a | potter_vcc | Potter vegetation carbon capacity reference. |

## Integration + supporting data/infra

| Dir | Size | Role |
|---|---:|---|
| `perseus_db` | 617M | **Integration hub.** SQLite results DB, `adapters/ingest_cem_state.R` and siblings, `48_export_api.py`, `api/`. The publish target for every engine. Backup: `db/perseus_results.sqlite.bak_20260606`. |
| `fia_data` | 28G | Raw FIA database (engine input). |
| `TREEMAP` | 1.1G | TreeMap rasters for spatial expansion (YC/CEM). |
| `SiteIndex` | 8.5G | Site index / productivity surfaces. |
| `raster_layers` | 1.3G | Geospatial covariates. |
| `NLCD` | 340M | Land cover. |
| `WPsCS_run` / `WPsCS_src` / `wpsenv` | ~0.3G | Harvested wood products (Wei WPsCS-Estimator) -> `total_system_c`. |
| `zenodo_staging` | 10G | Publication / archival staging. |
| `silc_cfi` / `silc_strata` | ~0.1G | CFI / stratification support. |
| `conus_render` / `conus_hcs_products` | | rendered raster products. |

## Status notes (what is current vs scratch)

- **Current focus:** CEM (r22 fixed engine, SDImax CONUS rerun in progress) and YC (192 CIs
  ready, ingest staged). These two are the active publish front.
- **Scratch / backups (archive candidates, do not feed PERSEUS):** `dg_refit_backup_*`,
  `fvs_fix_backup_*`, `acd_patch_scratch` (empty), `stage`, `stage2_pack_*`, `t2_final`,
  `t2_snapshot`, `lib_old`, `per_ft_b13`, `net01_standalone_test`, `magstd`, `scratch`.
- **Other projects (not this effort):** `HRF`, `LSOG`, `landowner`, `seven_islands`/`SevenIslands`,
  `ME_AGB_Map_Comparison`, `bakuzis_acadgy`, `magplot`, `Desktop`/`Pictures`/`Videos` (empty).

## Regenerate / drill down

- CEM run inventory: `CATALOG/refresh_catalog.sh` -> `CATALOG/OUTPUT_CATALOG.csv` (200 runs).
- All publishable CIs (CEM + YC): `CATALOG/refresh_publishable_cis.sh` -> `PUBLISHABLE_CIS.csv` (236).
- Engine/model truth: query `perseus_db` `model` table (9 classes, 46 models as of 2026-06-09).
- This catalog: `cardinal_catalog/CARDINAL_WORKSPACE_CATALOG.md` (repo) and `~/fia_cem_projections/CATALOG/` (Cardinal).
