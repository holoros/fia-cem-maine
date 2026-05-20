# Introduction section draft

*Drafted 20 May 2026 for the multistate CEM paper.*
*Roughly 1200 words, positioned as section 1 of the methods paper.*

## 1.1 The state-level forest carbon projection problem

State-level projections of forest carbon stocks and harvest removals serve a wide community of practice. Federal natural resource agencies use them to inform RPA Assessments and ESA biennial reports. Carbon market registries require state-level baselines for projection-based offsetting protocols. Forest products economists need them for harvest supply analyses. State forestry agencies use them for inventory-anchored management planning. Multi-model comparison efforts such as PERSEUS require projections at sub-national resolution to differentiate model behavior from regional ecological differences. In each setting, the underlying question is the same: given a state's current forested inventory and plausible climate and management trajectories, what is the projected trajectory of carbon stocks and harvest removals over the next several decades?

The Forest Inventory and Analysis (FIA) program of the USDA Forest Service provides the data foundation for these projections, with a long-running national panel pair design that re-measures plots on five- to ten-year cycles depending on state, capturing both the standing inventory and the growth, mortality, and removals that have occurred between measurements (Bechtold and Patterson 2005, USDA Forest Service 2024). The challenge is to translate these panel pair observations into projections that capture the joint dynamics of growth and disturbance under plausible future conditions.

## 1.2 Coarsened exact matching as a projection framework

Coarsened exact matching (CEM) was introduced by Van Deusen and Roesch (2013) as a non-parametric framework for FIA-based forest projection. The approach pairs subject plots (those awaiting projection) with re-measured donor plots that share the same set of coarsened covariates (forest type, owner group, age class, basal area, site class, condition proportion), then transfers the donor's observed growth or change to the subject. CEM is attractive because it requires no parametric growth model — the projection comes directly from observed FIA panel pair dynamics — and it gracefully handles the heterogeneity of forest types and management regimes that any growth-and-yield model must accommodate.

The Maine CEM framework (Weiskittel et al. in prep) extends the original Van Deusen and Roesch (2013) approach with several refinements: a BRMS Reineke SDImax cap (Woodall and Weiskittel 2021), Norby et al. (2010) CO2 fertilization coupling, episodic disturbance (Costanza et al. 2024), Potter et al. (2017) species climate vulnerability, Harris, Caputo, and Butler (2025) landowner stratification, and a Wear and Coulston (2025) harvest economic overlay calibrated to Maine RPA published rates. The Maine implementation has demonstrated -1.1 percent subject matched hindcast bias against FIA EXPALL EVALIDs over the 2004 to 2024 record, providing a canonical reference for the framework's behavior in well-calibrated single-state mode.

## 1.3 The transferability question

Extending the Maine framework to other states is methodologically straightforward in principle: replace the per-state climate trajectory, swap state_constants.csv parameters (terminal age, SDImax default, wildfire baseline, disturbance regime), substitute the appropriate Wear and Coulston (2025) regional harvest logit coefficients, and define an appropriate donor cohort from neighboring states. In practice, however, the question of whether the Maine-validated framework retains its skill across heterogeneous ecoregions has not been quantitatively documented.

The donor cohort definition is particularly underspecified. The Van Deusen and Roesch (2013) original implementation used a single state's panel pairs for both subjects and donors via leave-one-out matching. The Maine production framework follows similar within-state matching practice. Extending to other states forces a choice: should the donor cohort be the subject state alone (with leave-one-out), or should it expand to include neighboring states to improve cell coverage? Most CEM forest projection implementations have chosen the neighboring-state approach (Brooks and Wear 2024), but the consequences for projection skill have not been quantified.

## 1.4 Cross-state extension goals

This paper extends the Maine CEM framework to three additional states (Minnesota, Washington, Georgia) representing the northern boreal, Pacific Northwest, and southeastern coastal plain biomes respectively. Each state's donor cohort is defined per conventional CEM practice (state_constants.csv): MN's donors are WI, MI, IA, IL, ND, SD; WA's donors are OR, ID, MT; GA's donors are FL, SC, NC, AL, TN. Production runs use the same Maine-validated framework refinements (BRMS SDImax, CO2 fertilization, episodic disturbance, Potter species vulnerability, HCB ownership) with per-state climate and parameter adjustments documented in state_constants.csv.

We pose three questions:

1. **Does the Maine-validated CEM framework transfer to other states?** Specifically, what is the subject matched hindcast bias against FIA EXPALL EVALIDs for each state x RCP combination?

2. **If bias differs across states, what mechanism drives the difference?** Specifically, is bias attributable to donor pool composition, climate response, state-specific parameter values, owner stratification, or some combination?

3. **Can the mechanism be addressed with a portable refinement of the CEM matching procedure?** Specifically, would adding ecoregion or forest type stratification to the existing matching keys reduce bias in a way that generalizes across states?

## 1.5 Outline

Section 2 describes the data sources (FIA panel pairs, the Harris/Caputo/Butler 2025 landowner raster, EPA L3 ecoregion crosswalks) and the per-state production runs (100 simulations, 15 five-year cycles, RCP 4.5 and 8.5 climate scenarios). Section 3 reports the cross-state subject matched hindcast results, then the donor pool composition diagnostic, then the Georgia stand-age saturation diagnostic, then the resulting bias mechanism synthesis across all four states. Section 4 develops the three-iteration ecoregion-stratified CEM remediation, presents empirical cell-size feasibility, and reports the bias reduction from a Layer 7b production rerun applying the patched matching framework. Section 5 discusses the implications for cross-CEM-framework comparison (PERSEUS) and the broader question of donor pool selection in CEM forest projection. Section 6 covers limitations and future work.

## 1.6 Contributions

The contributions are:

1. The first quantitative documentation of CEM forest projection transferability across four CONUS biomes, with bias bounded by -25 to +11 percent of subject matched observed AGC.

2. Identification of donor pool composition mismatch as the universal cross-state bias mechanism, with the dominant subject forest types systematically underrepresented in each state's conventional donor cohort.

3. Identification of an auxiliary stand-age saturation mechanism specific to states with young plantation cohorts (e.g., Georgia loblolly).

4. A three-iteration ecoregion-stratified CEM matching strategy that addresses the donor pool composition mechanism, with empirically validated cell-size feasibility and bias reduction [to be filled in from production results].

5. An L3-to-section ecoregion crosswalk and associated configuration files released as a manuscript supplement, enabling other CEM forest projection frameworks to adopt the same matching strategy.

The L3-to-section crosswalk, the configuration files, the patched matching scripts, and the diagnostic R scripts are all available at the public manuscript repository [URL placeholder].
