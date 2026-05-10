# Multistate Portability Gaps: MN, WA, GA

**Date:** 8 May 2026
**Author:** A. Weiskittel (compiled from session audit)
**Status:** Audit and gap inventory. No code changes yet. Cross stratification target: HCB ownership × EPA Omernik Level III ecoregion.

## Scope

Target states for expansion beyond Maine:

* MN (Minnesota), STATECD 27
* WA (Washington), STATECD 53
* GA (Georgia), STATECD 13

Target stratification scheme: Harris Caputo Butler 2025 ownership classes (8 categories) crossed with EPA Omernik Level III ecoregions. This replaces the current Maine specific stratification (Acadian Plains and Hills default ecoregion plus county lookups).

## Section 1. Switch tables that need state additions

These are the concrete, surgical fixes. Each is a one line edit.

### 1a. `cem_pipeline_patch/run_projection.R`, function `get_donor_states()`, lines 440 to ~460

**Audit correction (2026-05-09):** the original audit said WA was missing entirely. It is not. WA exists at line 455 with `WA = c("WA", "OR", "ID")`, and OR exists at line 454. The only gap is that WA's neighbor list is missing MT. ME, MN, GA, OR, WA all have neighbor lists already.

Applied: WA neighbor list extended to include MT.

```r
WA = c("WA", "OR", "ID", "MT")
```

### 1b. `R/10_state_expansion.R`, `build_sdimax_lookup()` state name switch, line 113

Currently covers ME, NH, VT, NY, MA, CT, RI, PA. Falls back to abbreviation when no match. Add:

```r
"MN" = "Minnesota", "WA" = "Washington", "GA" = "Georgia",
```

### 1c. `R/10_state_expansion.R`, `expand_to_state()` STATECD switch, line 174

Currently covers ME (23), NH (33), VT (50), NY (36) only. Anything else returns NA, which silently breaks the STATECD filter. Add:

```r
"MN" = 27L, "WA" = 53L, "GA" = 13L,
```

### 1d. `R/01_data_prep.R` `state_fips` table

Already covers MN, GA, WA. No change needed. Confirmed.

## Section 2. Hardcoded Maine constants in R/06_projection_engine.R

These are the real risk. Code runs without error on a non Maine state but uses Maine values silently.

### 2a. HadGEM2-AO climate warming (lines 379 to 415)

```r
dT_2099 <- switch(as.character(rcp),
                   "4.5" = 2.5,    # Maine moderate warming
                   "8.5" = 4.5,    # Maine high warming
                   0)
```

Maine values for both RCPs. CO2 trajectories are global, fine. Need per state warming targets:

| State | RCP 4.5 dT 2099 (approx) | RCP 8.5 dT 2099 (approx) | Source |
|---|---|---|---|
| ME | 2.5 | 4.5 | Current Maine values |
| MN | 2.8 | 5.2 | NCA5 Midwest, more continental warming |
| WA | 2.0 | 3.8 | NCA5 Northwest, marine moderation |
| GA | 2.2 | 4.0 | NCA5 Southeast |

These need calibration against MACA or ClimateNA ensemble means for each state. Right now they need to live in `config/state_climate_constants.csv` keyed by state and RCP, replacing the hardcoded switch.

### 2b. Temperature growth response (lines 404 to 410)

```r
# Temperature only effect: empirical Maine forest growth response per
# degree C warming
temp_mult <- if (rcp == 4.5) 1 + 0.010 * dT
             else            1 + 0.010 * dT - 0.003 * pmax(0, dT - 3)^2
```

Maine northern hardwood and spruce fir response. Southern (GA) and western (WA) forests respond differently. GA pine plantations are productivity limited by drought, not temperature. WA Douglas fir is mixed (coastal vs inland Cascades). MN northern hardwoods are similar to ME but with more drought sensitivity.

Recommend: replace with state and forest type table or per L3 ecoregion table.

### 2c. Wildfire baseline 0.5% per cycle (line 556)

```r
fire_p_per_cycle <- 0.005 * fire_climate_mult * (cfg$fire_amp_mult %||% 1.0)
```

Maine baseline. Realistic per state baselines (per cycle, 5 yr):

| State | Annual fire prob | Per cycle (5 yr) | Source |
|---|---|---|---|
| ME | 0.001 | 0.005 | Current value |
| MN | 0.002 | 0.010 | MN DNR fire stats |
| WA | 0.012 | 0.060 | DNR + USFS, much higher |
| GA | 0.008 | 0.040 | GFC stats, Rx fire common but unintended fire moderate |

WA wildfire risk is roughly 10x Maine. This will be the biggest constant correction needed.

### 2d. Spruce budworm cycle and species lists (lines 451 to 465)

```r
sf  <- c(121L, 122L, 123L, 124L, 125L, 126L)               # spruce-fir
nh  <- c(701L, 801L, 802L, 803L, 805L, 809L)               # northern hardwood
oak <- c(381L, 501L, 502L, 503L, 505L, 509L, 513L, 519L)   # oak
```

The forest type code lists are universal FORTYPCD values (FIA codes). Coverage is fine for any state. **However** the spruce budworm logic is Maine specific (30 yr cycle peak in 2030 to 2040 based on the 1970s outbreak). For:

* MN: budworm cycle peaks differ from Maine; the relevant pest is more often eastern larch beetle and emerald ash borer
* WA: no spruce budworm; relevant pests are mountain pine beetle, western spruce budworm (different species)
* GA: no spruce budworm; relevant pests are southern pine beetle, redbay ambrosia beetle

The disturbance module needs either a per state pest list or a config CSV with peak phase, intensity, and affected forest types.

### 2e. Default SDImax 440 trees per acre (line 628)

```r
GLOBAL_SDIMAX_DEFAULT_ENG <- 440  # Maine northern hardwood-conifer mean
```

This is the fallback when ecoregion lookup fails. Maine northern hardwood and conifer mean. Other states have different means:

* MN northern hardwoods: ~480
* WA Douglas fir: ~600 to 700
* GA loblolly pine plantations: ~350 to 400

Should be replaced with a per state default in `config/sdimax_state_defaults.csv` or computed from the L3 ecoregion lookup directly.

## Section 3. Maine only modules

### 3a. R/11_economic_harvest.R — entirely Maine specific

| Element | Maine only? | Action for MN/WA/GA |
|---|---|---|
| `MAINE_COUNTY_LOOKUP` (16 county tibble) | Yes | Need MN, WA, GA county lookups |
| `.maine_stump_cache` env | Yes | Need state caches |
| `load_maine_stumpage()` reads `maine_stumpage_forecast.csv` | Yes | Need stumpage forecast per state |
| `load_maine_proportions()` reads `maine_treatment_proportions.csv` | Yes | Need treatment proportions per state |
| `maine_prices_for_year()` | Yes | Generic version takes state arg |
| `split_partial_clearcut()` | Yes | Generic logic but data is Maine SAR |

**Recommendation:** for MN, WA, GA initial runs, **disable the economic overlay** via `--no_econ`. The Wear and Coulston regional model handles Northeast, Midwest, Pacific Northwest, and Southeast natively, so generic prices work. Building state specific economic overlays is a separate, larger task. The MN and WA stumpage data infrastructure exists (DNR + DNRC reports) but GA stumpage is dispersed across SC/GA/AL TimberMart South. Defer.

### 3b. R/05_scenario_biasing.R — scenario sets all `maine_*`

Currently exposed:
* `maine_harvest_scenarios()` ← labeled Maine but actually generic Q biasing values
* `maine_policy_scenarios()` ← Maine BPL conservation easement specific
* `maine_land_use_scenarios()` ← Maine afforestation rates and development pressure

**Recommendation:** rename `maine_harvest_scenarios()` to `harvest_scenarios()` (it is generic). Keep the Maine policy and land use sets behind their current names. Add equivalent `policy_scenarios_<state>` and `land_use_scenarios_<state>` only when state policy questions are defined.

For initial MN/WA/GA runs, the `harvest`, `bau`, `climate_proxy` sets are sufficient.

## Section 4. Maine specific config CSVs

These exist on origin. Equivalents needed for MN, WA, GA:

| File | Purpose | Multistate path |
|---|---|---|
| `config/maine_county_harvest_logit_offset.csv` | County level offset added to Wear and Coulston harvest probability | Build per state from FIA harvest event rates by county |
| `config/maine_county_harvest_calibration.csv` | County stratification calibration for the projection engine | Build per state |
| `config/maine_ownership_atlas.csv` | Owner level harvest behavior atlas | Generic via HCB; rename to `hcb_ownership_atlas.csv` and use national values |
| `config/maine_ownership_statewide_summary.csv` | Statewide owner area totals for reporting | Replace with `<state>_ownership_summary.csv` per state |
| `config/maine_yield_curve_strata.csv` | Yield curve stratification (HCB × ecoregion × forest type) | This is the actual cross stratification we want; rename to `yield_curve_strata.csv`, expand to all states |
| `config/maine_stumpage_forecast.csv` | County stumpage forecasts | Keep Maine only; non Maine runs use `--no_econ` |
| `config/maine_treatment_proportions.csv` | Partial vs clearcut shares | Keep Maine only; non Maine runs use `--no_econ` |

The most important single file is `maine_yield_curve_strata.csv`. This is already structured around the HCB × ecoregion × forest type cross. Generalizing it to use L3 ecoregion (instead of Maine ecoregions) and expanding to MN, WA, GA is the central data prep task.

## Section 5. Ecoregion data: SDImax lookups currently Maine only

`config/sdimax_by_ecoregion.csv` has only 5 rows, all Maine ecoregions:
* Acadian Highlands
* Central Maine
* (3 more)

`config/sdimax_by_fortype_group_maine.csv` has Maine forest type group means.

**For HCB × L3 ecoregion approach, need to rebuild as:**

`config/sdimax_by_l3_ecoregion.csv` with columns:

```
us_l3code, us_l3name, fortype_group, n_plots, sdimax_m_mean, sdimax_e_mean, sdimax_e_p10, sdimax_e_p90
```

Coverage required:

| State | L3 ecoregions to cover (estimated) |
|---|---|
| ME | 4 (Acadian Plains and Hills, Acadian Highlands, etc.) |
| MN | 5 (Northern Lakes and Forests, North Central Hardwood Forests, Northern Glaciated Plains, Western Corn Belt Plains, Driftless Area) |
| WA | 8 (Puget Lowland, North Cascades, Cascades, Eastern Cascades Slopes, Columbia Plateau, Blue Mountains, Northern Rockies, Coast Range) |
| GA | 6 (Piedmont, Southeastern Plains, Southern Coastal Plain, Blue Ridge, Ridge and Valley, Southwestern Appalachians) |

Total: roughly 23 L3 ecoregions across the 4 states. Each row needs FIA based SDImax estimation following Woodall and Weiskittel 2021 methodology applied per L3 ecoregion.

## Section 6. Default ecoregion hardcode

`R/10_state_expansion.R` line 109:

```r
build_sdimax_lookup <- function(state = "ME",
                                sdimax_csv,
                                fortype_csv,
                                default_ecoregion = "Acadian Plains and Hills") {
```

Hardcoded Maine fallback. **Two options:**

* **Option A (small refactor):** add `default_ecoregion_by_state` table:
  ```r
  default_l3 <- switch(state,
    "ME" = "Acadian Plains and Hills",
    "MN" = "Northern Lakes and Forests",
    "WA" = "Cascades",
    "GA" = "Piedmont",
    NA_character_)
  ```
* **Option B (better):** join FIA plot table to L3 ecoregion polygons, every plot gets its own L3 attribute, no state level default needed. The lookup then keys directly on per plot L3 code.

Option B is the right long term answer and aligns with the HCB × L3 cross goal.

## Section 7. Data inventory on Cardinal

What exists for the four states:

| Asset | ME | MN | WA | GA |
|---|---|---|---|---|
| FIA CSVs (PLOT, COND, TREE, POP_*, etc., 11 tables) | yes | yes | yes | yes |
| `fia_db_<STATE>.rds` cached | yes | no | no | no |
| ClimateNA pull | `climatena_input_ME.csv` | none | none | none |
| Plot location CSV | `plot_locations_ME.csv` | none | none | none |
| HCB ownership raster | `US_forest_ownership.tif` covers all CONUS, including all four | covered | covered | covered |
| L3 ecoregion polygons | `Disturbance/us_eco_l3_state_boundaries.shp` covers all CONUS | covered | covered | covered |
| HCB × FIA plot crosswalk CSV | `fia_plots_with_owner.csv`, all 6289 rows STATECD=23 | absent | absent | absent |

## Section 8. Concrete next steps in dependency order

These are listed so each step's prerequisites are above it.

1. **Build per state HCB × L3 plot crosswalk.** Run a small R script using `terra` or `sf` to extract HCB ownership class and L3 ecoregion code at each FIA plot location for ME, MN, WA, GA. Output: `config/fia_plots_hcb_l3.csv` with columns `STATECD, COUNTYCD, PLOT, INVYR, LAT, LON, PLT_CN, hcb_class, us_l3code, us_l3name`. This is the foundational join table everything else needs.

2. **Generate per state FIA RDS caches.** Run `osc/00_download_data.R` for MN, WA, GA. Each takes maybe 30 to 60 minutes on a Cardinal login node. The script is already state aware via the `state` argument.

3. **Pull ClimateNA for non Maine plots.** Same shape as ME pull (`osc/01_download_climate.R`). Output: `climatena_input_<STATE>.csv`, `plot_locations_<STATE>.csv`. This unblocks decoupled climate runs.

4. **Build `config/sdimax_by_l3_ecoregion.csv`.** Following Woodall and Weiskittel 2021 methodology, fit SDImax per L3 ecoregion × forest type group across all four states' FIA tree lists. Roughly 23 ecoregions × 6 to 8 forest type groups means 140 to 180 rows. This replaces all five `sdimax_by_*.csv` Maine variants and the per state ecoregion default.

5. **Refactor switch tables (Section 1).** Three one line edits in `R/10_state_expansion.R` and `cem_pipeline_patch/run_projection.R`. Smallest code change of the whole effort.

6. **Externalize Maine constants from R/06.** Move climate dT, wildfire baseline, SDImax default, and forest type response coefficients to `config/state_constants.csv`. Replace switch statements in R/06 with table reads keyed by `cfg$target_state`.

7. **Build per state county harvest logit offset.** Apply the same Maine R12 calibration approach to MN, WA, GA county FIA data. Output: `config/<state>_county_harvest_logit_offset.csv`. Make `R/03` look up by `cfg$target_state`.

8. **Smoke test runs.** One short run (n_sims=10, cycles=3, 30 minute walltime) per state. Goal: confirm the pipeline runs to completion, identify any silent Maine fallbacks not caught in the audit. Compare statewide AGC totals against published FIA EVALIDator state estimates as sanity check.

9. **Production runs.** After smoke tests pass, run the standard `submit_<state>_wear_r21.sh` per state per RCP. Each run should produce the same artifact pattern as the May 5 ME r21 run.

## Section 9. What is NOT a portability gap

For the record:

* **R/01 data prep:** state_fips table covers all 32 eastern, midwestern, southern states including all targets. `read_fia_direct()` is state agnostic.
* **R/02 CEM matching:** purely on FIA attributes (FORTYPCD, OWNGRPCD, SLICE, SITECLCD). No state hardcoded values.
* **R/04 planting model:** Wear and Coulston 2025 logistic with regional coefficients. Generic.
* **R/07 timber supply:** generic.
* **R/08 climate interface:** generic; reads whatever climate CSV is provided.
* **R/09 reporting:** generic.
* **R/14 final figure:** Maine specific in title and panels but easy to template.

These pieces work as is for any state.

## Section 10. Risk inventory

Three things that could surprise you on first non Maine run:

* **Silent Maine values.** R/06 climate dT and wildfire baseline have no warning if the target state is not ME. A WA run will produce a 10x lower wildfire frequency than reality. Externalizing these (Section 8 step 6) is required before trusting outputs.
* **`get_donor_states()` for WA returns only WA.** Without OR, ID, MT in the donor list, the CEM pool is restricted to in state donors only, which thins matching. Easy fix per Section 1a.
* **Default ecoregion fallback in `build_sdimax_lookup()`.** Falls back to "Acadian Plains and Hills" which does not exist in non Maine SDImax data. The result is everyone falls through to the global mean, eliminating the ecoregion stratification entirely. Section 6 fix is required.

---

## Section 11. Progress log (added 2026-05-09)

| Step | Status | Notes |
|---|---|---|
| 1. HCB x L3 plot crosswalk | DONE | `config/fia_plots_hcb_l3.csv`, 104,628 rows, 22 L3 ecoregions touched. Built by `scripts/build_hcb_l3_crosswalk.R` against `~/FIA/ENTIRE_PLOT.csv` and `~/Disturbance/us_eco_l3.shp`. Per-state HCB-classified % runs 33 to 56; HCB-FIA agreement varies 41 to 74%, highest in MN. |
| 2. Per-state FIA RDS caches | IN FLIGHT | `scripts/download_donor_states.sh` running on Cardinal login node 2026-05-09 21:25 EDT. Routes writes to `~/FIA` (scratch, 0 quota impact) via `OSC_PROJECT_DIR`. Order: MN, WA, GA. Unblocks all three smoke tests. |
| 3. Plot locations + ClimateNA inputs | DONE | `~/FIA/climate/plot_locations_<STATE>.csv` and `~/FIA/climate/climatena_input_<STATE>.csv` for all 4 states. Built by `scripts/extract_plot_locations.R`. ClimateNA itself runs externally; outputs land back in `~/FIA/climate/<STATE>/`. |
| 4. SDImax by L3 ecoregion | DONE | Five new lookup CSVs: `sdimax_by_l3_ecoregion.csv` (22 rows), `sdimax_by_l3_typgroup.csv`, `sdimax_by_l3_typgroup_compact.csv`, `sdimax_by_typgroup.csv`, `sdimax_by_state_l3.csv`. PNW peaks (1300+ trees/ha for Cascades, Coast Range), prairie transitions ~700, MN northern hardwoods ~830. Replaces Maine-only `sdimax_by_ecoregion.csv` and `sdimax_by_fortype_group_maine.csv`. |
| 5. Switch-table edits | DONE | Three surgical edits committed: `R/10_state_expansion.R` `build_sdimax_lookup()` adds MN/WA/GA state names; `R/10_state_expansion.R` `expand_to_state()` adds STATECDs 27/53/13; `cem_pipeline_patch/run_projection.R` `get_donor_states()` extends WA neighbors to include MT. Audit correction: WA was already in `get_donor_states()` (with OR, ID), not entirely missing as originally stated. |
| 6. Externalize Maine constants from R/06 | DONE | New `config/state_constants.csv` keyed by state. Three switch statements in `06_projection_engine.R` now read from it: HadGEM2-AO RCP 4.5 / 8.5 dT_2099, wildfire baseline per cycle, default global SDImax (English). New helper `get_state_constants(cfg)` cached on `.GlobalEnv$.STATE_CONSTANTS`. Falls back to ME defaults on lookup miss. ME row preserves the exact original values. WA wildfire 0.060/cycle (10x ME); MN 0.010 (2x); GA 0.040 (8x). |
| 7. Per-state county harvest logit offset | NOT STARTED | Maine version `config/maine_county_harvest_logit_offset.csv` was built by `scripts/build_county_harvest_lookup.R` from FIA harvest event rates. Multistate version needs analogous CSVs for MN, WA, GA. Blocked on step 2 completion. |
| 8. Smoke test runs | BLOCKED -> UNBLOCKING | First MN smoke (job 9292743) failed because compute nodes lack internet for rFIA::getFIA(). Step 2 produces the per-cohort RDS files; once present, `run_projection.R` line 297 auto-upgrades from `--fia_access rfia` to `rds` mode, no submit-script changes needed. Resubmit after MN/WA/GA RDS files land. |
| 9. Production runs | BLOCKED | Blocked on 8. |

## Section 12. Findings discovered while implementing

These didn't appear in the original audit but surfaced during implementation.

### 12a. FIA data architecture gap

`~/FIA/ENTIRE_TREE.csv` is **not present** on Cardinal as of 2026-05-09. Only `ENTIRE_TREE_GRM_THRESHOLD.csv` and `ENTIRE_TREE_WOODLAND_STEMS.csv` exist there. The base TREE table (DBH, HT, SPCD, TPA_UNADJ, ...) lives only as per-state `<STATE>_TREE.csv` files in `~/fia_data/`. Coverage at session start:

* Full 11-table set: ME, NH, VT, NY, MN, WA, GA
* Partial (6 tables): MA, CT, RI
* Sparse (2 tables, COND + TREE only): OR, ID, MT, FL, SC, TN, AL
* Missing entirely: WI, MI, IA, NC

The download driver currently running fills the gap for MN/WA/GA donor pools.

### 12b. Cardinal's FIA shapefile name

The L3 ecoregion shapefile on Cardinal is `~/Disturbance/us_eco_l3.shp` (full set: .shp + .dbf + .shx + .prj + .sbn + .sbx + .shp.xml). The audit originally referred to `us_eco_l3_state_boundaries.shp` based on a `.dbf` file with that base name; that .dbf is a standalone attribute join lookup and has no associated geometry. First crosswalk job (9282082) failed with `file.exists(L3_SHP) is not TRUE`; corrected in commit 4c53e5f.

### 12c. Local repo location

The actual local clone of `holoros/fia-cem-maine` lives at `~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching/` (note hyphenated folder name and CRSF-Cowork parent), not at the previously assumed `~/Documents/Claude/fia_plot_matching/`. The repo has 30+ commits of curated history including manuscript materials, MEMORY logs, and `cem_pipeline_patch/` deltas.

### 12d. Curated repo strategy

`R/06_projection_engine.R` in the curated repo is intentionally the older r20 baseline. The newer r21 / v4 productivity multiplier code lives in `cem_pipeline_patch/06_projection_engine.R`. Cardinal runs the patched version (it copies cem_pipeline_patch over R/ at deployment). The Section 6 externalization landed in `cem_pipeline_patch/06_projection_engine.R` (the version Cardinal actually executes); R/06 keeps the original Maine hardcodes as the historical baseline.

---

End of audit.
