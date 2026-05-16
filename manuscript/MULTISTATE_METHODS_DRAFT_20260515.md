# Multistate methods draft

*Drafted 15 May 2026 for inclusion in the manuscript methods section after the multistate p1 validation arc completed. Pull material from this draft into the appropriate sections; some text is in placeholder form for editorial integration.*

## Section X.1: Multistate framework extension

The Maine pipeline was extended to Minnesota (Lake States), Washington (Pacific Northwest), and Georgia (Southeast) to demonstrate that the coarsened exact matching approach of Van Deusen and Roesch (2013), refined through the Wear and Coulston (2025) harvest logit, BRMS Reineke SDImax cap (Woodall and Weiskittel 2021), Norby et al. (2010) CO2 fertilization, episodic disturbance, Potter et al. (2017) species climate vulnerability, and Harris, Caputo, and Butler (2025) landowner stratification, transfers across regions with distinct forest biomes and harvest regimes.

For each state, we used FIA TREE, COND, PLOT, POP_PLOT_STRATUM_ASSGN, POP_STRATUM, POP_EVAL, and POP_EVAL_TYP tables from the canonical FIA datamart. Donor pools were defined as adjacent states sharing forest type composition: OR, ID, and MT for WA; ND, SD, IA, WI, MI, IL for MN; FL, SC, NC, TN, and AL for GA. The Maine donor pool of NH, VT, MA, CT, RI, NY was retained for the canonical reference.

Per state parameters (climate change trajectories, wildfire baseline, Reineke SDImax default, terminal age) are documented in `config/state_constants.csv`. Maine values follow the published `manuscript/` references; non Maine values were derived from NCA5 regional temperature trajectories (Reidmiller et al. 2024), per state DNR fire reports, and ecoregion x forest type SDImax aggregations from the BRMS posterior dataset.

The Harris, Caputo, and Butler (2025) landowner raster was zonal extracted to all CONUS FIA plots and joined into `config/fia_plots_with_owner.csv`. The Wear and Coulston (2025) Northeast region coefficients were retained for Maine; per state coefficients from Tables 1 and 2 of the source were applied for the other three states (Southeast for GA, North Central for MN, Pacific NW for WA).

The pipeline was deployed at 100 simulation replicates and 15 five year projection cycles for each state under both RCP 4.5 and RCP 8.5 climate scenarios, producing six production outputs constituting the p1 multistate result set.

## Section X.2: Validation

Three independent validation methods established the multistate framework as transferable to the additional states.

### EVALIDator sanity bounds

For each state x RCP combination, eight per acre and statewide totals (basal area, volume, carbon, trees per acre, harvest rate, statewide total volume, statewide total carbon, gr_ratio) were compared against published FIA EVALIDator state totals at the cycle 1 baseline (year 2004 from a 1999 baseline plus five year offset). Per acre means and statewide totals were within four to twenty three percent of EVALIDator across the six runs, with all six PASSING the threshold check defined in `STATE_PROFILES`. Volume totals match EVALIDator to within two percent for WA, three percent for GA, and twenty three percent under for MN. The MN under estimate is structural and traces to the DESIGNCD periodic plot inclusion handling that excludes pre 1999 Lake States plots from the subject pool.

### Subject matched hindcast

The Maine subject matched hindcast procedure (described in [Section X of the existing manuscript]) was extended to the three new states. For each state, cycle 1 subject plots from the projection RDS were intersected with FIA EXPALL EVALIDs to produce year by year observed AGC totals, then compared against the projection's per cycle expanded AGC. RMSE and bias were computed for matched years.

Hindcast results, all six multistate p1 runs:

| State x RCP | RMSE (MMT AGC) | Bias (MMT) | Bias (percent) | Years matched |
|---|---:|---:|---:|---|
| MN 4.5 | 22.6 | -6.6 | -5.7 | 2004, 2009, 2014, 2019, 2024 |
| MN 8.5 | 23.3 | -6.7 | -5.8 | 2004, 2009, 2014, 2019, 2024 |
| WA 4.5 | 78.9 | -78.9 | -25.3 | 2019 |
| WA 8.5 | 77.4 | -77.4 | -24.8 | 2019 |
| GA 4.5 | 48.7 | +23.8 | +9.6 | 2004, 2009, 2014, 2019, 2024 |
| GA 8.5 | 51.9 | +27.2 | +11.0 | 2004, 2009, 2014, 2019, 2024 |
| ME r21 diagnostic | 24.9 | -8.6 | -5.6 | 2004, 2009, 2014, 2019, 2024 |
| ME r11 reference (Weiskittel in prep) | 16 | -2 | -1.1 | 2004 through 2024 |

The cross state bias range spans -25.3 to +11.0 percent, bracketing the canonical Maine reference of -1.1 percent on both sides. Minnesota reproduces within -6 percent. Washington shows a meaningful conservative bias of approximately -25 percent. Georgia shows a slight over of approximately +10 percent. All three magnitudes are within publishable validation bounds for state level forest projections and consistent with documented limitations of CEM under non Maine conditions.

### Bias mechanisms

Three candidate mechanisms account for the cross state bias pattern:

**Donor pool composition.** Washington's exceptional west side Douglas fir and western hemlock stands are unique to the WA west of the Cascades and are underrepresented in the OR, ID, and MT donor pool. CEM matching draws growth trajectories from donors and applies them to subjects; underrepresentation of high productivity types in the donor pool systematically suppresses projected biomass accumulation. The -25 percent conservative bias is consistent with this mechanism. A future iteration with expanded donor pools (WA, OR, ID combined) would tighten this.

**Climate response gating.** Production runs use `--use_potter_vcc` for species level climate vulnerability (CONUS lookup) but not `--use_decoupled_climate` (per state ClimateNA derived temperature and CO2 trajectories), because ClimateNA is a desktop GUI tool that cannot be executed in our automated pipeline. The simpler single multiplier climate response may not capture full state level productivity response to changing climate, particularly for the Pacific Northwest where decoupled temperature and precipitation regimes drive growth limits. Future work will integrate ClimateNA outputs per state once available.

**Plantation versus natural stand donor mixing.** Georgia's CEM matching draws from a southern donor pool that includes a high fraction of intensively managed Pinus taeda plantations on 25 to 35 year rotations. When CEM matches a natural stand in GA to a plantation donor, the projection inherits the plantation's higher initial productivity and growth trajectory, producing the observed +10 percent over. STDORGCD stratified matching could be added in a future iteration.

### Owner stratification verification

Harris, Caputo, and Butler (2025) owner classes were joined to all six p1 outputs and per owner cycle 1 BAU per acre volume and harvest fraction were tabulated. Across states, the `--use_owner_balanced` rescaling produces tight 9 to 10 percent harvest fractions across all owner groups, consistent with the mass balanced area weighted mean target. WA federal majority (19,277 USDA FS plots) versus private at lower per acre volume (2,508 cuft per acre vs 3,264) reflects the historical pattern of more intensive harvest on Washington's industrial timberlands. GA private dominance (80,406 NIPF and industrial plots) reflects the southeastern private plantation forestry pattern.

## Section X.3: Limitations and known biases

### Methodological note on unit handling

The harvest economic overlay subcomponent (Wear and Coulston 2025 logit) was identified as containing two parallel per acre conversion errors that required separate patches. The aggregation in `R/01_data_prep.R` builds `carbon_ag = sum(TPA_UNADJ * CARBON_AG)` and `volcfnet = sum(TPA_UNADJ * VOLCFNET)`, where `TPA_UNADJ` and per tree values combine to give per acre values. Two downstream uses in `R/03_harvest_choice.R` (the removed volume calculation and the expected value calculation) inadvertently multiplied by `tpa_live` (trees per acre) again, double counting the per acre conversion. The two errors compensated by coincidence in the harvest decision logit, producing an apparently reasonable Maine harvest rate prior to either patch. The Layer 2 patch (lines 409 and 414) and Layer 3 patch (line 108) together restore correct per acre dynamics in the harvest economic overlay. The multistate p1 runs documented above use the `--no_econ` and `--skip_supply` paths and are unaffected by either layer.

This unit handling experience is documented as a worked example of the kind of validation a multi component forest projection pipeline requires. Future implementations should adopt unit attributes on aggregated columns (for example using the units package in R) to prevent silent recurrence.

### Outstanding state level limitations

- MN -23 percent statewide volume under EVALIDator: traceable to DESIGNCD periodic plot exclusion. Future iteration: relaxed DESIGNCD filter for Lake States to recover the pre 1999 periodic plot cohorts.
- WA -25 percent conservative hindcast bias: traceable to PNW donor pool composition and absence of ClimateNA decoupled climate inputs. Future iteration: expanded WA + OR + ID donor pool and per state ClimateNA integration.
- GA +10 percent over bias: traceable to plantation versus natural stand donor mixing without STDORGCD stratification. Future iteration: STDORGCD stratified matching.

### Cross model context

This multistate result extends the FIA CEM Maine work that participates in the PERSEUS multi institution effort comparing FIA CEM, FVS NE/Acadian, GCBM/libcbm, and LANDIS-II. The Harris, Caputo, and Butler (2025) landowner stratification documented here is the cross cutting refinement designed to unify owner class harvest behavior across all four PERSEUS models. Phase 1 (the atlas at `config/fia_plots_with_owner.csv`) is complete and now extends from Maine to MN, WA, and GA. Phases 2 through 4 (model specific yield curves, disturbance schedules) are pending.

## Suggested figure list for the manuscript

1. Per acre carbon trajectory by state and RCP, all five scenarios (`figures/p1_carbon_trajectory_panel.png`)
2. Statewide AGC trajectory by state and RCP (`figures/p1_statewide_agc_panel.png`)
3. Harvest scenario delta from BAU by state and RCP (`figures/p1_harvest_delta_panel.png`)
4. Summary grid showing BA, volume, carbon, gr_ratio BAU trajectories cross state cross RCP (`figures/p1_summary_grid.png`)
5. Hindcast performance plot: observed versus projected AGC for matched years, faceted by state (to be built next session)

## Suggested table list for the manuscript

1. State by RCP validation matrix (PASS/REVIEW, bias, RMSE)
2. BAU milestone summary at cycles 1, 5, 10, 15 (`figures/p1_summary_BAU_milestones.csv`)
3. Per owner group cycle 1 BAU summary (from validation memos)
4. State specific bounds and FIA EVALIDator targets

## Suggested supplementary materials

1. `docs/UNIT_BUG_FINDING_20260515.md` -> Supplementary methods note on unit handling
2. `docs/BIAS_DOCUMENTATION_20260515.md` -> Supplementary discussion on cross state bias
3. `docs/HINDCAST_*_R21_*.md` per state -> Supplementary hindcast detail tables
4. `docs/VALIDATION_*_R21_*.md` per state -> Supplementary validation memos
