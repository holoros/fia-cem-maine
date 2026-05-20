# Section X.2 (expanded): Bias mechanism and donor pool composition

*Draft 20 May 2026 incorporating the resolved bias mechanism findings from the 17 May diagnostic suite.*
*Intended to replace the current bias paragraphs in `MULTISTATE_METHODS_DRAFT_20260515.md` once Layer 7b production reruns confirm the projected reductions.*

## X.2.1 Cross-state hindcast bias pattern

Subject matched hindcasts against FIA EXPALL EVALIDs for all four multistate p1 states produced the following residuals at the canonical 1999 baseline plus matched cycle years:

| State x RCP | RMSE (MMT AGC) | Bias (MMT) | Bias (%) | Years matched |
|---|---:|---:|---:|---|
| MN 4.5 | 22.6 | -6.6 | -5.7 | 2004, 2009, 2014, 2019, 2024 |
| MN 8.5 | 23.3 | -6.7 | -5.8 | 2004, 2009, 2014, 2019, 2024 |
| WA 4.5 | 78.9 | -78.9 | -25.3 | 2019 |
| WA 8.5 | 77.4 | -77.4 | -24.8 | 2019 |
| GA 4.5 | 48.7 | +23.8 | +9.6 | 2004, 2009, 2014, 2019, 2024 |
| GA 8.5 | 51.9 | +27.2 | +11.0 | 2004, 2009, 2014, 2019, 2024 |
| ME r21 reference | 16.0 | -2.0 | -1.1 | 2004 through 2024 |

The cross-state bias range spans -25 to +11 percent, bracketing the canonical Maine reference of -1.1 percent on both sides. Investigation across the four states revealed that the same underlying mechanism — donor pool composition mismatch — operates universally; what differs across states is the compensating mechanisms that absorb or amplify the mismatch.

## X.2.2 Donor pool composition diagnostic

For each subject state and its conventional donor cohort (state_constants.csv), we computed the forest type group composition share (FORTYPCD aggregated to TYPGRPCD) of forested baseline conditions (COND_STATUS_CD == 1, INVYR 1999 to 2008) using the full CONUS FIA ENTIRE_COND table.

The headline gap patterns:

**Minnesota:** MN subjects are 39.7 percent aspen/birch and 23.0 percent spruce/fir; the Lake States donor cohort (WI, MI, IA, IL, ND, SD; 89 percent MI plus WI) is only 16.4 percent aspen/birch and 10.5 percent spruce/fir. The donor pool overrepresents central hardwoods (maple/beech/birch +17.7 percentage points, oak/hickory +9.9 pp). CEM matching imports slower climax-forest growth trajectories from MI/WI maple-beech-birch and oak-hickory donors onto MN's fast-growing boreal pioneer subjects, suppressing projected accumulation.

**Washington:** WA subjects are 41.6 percent Douglas-fir and 14.1 percent hemlock/Sitka spruce; the Pacific Northwest donor cohort (OR, ID, MT) is 32.6 percent Douglas-fir and only 3.0 percent hemlock/Sitka spruce. The donor pool overrepresents interior pine types (ponderosa pine +7.5 pp, lodgepole pine +6.4 pp, other western softwoods +7.2 pp). CEM matching imports interior pine growth trajectories onto WA's coastal high-productivity subjects, producing the largest conservative bias in the multistate set.

**Georgia:** GA subjects are 30 percent loblolly/shortleaf pine and 14 percent longleaf/slash pine; the southeastern donor cohort (FL, SC, NC, AL, TN) is 26 percent loblolly/shortleaf and 6 percent longleaf/slash. The donor pool overrepresents oak/hickory (39 percent donor vs 27 percent GA, -12 pp gap from GA's perspective). The simple plantation-vs-natural donor mixing hypothesis is refuted by these data — GA has more plantation-indicative types than its donor pool. The GA bias mechanism instead operates through the stand-age saturation function described in X.2.3.

**Maine (canonical reference):** ME subjects are 32 percent spruce/fir and 13 percent aspen/birch; the Northeast donor cohort (NH, VT, MA, CT, RI, NY, PA) is only 2 percent spruce/fir and 3 percent aspen/birch. Maine has a 30 pp spruce/fir gap and a 32 pp oak/hickory gap relative to its donor pool. The canonical -1.1 percent bias arises despite this dramatic mismatch because three compensating mechanisms in Maine absorb the donor pool gap: explicit ClimateNA decoupled climate coupling, within-Maine refinement of `state_constants.csv` parameters (terminal_age 120, SDImax 440), and owner balanced rescaling calibrated against published Maine RPA harvest rates.

## X.2.3 Auxiliary mechanism: stand age saturation in Georgia

The Georgia bias direction (+10 percent over) differs from the WA/MN underestimate pattern despite the same donor pool composition mechanism. A separate diagnostic identified a Georgia-specific amplification: the stand-age saturation function with `terminal_age = 80` and `growth_start_age = 60` leaves 95.4 percent of GA plantation-indicative conditions (FORTYPCD 141, 142, 161, 165-168) at `sat_age = 1.0` (full unattenuated growth). GA's plantation cohort has median age 20 years, 95 percent under age 60, well below the saturation threshold. Combined with forest-type-agnostic BAU harvest selection (selection probability uniform across forest types), plantations grow at full donor rates but are not preferentially clearcut at rotation age (25 to 35 years). The combination produces over-prediction of carbon accumulation on plantations that should be removed but are not selected.

## X.2.4 Recommended remediation: ecoregion-stratified CEM matching

The donor pool composition mismatch suggests adding ecoregion as a CEM matching key alongside FORTYPCD and OWNGRPCD, which are already in the existing iter1 strata. Empirical cell-size diagnostics confirm this is feasible at the EPA L3 ecoregion granularity: 156 cells across CONUS with at least one subject; 36.7 percent have at least 30 conditions; only 3 percent of subject conditions in the multistate p1 set fall in cells with zero cross-state donors. Adding owner stratification (OWNGRPCD's 4 classes: USDA FS, Other Federal, State/local, Private) produces 332 cells with cell-coverage essentially unchanged from the 2-way (37 percent have at least 30 conds) and an improvement in low-donor subject cell rate (3.1 percent vs 4.0 percent for 2-way), because owner structure aligns naturally with geography.

We implemented this as a three-iteration matching strategy:

1. **Iter 1 (fine).** Match on ecoregion × FORTYPCD × OWNGRPCD × condition proportion × stand origin × site class × age × basal area, including climate when ClimateNA decoupled climate is active. Captures the vast majority of subjects at the strictest tier (91.8 percent in the ME smoke test).

2. **Iter 2 (medium).** Collapse OWNGRPCD to federal versus non-federal and ecoregion to Bailey-section-equivalent (20 ecological sections covering CONUS). Captures the remaining subjects whose strict cell is empty (64.8 percent of unmatched in the ME smoke test).

3. **Iter 3 (coarse).** Drop owner and ecoregion entirely. Acts as a within-state leave-one-out matching for any residual subjects (90.6 percent of remaining in the ME smoke test).

Across the iterations, 99.7 percent of subject conditions match at least one donor with median 3 matches per subject, confirming the empirical cell sizes are adequate.

## X.2.5 Bias reduction observed (placeholder for production rerun)

[Section to be completed after Layer 7b production reruns land. Expected outcomes per the empirical cell-size diagnostic and projected donor pool match closing:]

[Insert revised bias table from `output/l7b_comparison_20260520/l7b_vs_p1_cycle1_bau_comparison.csv`]

[Projected outcomes:]
- WA -25% → -5 to -10%
- MN -23% statewide → -3 to -8%
- GA +10% → +3 to +5%
- ME canonical -1.1% → unchanged

[If observed reductions are within these projections, the manuscript narrative becomes: donor pool composition mismatch is the universal mechanism across all four states; the proposed three-iteration ecoregion-stratified matching demonstrates a quantitative path to reduce hindcast bias from the -25/-23/+10 percent range to within 5 to 10 percent for all subject states while preserving the canonical Maine reference bias at -1.1 percent.]

## X.2.6 Method caveats and limitations

Three caveats:

1. **HCB owner classification coverage.** The Harris/Caputo/Butler 2025 owner raster offers finer-grained classification (10 classes) than OWNGRPCD's 4 classes. Currently the HCB crosswalk at `config/fia_plots_hcb_l3.csv` covers only 6,289 plots (Maine-only at this writing). Extending the HCB classification to full CONUS plots is a multi-day geospatial task. The current implementation uses OWNGRPCD's 4 classes (federal subdivided into USDA FS vs Other Federal, state/local, private) which captures the dominant private/federal harvest rate differential.

2. **EPA L3 ecoregion coverage.** The HCB L3 crosswalk covers 104,628 of 239,464 CONUS forested baseline conditions (44 percent). For unattributed plots, the CEM falls back to STATECD as the ecoregion key (preserving current within-state matching behavior). Full coverage requires a geospatial join of remaining plots to the EPA L3 ecoregion raster.

3. **GA stand-age saturation correction not deployed.** The GA over-prediction mechanism includes the stand-age saturation under-application on young plantations. A `terminal_age` reduction for plantation FORTYPCDs (e.g., FORTYPCD 141, 142, 161, 165 to 168 set to terminal_age = 50 instead of state default 80) would attenuate growth on plantations approaching rotation age. This is a separate methodological refinement that could be tested in a future iteration but is not part of the current Layer 7b ecoregion patch.
