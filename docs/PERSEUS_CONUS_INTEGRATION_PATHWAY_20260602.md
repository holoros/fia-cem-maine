# Pathway: incorporating FIA CEM outputs into PERSEUS Forest Intelligence across CONUS

**Date:** 2026-06-02
**Author:** A. Weiskittel (CRSF, University of Maine)
**Reviewed:** the live explorer (https://holoros.github.io/perseus-forest-intelligence/), the `holoros/perseus-forest-intelligence` repo, and the upstream `~/perseus_db` pipeline on OSC Cardinal.

## How the system actually fits together

The explorer is a static React/Vite/MapLibre app. It reads nothing live; it consumes JSON under `public/api/` that is exported from the upstream `perseus_db` database. The chain is:

```
FIA CEM runs (Cardinal ~/fia_cem_projections/output/state_summary_progression/state_<tag>_ci.csv)
        │   adapters/ingest_cem_*.R  (load per-scenario CI rows into the results DB)
        ▼
perseus_db/db/perseus_results.sqlite   (schema perseus_api_v1: model, scenario_preset, result_v02)
        │   scripts/48_export_api.py
        ▼
perseus_db/api/*.json  ->  copy to perseus-forest-intelligence/public/api/
        │   commit to main; GitHub Pages (gh-pages branch) redeploys
        ▼
explorer: api/series/<STATE>.json renders one line per engine
```

Each engine in a state series is one object:

```
series[metric][bucket] = [ { "model": "cem_wear_econ_rcp45", "cls": "CEM",
                             "label": "...", "pts": [[year, mean, lo, hi], ...] }, ... ]
```

`cls` is the engine family (CEM, FVS, LANDIS, GCBM, YC). `bucket` is `"managed (harvest)"` or `"reserve (no harvest)"`. `pts` is `[year, mean, lo, hi]`, which is exactly the shape of the CEM `state_<tag>_ci.csv` (one row per scenario × cycle, with mean/lo/hi on every metric).

## The gap

CEM is already a first-class engine class, but it is ingested for **Maine only** (91 CEM series objects in `ME.json`; zero in WA, GA, MN, IN, OR, ID, US). The reason is mechanical, not conceptual: the three CEM adapters (`ingest_cem_rcp_scenarios.R`, `ingest_cem_trajectory.R`, `ingest_cem_v5.R`) hardcode `state_code = 'ME'`, `_ME` scenario suffixes, `species_id 'fia_current_ME'`, and read from the Maine `~/HRF/projections/...` path. WA, GA, MN already have full CEM production runs on Cardinal whose CI CSVs match the contract; they have simply never been ingested.

Separately, the explorer already has a CONUS engine: the `YC` class (FIA empirical Chapman-Richards yield curves stratified by **forest-type group × EPA Level III ecoregion × ownership**, HCB raster), covering all 48 states, now promoted to the hybrid form `yc_hybrid_v1` (ADR 0001). That stratification backbone is the same one the CEM extension plan converges on. So CEM and YC are two realizations of one design: CEM is the per-plot Markov-matching engine, YC is the empirical-curve engine, on the identical ft × L3 × owner × HCB backbone.

This gives two complementary pathways to CONUS, plus an optional heavy third.

## Track A: focal-state CEM ingest (direct, near-term)

Generalize the existing CEM adapter from Maine to any state, then ingest the refined runs. This puts a real CEM line next to FVS/GCBM/LANDIS/YC for each focal state, which is the cross-engine comparison the explorer exists for.

Steps:

1. **Generalize `ingest_cem_rcp_scenarios.R` to a `--state` argument.** Replace the hardcoded `'ME'`, the `_ME` scenario-id suffix, `species_id`, and the input directory with parameters. The metric and bucket mapping (next section) and the DB registration logic are already correct and stay as is. One adapter, parameterized, replaces the Maine-only path.
2. **Point it at the refined CI CSVs** in `~/fia_cem_projections/output/state_summary_progression/`: ME canonical, WA `prodW` (productivity-weighted, bias -15.4%), GA `plantTerm` (plantation rotation), MN `l7b`. Tag engines descriptively, e.g. `cem_wear_prodW_rcp45` (WA), `cem_wear_plantTerm_rcp45` (GA).
3. **Re-export and publish:** `python3 scripts/48_export_api.py .` in `perseus_db`, copy `api/*` to `perseus-forest-intelligence/public/api/`, commit to `main`. Result: WA/GA/MN gain CEM trajectories in the explorer.

Prerequisite: ingest **production** runs (n_sims 100, both RCPs), not the current n_sims 20 smokes. The smokes confirm direction; they should not become the public canonical line. So Track A executes after the WA `prodW` and GA `plantTerm` smokes validate and are promoted to production.

## Track B: CONUS scaling through the YC hybrid (the real "across CONUS" answer)

Running per-plot CEM for all 48 states is not required to get CEM-informed signal nationwide, because the YC engine already carries the same stratification to CONUS. The pathway is to feed CEM's refinements into the YC hybrid as parameters and to use the focal-state CEM runs as out-of-sample validation of YC in those states.

The CEM refinements map directly onto YC hybrid controls:

| CEM refinement (this work) | YC hybrid analogue | Action |
|---|---|---|
| Productivity-weighted donor draw (prodW) | Per-cell empirical culmination A* anchoring | Use CEM's productivity steering to inform YC A* in low-data western cells |
| Plantation rotation age 35 yr (plantTerm, STDORGCD=1) | YC Industrial even-aged rotation (currently 45 yr) | Shorten Southern loblolly Industrial rotation toward the CEM-indicated 35 yr |
| Per-state terminal age (stateTerm: GA 80, WA 200) | YC hybrid culmination + decline tail | Cross-check YC senescence breakpoints against CEM terminal ages |
| HCB × EPA L3 stratification | YC ft-group × L3 × ownership | Already shared; keep the keys aligned across both engines |

Steps:

1. **Cross-engine validation.** With Track A done for WA/GA/MN, use the explorer's existing divergence view to compare CEM vs YC vs FVS/GCBM in those states. Agreement is the multi-model check; divergence localizes where a refinement matters.
2. **Port the refinements into the YC owner regimes and anchoring** (`ycx_01_curves.R` rotation lengths and `ycx_hybrid_anchor.R` A*), re-fit, re-anchor, re-export. This improves the CONUS layer in every state at once, not just focal states.
3. **Publish** through the same export path.

## Track C (optional, phase 2): full per-plot CEM for CONUS

If true per-plot CEM beyond focal states is wanted, run CEM per state using the extension architecture from `CEM_REFINEMENT_EXTENSION_PLAN_20260530.md` (L3 + HCB keys are already CONUS-wide; the per-state data recipe is documented), then ingest each state through the generalized Track A adapter. Higher compute and disk; reserve until focal validation in Tracks A and B supports the investment, and prioritize one representative state per uncovered RPA region first.

## Metric and bucket mapping (CEM CI CSV to perseus_api_v1)

The CEM `state_<tag>_ci.csv` columns map almost one to one onto the metric catalog in `api/meta.json`. Units already match (CEM MMT = PERSEUS Tg C).

| CEM column (mean/lo/hi) | PERSEUS metric | unit |
|---|---|---|
| mmt_agc | agc_live_total | Tg C |
| mmt_bgc | bgc_live_total | Tg C |
| mmt_dead_c | dead_wood_c | Tg C |
| mmt_litter_c | litter_c | Tg C |
| mmt_soil_c | soil_c | Tg C |
| mmt_under_c | understory_c | Tg C |
| mmt_total_c | total_ecosystem_c | Tg C |
| mmt_biomass | agb_dry | Tg dry biomass |
| merch_vol_mcf | merch_vol_mcf | Mcf |
| rd_mean_wtd / sdi_mean_wtd | rd_mean_wtd / sdi_mean_wtd | RD / SDI |
| total_area_mha | total_area_mha_cem | Mha |

Bucket: scenario `No_harvest` to `reserve (no harvest)`; `BAU` and the `Harvest_*` scenarios to `managed (harvest)`. `pts = [year, mean, lo, hi]` per scenario × cycle.

## Sequencing and governance

1. Promote WA `prodW` and GA `plantTerm` to production (n_sims 100, both RCPs) once the running smokes validate. (Prerequisite for any public ingest.)
2. Generalize the CEM adapter to `--state`; ingest ME/WA/GA/MN; re-export; publish. (Track A.)
3. Cross-engine validation in the explorer; port refinements into the YC hybrid; re-export. (Track B.)
4. Optional CONUS per-plot CEM rollout. (Track C.)

Governance cautions from the perseus repo README and `docs/desync.md`: the deployed `gh-pages` branch (v1.3) is ahead of `main` source; Pages Source must stay "Deploy from a branch: gh-pages" and the deploy workflow stays `workflow_dispatch` only until that desync is reconciled. Data refreshes must follow the documented path (export from `perseus_db`, copy to `public/api/`, commit to `main`), not a Pages-source change. Cut a release tag when promoting a deployment (tagging currently lags the deployed build).

## First executable step: state-general adapter BUILT and validated (2026-06-02)

The `--state` generalization is done and dry-run validated, not just planned. `perseus_integration/ingest_cem_state.R` (also deployed to `~/perseus_db/adapters/` on Cardinal) takes `--state`, an explicit `--csv`, `--model`, `--climate`, and writes the CEM series for any state. A scratch-DB dry-run (copy of `perseus_results.sqlite`, production untouched) ingested a state-expanded CI into the real `WA` slot and produced 2,700 valid rows: 5 scenarios × 12 metrics (the carbon pools, biomass, volume, merch volume, RD, SDI) × 15 years × mean/lo/hi, with the BAU `agc_live_total` series materializing as the exact `[year, value]` contract the explorer renders. Maine behavior is untouched (the original ME adapter is unchanged; this script is additive).

Three things confirmed during validation:

- **Reference tables already exist for the focal states.** `state` has WA/GA/MN; `species_assumption` has `fia_current_WA/GA/MN`; `climate_driver` has the RCP climate ids. So the `scenario_preset` foreign keys are satisfied for WA/GA/MN with no extra setup.
- **State expansion is a prerequisite, per run.** The adapter consumes the state-aggregated CI with the `mmt_*` carbon-pool columns (output of `10_state_expansion.R` / `run_state_expansion_all.R`). The per-run `output/<STATE>_<date>_<tag>/ci_summaries.csv` is per-acre and is NOT a valid input. So each production run needs: projection, then state expansion to `state_<tag>_ci.csv`, then this adapter. The adapter enforces this with a clear error if the `mmt_*` columns are absent.
- **One harvest rule per scenario.** `result_v02`'s UNIQUE key separates rows by `harvest_rule_id`, so the adapter registers a distinct rule per scenario (`cem_bau`, `cem_no_harvest`, `cem_harvest_p50_biomass`, ...). The downstream `48_export_api.py` bucket map (`meta.json` currently exposes two buckets, managed and reserve) is the one export-side item to confirm: either add the new `cem_harvest_*` rules to its rule-to-bucket mapping, or export only `BAU` (managed) and `No_harvest` (reserve) per CEM model for the two-bucket view.

Remaining sequence to publish (gated on production promotion): run state expansion on the production WA/GA/MN runs, run `ingest_cem_state.R --state {WA,GA,MN}` against each `state_<tag>_ci.csv`, run `48_export_api.py`, copy `api/*` to the site `public/api/`, commit to `main`. The adapter is the part that was untested; it is now proven.
