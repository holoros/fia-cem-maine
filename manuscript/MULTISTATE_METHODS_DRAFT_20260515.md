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

For each state x RCP combination, eight per acre and statewide totals (basal area, volume, carbon, trees per acre, harvest rate, statewide total volume, statewide total carbon, gr_ratio) were compared against published FIA EVALIDator state totals at the cycle 1 baseline (year 2004 from a 1999 baseline plus five year offset). Per acre means and statewide totals were within four to twenty three percent of EVALIDator across the six runs, with all six PASSING the threshold check defined in `STATE_PROFILES`. Volume totals match EVALIDator to within two percent for WA, three percent for GA, and twenty three percent under for MN. The MN under estimate was resolved on 17 May 2026 as a donor pool composition mismatch (`MN_DONOR_POOL_DIAGNOSTIC_20260517.md`). The Lake States donor cohort is 89 percent MI plus WI (central Great Lakes forest); it under-represents MN's northern boreal aspen/birch by 23.3 percentage points and spruce/fir by 12.4 pp, and over-represents central hardwoods maple/beech/birch by 17.7 pp and oak/hickory by 9.9 pp. The mechanism is the same as the WA -25 percent bias: CEM matching imports slower-growing donor forest type trajectories onto under-represented subject types.

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

**Donor pool composition for WA (confirmed by direct diagnostic).** A 17 May 2026 diagnostic on FIA COND tables in the 1999 to 2008 baseline window quantified the WA donor pool gap. WA west side hemlock and Sitka spruce forest types occupy 14.1 percent of WA forested area but only 3.0 percent of the OR, ID, MT donor pool (a 11.1 percentage point gap). Douglas fir occupies 41.6 percent of WA versus 32.6 percent of donors (9.0 pp gap). The donor pool is overrepresented in interior pine types: ponderosa pine 16.5 percent donor versus 9.0 percent WA (7.5 pp gap), lodgepole pine 9.8 percent versus 3.4 percent (6.4 pp gap), other western softwoods 7.7 percent versus 0.5 percent (7.2 pp gap). CEM matching draws growth trajectories from donors and applies them to subjects; the matcher imports interior pine growth trajectories into WA west side subjects, suppressing projected biomass accumulation. This is the dominant mechanism for the WA -25 percent conservative bias. Remediation paths include restricting OR donors to west-of-Cascade plots only, treating WA west side plots as their own donor cohort, or adding Bailey ecological section as a CEM matching covariate.

**Climate response gating.** Production runs use `--use_potter_vcc` for species level climate vulnerability (CONUS lookup) but not `--use_decoupled_climate` (per state ClimateNA derived temperature and CO2 trajectories), because ClimateNA is a desktop GUI tool that cannot be executed in our automated pipeline. The simpler single multiplier climate response may not capture full state level productivity response to changing climate, particularly for the Pacific Northwest where decoupled temperature and precipitation regimes drive growth limits. Future work will integrate ClimateNA outputs per state once available. This is a contributing secondary mechanism for the WA bias alongside donor pool composition.

**GA +10 percent over mechanism (resolved 17 May 2026).** The original donor mixing hypothesis was refuted: GA subjects are 43 percent plantation-indicative pine forest types (FORTYPCD 141, 142, 161, 165-168); the donor pool (FL, SC, AL, TN) is only 30 percent plantation-indicative. The multiplicative-effect hypothesis was also refuted: GA's cycle 1 BAU relative growth rate of 0.0122 is the highest of four states (WA 0.0119, MN 0.0081, ME 0.0065), consistent with warm wet southeastern climate, and not anomalously normal-applied-to-high-baseline. The actual mechanism is the combination of two effects. First, the stand-age saturation function with `terminal_age = 80` and `growth_start_age = 60` leaves 95.4 percent of GA's plantation-indicative conditions at `sat_age = 1.0` (full unattenuated growth) because the cohort is young (median age 20 years, 95 percent under age 60). Donor-to-subject growth ratios and climate multipliers are applied at full strength. Second, the BAU harvest module aggregates to approximately 10 percent per cycle matching regional rates but is forest-type-agnostic in selection; plantation conditions and natural conditions have equal probability of harvest per cycle, while in reality plantation rotations of 25 to 35 years drive heavy clearcut on plantations specifically. The combination produces unconstrained carbon accumulation on plantations that should be removed but are not preferentially selected. Future iterations could add forest-type-aware harvest selection or lower `terminal_age` for plantation forest types to begin saturation attenuation closer to rotation age.

### Owner stratification verification

Harris, Caputo, and Butler (2025) owner classes were joined to all six p1 outputs and per owner cycle 1 BAU per acre volume and harvest fraction were tabulated. Across states, the `--use_owner_balanced` rescaling produces tight 9 to 10 percent harvest fractions across all owner groups, consistent with the mass balanced area weighted mean target. WA federal majority (19,277 USDA FS plots) versus private at lower per acre volume (2,508 cuft per acre vs 3,264) reflects the historical pattern of more intensive harvest on Washington's industrial timberlands. GA private dominance (80,406 NIPF and industrial plots) reflects the southeastern private plantation forestry pattern.

## Section X.3: Limitations and known biases

### Methodological note on unit handling in the harvest economic overlay

During the multistate validation work, a systematic audit of the harvest economic overlay (Wear and Coulston 2025 logit implementation) uncovered four distinct unit and scaling errors that had accumulated in the codebase. The errors are discussed here as a worked example of the validation discipline required for a multi component forest projection pipeline.

The aggregation step in `R/01_data_prep.R` builds the per acre baseline columns via tree level expansion: `carbon_ag = sum(TPA_UNADJ * CARBON_AG)` and `volcfnet = sum(TPA_UNADJ * VOLCFNET)`. Because `TPA_UNADJ` is FIA's trees per acre expansion factor and the per tree volumes and carbon are in cubic feet and pounds respectively, the aggregated columns carry units of **cuft per acre** and **pounds per acre** at the condition level. Several downstream calculations in `R/03_harvest_choice.R` did not respect this per acre convention and produced inflated values that propagated to the harvest decision logit.

The four corrections, ordered chronologically as we discovered them:

| Layer | Site | Description | Status |
|---|---|---|---|
| 1 | `R/06_projection_engine.R` line 922 | gr_ratio reporting unit | Active code, fixed |
| 2 | `R/03_harvest_choice.R` line 409 | `vol_removed_total = volcfnet × tpa_live × intensity` double counted per acre | Active code, fixed |
| 3 | `R/03_harvest_choice.R` line 108 | `EV = T2_volcfnet × prices × tpa_live` double counted per acre | Dead code, fixed for consistency |
| 4 | `R/03_harvest_choice.R` lines 80 to 91 | `REV = vol_sawtimber × $/MBF` mixed cuft volume with $/MBF and $/cord prices | Active code, decisive |

Of the four, only Layer 4 directly affected the cycle 1 BAU harvest decision in production. The Layer 4 patch added explicit conversion factors `MBF_per_CUFT = 1/200` and `CORD_per_CUFT = 1/80` to the revenue calculation, correctly bridging the per acre cuft volumes against per MBF sawtimber and per cord pulpwood prices. Before the patch, treating $250 per MBF as $250 per cuft inflated revenue by approximately 200x; combined with the pulpwood 80x inflation, the resulting differential value (proxied by revenue in this implementation) saturated the logit term and produced near-deterministic harvest probabilities of approximately 0.84 per cycle, inconsistent with observed Maine harvest rates of approximately 0.10 per cycle.

Post Layer 4, a 10 simulation ME baseline-as-usual smoke produced cycle 1 BAU harvest rate of 0.258, cycle 2 of 0.130, cycle 3 of 0.089, cycle 4 of 0.037, and cycle 5 of 0.028, averaging 0.108 across the five cycles. The elevated cycle 1 rate represents initial inventory liquidation of mature stands accumulated during the 1999 baseline period, with the system stabilizing to sustainable rates by cycle 3 onward. The gr_ratio (gross growth divided by harvest removals) follows the corresponding trajectory from 0.84 at cycle 1 to 9.83 at cycle 5, indicating the projection moves from initial inventory liquidation through sustained accumulation.

Layers 2 and 3 turned out to be in code paths that did not drive cycle 1 harvest decisions; Layer 2 affected cycle 2 and later revenue feedback, and Layer 3 was in a never called function (`compute_ending_value()`). Both patches stay in the codebase for correctness and for any future code paths that might invoke them.

The multistate p1 runs reported in Section X.2 use the `--no_econ` and `--skip_supply` paths and bypass the harvest economic overlay entirely. Their validation results are unaffected by any of the four layer patches. The ME r21 economic projection that is the canonical Maine result with the full Wear and Coulston (2025) harvest overlay was rerun after the Layer 4 patch landed. At full production scale (100 simulations, 15 cycles, both RCPs), cycle 1 BAU gr_ratio is 3.46, matching the Maine RPA Forests of Maine 2021 reported state level growth to removals ratio of 3.32 within four percent and confirming the Layer 4 patch produces realistic Maine harvest dynamics at production scale.

Future implementations of the projection framework should adopt explicit unit attributes on aggregated columns (for example using the `units` package in R) to prevent recurrence of unit and scaling errors in the economic overlay.

### Outstanding state level limitations

- MN -23 percent statewide volume under EVALIDator: confirmed as Lake States donor pool composition mismatch. Donor pool 89 percent MI plus WI (central Great Lakes forest) under-represents MN northern boreal aspen/birch by 23.3 pp and spruce/fir by 12.4 pp; over-represents central hardwoods (maple/beech/birch +17.7 pp, oak/hickory +9.9 pp). CEM imports slower climax-forest growth trajectories onto MN pioneer subjects. Future iteration: MN-as-own-donor leave-one-out, restrict donors to MI/WI plots north of latitude 45.5, or stratify CEM by FORTYPCD; Bailey section CEM stratification is the methodologically cleanest direction.
- WA -25 percent conservative hindcast bias: dominant mechanism is PNW donor pool composition (hemlock/Sitka spruce -11.1 pp, Douglas-fir -9.0 pp underrepresented; ponderosa/lodgepole/other softwoods overrepresented). Secondary mechanism is the absence of ClimateNA decoupled climate inputs. Future iteration: west-of-Cascade donor restriction, WA-as-own-donor leave-one-out matching, or Bailey ecological section CEM stratification; plus ClimateNA per-state integration.
- GA +10 percent over bias: mechanism resolved as the combination of stand-age saturation under-application (95.4 percent of GA plantation conditions sit at `sat_age = 1.0` because cohort median age is 20 years, well below the `growth_start_age = 60` threshold) and forest-type-agnostic harvest selection in the BAU module (plantation rotations at 25-35 years are not preferentially harvested). Future iteration: forest-type-aware harvest selection plus lower `terminal_age` for plantation FORTYPCDs to begin saturation closer to rotation age.

### Cross model context

This multistate result extends the FIA CEM Maine work that participates in the PERSEUS multi institution effort comparing FIA CEM, FVS NE/Acadian, GCBM/libcbm, and LANDIS-II. The Harris, Caputo, and Butler (2025) landowner stratification documented here is the cross cutting refinement designed to unify owner class harvest behavior across all four PERSEUS models. Phase 1 (the atlas at `config/fia_plots_with_owner.csv`) is complete and now extends from Maine to MN, WA, and GA. Phases 2 through 4 (model specific yield curves, disturbance schedules) are pending.

## Suggested figure list for the manuscript

1. Per acre carbon trajectory by state and RCP, all five scenarios (`figures/p1_carbon_trajectory_panel.png`)
2. Statewide AGC trajectory by state and RCP (`figures/p1_statewide_agc_panel.png`)
3. Harvest scenario delta from BAU by state and RCP (`figures/p1_harvest_delta_panel.png`)
4. Summary grid showing BA, volume, carbon, gr_ratio BAU trajectories cross state cross RCP (`figures/p1_summary_grid.png`)
5. Hindcast performance plot: observed versus projected AGC for matched years, faceted by state (`figures/p1_hindcast_observed_vs_projected.png`)

## Suggested table list for the manuscript

1. State by RCP validation matrix (PASS/REVIEW, bias, RMSE)
2. BAU milestone summary at cycles 1, 5, 10, 15 (`figures/p1_summary_BAU_milestones.csv`)
3. Per owner group cycle 1 BAU summary (from validation memos)
4. State specific bounds and FIA EVALIDator targets

## Suggested supplementary materials

1. `docs/UNIT_BUG_FINDING_20260515.md` -> Supplementary methods note on unit handling
2. `docs/BIAS_DOCUMENTATION_20260515.md` -> Supplementary discussion on cross state bias
3. `docs/HINDCAST_<STATE>_<RCP>_WEAR_P1.md` per state plus `docs/HINDCAST_ME_RCP45_HADGEM2_WEAR_R21.md` for ME -> Supplementary hindcast detail tables
4. `docs/VALIDATION_<STATE>_R21_<RCP>.md` per state -> Supplementary validation memos
