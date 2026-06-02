# CEM Refinement and Extension Plan

**Date:** 2026-05-30
**Author:** A. Weiskittel (CRSF, University of Maine)
**Scope decision:** Finish the four current states (ME, MN, WA, GA) cleanly before adding new states. Build out all four scenario axes (climate ensemble, management, disturbance, policy/economic). Architect for later CONUS expansion without committing to it now.
**Inputs reviewed:** local `fia-cem-maine` repo (R modules, docs, config, figures) and the live Cardinal project at `~/fia_cem_projections` (account PUOM0008), including current queue, output tree, validation and hindcast docs, and `config/state_constants.csv`.

## 1. Where the model stands

The Maine pipeline is the validated core. A 1999 to 2024 subject matched BAU hindcast gives RMSE 16 MMT AGC (about 6% of mean stock) and bias near zero (-2 MMT, -1.1%). r17 is the canonical refined baseline; r18 adds Harris, Caputo, and Butler (HCB) 2025 landowner stratification and is the in flight refinement.

The multistate extension to Minnesota, Washington, and Georgia is far along. The portability audit (`docs/MULTISTATE_PORTABILITY_GAPS.md`) is essentially closed: the HCB by EPA Omernik Level III crosswalk is built (`config/fia_plots_hcb_l3.csv`, ~104k rows, 22 L3 ecoregions), per L3 SDImax lookups replace the Maine only tables, the switch tables in `R/10` and `run_projection.R` carry MN/WA/GA, and the Maine hardcodes in `R/06` are externalized to `config/state_constants.csv`. Production L7b runs exist for all three states at both RCP 4.5 and 8.5, and the sanity bound validations pass.

The hindcasts are where the open scientific problems live:

| State | Hindcast bias vs subject matched FIA | Read |
|---|---|---|
| ME | -2 MMT (-1.1%), RMSE 16 MMT (~6%) | Validated, canonical |
| MN | Sanity bounds PASS; per acre carbon -23% vs ME (expected, lower productivity) | Plausible, hindcast residuals need finalizing |
| WA | -25%, about -79 MMT residual (cycle 4, 2019 EVALID) | Persistent underprediction, not fixed by donor geography |
| GA | +40 MMT (+16%), RMSE 73 MMT (29%) | Overprediction |

Two findings constrain the refinement work. First, the Washington underprediction is a donor growth rate composition problem, not a geographic coverage problem. The CONUS donor experiment was a null (the database was never rebuilt, so the state list change was a no op), and once California donors were genuinely added the projection moved slightly down, because the added donors grow more slowly than west side Washington. Adding geography cannot remedy an underprediction that arises because the existing donor pool already grows more slowly than the subject forest. Second, Georgia runs hot, which is the mirror image problem in a fast growing, plantation dominated, short rotation system where the CEM donor pool and the stationary dead pools both bias the trajectory upward.

Operational state worth noting before any new runs: the project is 63 GB, almost entirely 19 `per_plot_projections.rds` checkpoints at 2 to 3 GB each; a Washington statewide v2 job (`wa_stwide_v2`) is currently running; and the curated repo intentionally keeps the older r20 engine in `R/06`, while Cardinal executes the patched r21/v4 engine from `cem_pipeline_patch/`. That repo to Cardinal divergence is a standing reproducibility risk that this plan addresses directly.

## 2. Refinement track: get the four states defensible

Ordered by scientific leverage, not by effort.

### 2.1 Resolve the Washington underprediction (highest priority)

The donor pool grows too slowly relative to the subject forest, so the fix has to act on growth composition rather than donor membership. Three candidate mechanisms, to be tested in order:

1. **Growth rate weighted donor matching.** Within each CEM cell, weight donor draws by a productivity covariate (site index, BGI, or asymptotic AGB already staged in `config/bgi_by_pltcn.csv` and `config/asym_agb_by_pltcn.csv`) so that fast growing west side donors are not diluted by slow interior or California donors. This is the most direct lever and reuses existing staged data.
2. **Ecoregion productivity stratification refinement.** The L3 key may be too coarse for Washington, where the Coast Range and west Cascades differ sharply from the eastern Cascades and Columbia Plateau. Split the matching key on the west side versus east side Cascades crest, which the `wa_westside_donor_prototype.R` work already prototypes.
3. **Asymptote anchoring.** If 1 and 2 do not close the gap, anchor the projection asymptote to the FIA observed AGB ceiling per cell, the same `--anchored` logic used in the v4 yield curves, rather than letting the donor draw set the ceiling.

Decision gate: rerun the WA hindcast after each mechanism and keep the smallest change that brings the residual inside roughly plus or minus 10%. Do not stack all three blindly.

### 2.2 Diagnose and correct the Georgia overprediction

Georgia is +16% hot. Likely contributors, to be decomposed with the existing `ga_l7b_residual_decomposition.R` and `ga_l7b_cohort_analysis.R` scripts:

1. **Plantation rotation truncation.** Loblolly is rotated on 25 to 35 years (`terminal_age = 80` in `state_constants.csv` is the natural stand value and is too long for the plantation cohort). The harvest choice and terminal age need to be owner and stand origin aware so industrial plantation cells turn over on the real rotation instead of accumulating biomass.
2. **Stationary dead and litter pools.** Holding dead, litter, and soil stationary across 70 years is more defensible in a slow Maine system than in a fast Georgia one where rapid turnover should move those pools. This is a shared refinement (see 2.4).
3. **CO2 fertilization in a moisture limited system.** Norby 2010 CO2 response is productivity not water limited; Georgia growth is often drought limited, so the flat +10% per doubling likely overcredits the Southeast. Make the CO2 multiplier moisture aware or per region.

### 2.3 Finalize r18 HCB landowner stratification across all four states

The Maine landowner integration (Phase 1 atlas) is complete. Carry the per owner class harvest multipliers (NIPF 0.5, Industrial 1.5, Tribal/Federal 0.2, State 0.5, Local 0.3) into MN, WA, GA using the national HCB raster rather than Maine specific values, and confirm the multipliers are not silently Maine calibrated. This directly supports the Georgia plantation fix in 2.1 because the Industrial class is where the rotation truncation matters most.

### 2.4 Activate the non live carbon pools

The seven pool accounting currently evolves only the live pools and holds standing/down dead, litter, and soil stationary. For a 70 year horizon across contrasting systems this is the largest shared structural simplification. Minimum defensible upgrade: let dead and litter pools respond to harvest and disturbance inputs and decay on per region rate constants (Smith et al. 2006 half lives are already cited for wood products). Soil can stay stationary as a documented assumption. This single change moves Washington (accumulating system) and Georgia (turnover system) in opposite, physically correct directions.

### 2.5 Calibrate the climate response per L3 ecoregion

`state_constants.csv` carries per state dT_2099 and a Maine derived temperature response coefficient (`1 + 0.010*dT` with a quadratic penalty). The temperature growth response is still Maine northern hardwood and spruce fir in shape. Replace the scalar with an L3 ecoregion by forest type table calibrated against MACA or ClimateNA ensemble means, so Georgia pine drought response, Washington Douglas fir mixed response, and Minnesota drought sensitive hardwoods each carry their own coefficient. This is prerequisite to trusting the RCP 8.5 divergence and to the climate ensemble scenario axis (3.1).

### 2.6 Per state disturbance modules

The disturbance module is Maine spruce budworm in its phase and species logic. `state_constants.csv` already flags `sbw_relevance` per state but the engine still runs the Maine cycle. Build a `config/disturbance_schedule.csv` keyed by state or L3 with peak phase, intensity, and affected forest types: eastern larch beetle and emerald ash borer for MN, mountain pine beetle and western spruce budworm plus the 10x fire baseline for WA, southern pine beetle and the prescribed versus unintended fire split for GA. This also feeds the disturbance scenario axis (3.3).

## 3. Scenario track: build out all four axes

The current scenario machinery exposes harvest level sets (BAU, no harvest, Q biasing, biomass biasing) and a single climate dimension (HadGEM2-AO RCP 4.5/8.5). All four axes below extend `R/05_scenario_biasing.R` and the climate interface, and each should be expressible as a `--scenario_set` plus a config table rather than new code paths.

### 3.1 Climate ensemble

Move from one GCM and two RCPs to a small CMIP6 ensemble. Target a 3 to 5 GCM by 2 to 3 SSP design (for example SSP2-4.5, SSP3-7.0, SSP5-8.5) so the carbon trajectories carry a climate uncertainty band rather than a single line. Mechanics: parameterize `08_climate_interface.R` to read a `config/climate_scenarios.csv` of dT and CO2 trajectories per GCM by SSP by L3, and add an ensemble loop in the driver. Depends on 2.5 (per region climate response) to be meaningful.

### 3.2 Management scenarios

Expand the harvest set into a management design: rotation length sweeps, retention levels, afforestation and reforestation rates, harvest intensity, and partial versus clearcut shares per owner class. The owner class split from r18 (3.3 above) is the natural axis; the Maine economic overlay already splits partial versus clearcut, so generalize that logic out of `11_economic_harvest.R` into a state agnostic management scenario set. This is also the axis most useful to PERSEUS cross model comparison, since FVS, GCBM, and LANDIS can run the same management definitions.

### 3.3 Disturbance scenarios

Turn the per state disturbance modules (2.6) into a scenario sweep: low, central, and high pest and fire intensity, plus a no disturbance counterfactual. This is the stress test axis and directly addresses reviewer questions about Washington fire and the next spruce budworm outbreak in Maine. Tunables already exist (`insect_amp_mult`, `fire_amp_mult`); the work is wiring them into a named scenario set and documenting the central estimates.

### 3.4 Policy and economic scenarios

Three sub axes: stumpage price trajectories (the Maine forecast infrastructure exists; generalize to per state or hold others at generic Wear and Coulston regional prices), carbon price driven harvest (a harvest probability shifter as a function of an exogenous carbon price), and land use change (afforestation versus development pressure, the `maine_land_use_scenarios()` set generalized). Keep the Maine specific BPL easement and land use sets behind their current names and add generic versions only where a policy question is defined.

## 4. Extension track: architect now, expand later

Per the scope decision, no new state runs until the four are defensible. But the refinements above should be built state agnostic so the eventual expansion is data prep, not code. Concretely:

- Finish externalizing the last Maine only modules: `R/11_economic_harvest.R` (county lookup, stumpage, treatment proportions) behind a `--no_econ` default for non Maine states, and rename the generic scenario functions (`maine_harvest_scenarios()` is already generic) so nothing reads as Maine specific.
- Keep every new lookup keyed on L3 ecoregion and HCB class, both of which already span CONUS, rather than on state. The per plot L3 join (Option B in the portability audit) removes the per state ecoregion default entirely and is the right long term key.
- Maintain the per state data recipe as a documented, repeatable sequence: FIA RDS cache, ClimateNA pull, county harvest logit offset, smoke test against EVALIDator, production. The MN/WA/GA path already exercised this; capture it as a script so a new state is a config and a submit, not a porting exercise.
- The county harvest logit offset (step 7 in the audit) remains NOT STARTED for MN/WA/GA; build it as part of finishing those three, since it feeds both refinement (harvest realism) and any later state.

When breadth does come, the natural next tier is one representative state per uncovered RPA region (for example NC or AL for the Southeast natural pine, OR for west side conifer, WI for Lake States), then CONUS by ecoregion.

## 5. Infrastructure and reproducibility

These are not optional housekeeping; they gate trust in the numbers.

- **Reconcile the repo and Cardinal engines.** Cardinal runs `cem_pipeline_patch/06_projection_engine.R` (r21/v4) while the repo `R/06` is the older r20 baseline. Promote the patched engine into the canonical `R/` tree (or document the patch as the canonical deployment step) so the committed code matches what produced the results. Do this before the manuscript numbers are locked.
- **Validation harness.** `scripts/validate_template.R` already produces the 8 check sanity validation. Wrap it plus the hindcast comparison into a single per state, per scenario report that runs automatically after every production job, so regressions surface immediately. This is the unit test layer the pipeline currently lacks.
- **Disk cull.** 19 `per_plot_projections.rds` checkpoints at 62 GB. After state expansion aggregation is confirmed, cull superseded checkpoints with confirmation, keeping the latest canonical run per state per RCP. The 20 May Washington null result shows why md5 and provenance tracking on these matters.
- **Repo sync.** The local clone and Cardinal have diverged across many `.bak` and `.preupdate` files. A clean sync (the `weekly-repo-sync` cadence exists) plus a tagged r18 release once the four states are defensible gives a citable baseline for the methods note.

## 6. Sequencing

Phase boundaries are decision gates, not calendar dates.

**Phase A. Lock the engine and the pools.** Reconcile repo and Cardinal engines (5.1), activate dead/litter pools (2.4), wire the automatic validation harness (5.2). Rerun all four states both RCPs as the new baseline. Gate: all four hindcasts regenerated against one engine.

**Phase B. Fix the two outliers.** Washington donor growth weighting (2.1) and Georgia plantation rotation and CO2 moisture correction (2.2), with r18 landowner stratification finalized across states (2.3). Gate: WA and GA residuals inside roughly plus or minus 10 to 15%.

**Phase C. Climate and disturbance realism.** Per L3 climate response calibration (2.5) and per state disturbance modules (2.6). Gate: RCP 8.5 divergence and disturbance effects defensible per region.

**Phase D. Scenario build out.** Climate ensemble (3.1), management (3.2), disturbance (3.3), and policy/economic (3.4) scenario sets, each as a `--scenario_set` plus config table. Gate: a four state by ensemble by management matrix runnable from one submit pattern.

**Phase E. Manuscript and release.** Populate the multistate paper abstract and Section 3.5 with the corrected narrative (donor growth composition, not geography, binds Washington), tag the r18 release, archive the data and code (`data-curator` for the FAIR package). The extension architecture (Section 4) is carried as future work.

## 7. Open decisions for Aaron

1. **WA fix order.** Confirm starting with growth rate weighted donor matching (2.1, mechanism 1) before the west/east Cascades key split. Recommended because it reuses staged BGI/asymptote data and is the most direct lever.
2. **Soil pool.** Confirm holding soil organic carbon stationary as a documented assumption while activating dead and litter (2.4), versus committing to a soil dynamics module now.
3. **Climate ensemble size.** Confirm the GCM by SSP grid (suggest 3 GCMs by 3 SSPs as the default; larger ensembles multiply compute and disk).
4. **PERSEUS alignment.** Whether the management scenario definitions (3.2) should be frozen to match the FVS, GCBM, and LANDIS cross model comparison before building them here, so all four models run identical scenarios.
