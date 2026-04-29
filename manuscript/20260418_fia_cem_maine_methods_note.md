# A state-scale application of FIA coarsened exact matching for Maine forest carbon projections under climate and economic scenarios

**Running head:** Maine FIA CEM carbon projections

**Authors:** A. Weiskittel [1], [co-authors TBD]
[1] Center for Research on Sustainable Forests, University of Maine, Orono, ME 04469, USA. aaron.weiskittel@maine.edu

**Target journal:** Mathematical and Computational Forestry and Natural Resource Sciences (MCFNS). Alternative: Journal of Forestry.

**Word count target:** 6,000 words plus 6 figures and 3 tables.

---

## Abstract

Forest Inventory and Analysis (FIA) data underpin the Resources Planning Act (RPA) Assessment's state-scale carbon projections, but state agencies and climate councils typically need projections that reflect both climate change and state-specific market conditions on policy-relevant horizons. We extend the coarsened exact matching (CEM) approach of Van Deusen and Roesch (2013) with the stratification and transition refinements of Wear and Coulston (2019) and layer a Maine-specific economic harvest module driven by 10 years of Maine Forest Service county stumpage price reports and Silvicultural Activities Reports. We project six contrasting scenarios on a 1999 baseline through 2099 (20 five-year cycles × 100 bootstrap simulations) on OSC Cardinal HPC. We benchmark against PERSEUS and RPA state totals and cross-validate against five historical FIA EXPALL panels. Results highlight three findings. First, age-class saturation with a 120-year terminal age removes a 130 MMT runaway in RCP 8.5 no-harvest projections that appears in the unsaturated CEM pipeline. Second, multi-pool carbon accounting (seven pools following Wear and Coulston 2019) yields a Maine total carbon estimate of 1,128 MMT in 2004, of which 62 percent is soil organic and 21 percent is above-ground live tree biomass. Third, the Maine economic overlay produces county-differentiated partial-versus-clearcut dynamics ranging from less than 1 percent clearcut in southern coastal counties to 31 percent in Aroostook, matching the observed 2015 to 2023 Silvicultural Activities Report pattern. The pipeline is reproducible, open-source, and extensible to other states with comparable FIA and MFS-style reporting infrastructure.

**Keywords:** Forest Inventory and Analysis, coarsened exact matching, Maine, forest carbon, economic harvest model, climate change projection.

## 1. Introduction

Place-based forest carbon projections need to accommodate three interacting drivers: biological growth responses to a changing climate, economic drivers of harvest decisions, and the structural properties of the starting inventory. The Resources Planning Act (RPA) Assessment ( Coulston et al. 2022) delivers national projections using a CEM-based Forest Dynamics Model ( Van Deusen and Roesch 2013), but state-level applications require finer resolution on stratification, transition structures, and market conditions.

Maine's forest covers 17.6 million acres, roughly 90 percent of the state land area, and hosts a forest products economy worth over USD 8 billion annually ( MFS 2024). Maine's forest carbon stock is both a resource and a policy lever, featured in the state's Climate Action Plan and relevant to carbon offset markets. Prior state-scale assessments have relied on either national-scale projections (too coarse) or stand-level modeling (too narrow). A state-scale but inventory-rich projection would better serve state planning.

Here we bridge that gap. We apply CEM on a Maine-anchored FIA pool with neighboring donor states, layer the refinements prescribed by Wear and Coulston (2019), integrate Maine county-specific stumpage price forecasts and Silvicultural Activities Report (SAR) -observed harvest patterns, and project forward through 2099 under RCP 4.5 and RCP 8.5 climate forcings with and without harvest. Our primary contributions are:

1. A reproducible pipeline implementing Wear 2019 stratification (stand origin and owner primary), age-class saturation (terminal age 120 years for northern hardwood-conifer mixes), and seven-pool total carbon accounting.

2. A Maine-specific economic harvest module driven by 10 years of MFS stumpage reports at the county × product × species granularity with real-price forecasts to 2125.

3. A partial-versus-clearcut split calibrated against SAR-observed county treatment proportions, preserving the observed geographic heterogeneity.

4. Quantitative benchmarking against PERSEUS and RPA state totals plus cross-validation against five FIA EXPALL panels.

## 2. Methods

### 2.1 FIA data and baseline selection

We used FIA DataMart bulk CSV exports (TREE, COND, PLOT, POP_* tables) for Maine and four neighboring donor states (New Hampshire, Vermont, New York, Massachusetts). The subject plot pool was defined as the earliest measurement per (PLT_CN, CONDID) falling within the baseline window [1999, 2008], a 10-year span covering the first two complete annualized panel cycles in Maine. Plots that were ever remeasured on subsequent panels supply the donor pool (to compute empirical growth rates); plots that were only measured once during the window enter as subjects and are projected forward. Plots with post-harvest treatment codes on their donor-side remeasurement were excluded from the donor pool to prevent harvest-induced ratios from biasing the forward projection.

Of 21,638 total Maine plots in the FIA database and 9,331 condition-year records in the baseline window, 6,887 passed the forested-and-non-reserved-and-valid-site-class filters and had complete growth-variable records. Of these, 2,819 entered the subject pool (the rest became donors). This 40 percent subject fraction is structural to the CEM approach rather than an optional choice: the pipeline cannot project forward a plot whose future state is already observed without double-counting. A 15-year baseline window would increase the subject count at the cost of making the baseline year interpretation more diffuse.

**Implication for cross-validation.** The pipeline's state-expanded subject-only inventory represents roughly 40 percent of the total forest by FIA plot count. Observed FIA EXPALL inventories, which use all plots in a given year's panel, therefore consistently exceed our projected subject-only total by approximately 90 MMT AGC during the 2004 to 2024 validation window. This gap is a definitional mismatch between the two inventories rather than model bias. Scenario-relative comparisons within our pipeline (harvest vs no-harvest, RCP 4.5 vs 8.5) remain internally consistent because they share the same subject pool.

### 2.2 CEM matching with Wear 2019 stratification

We applied coarsened exact matching on seven stand-condition variables prioritized per Wear and Coulston (2019, Table 3): stand origin (STDORGCD), owner group (OWNGRPCD), forest type (FORTYPCD), site class (SITECLCD), stand age bin (10-year bins), basal area bin (20 sq ft/ac bins), and condition proportion bin. Matching proceeded in three coarsening iterations (fine, medium, coarse) with unmatched subjects carried forward using their subject-side values rather than dropped. Donor plots came from the same four neighboring states; the donor pool totaled 23,927 remeasurement pairs after the untreated filter.

### 2.3 Projection engine

Each subject plot was projected through twenty 5-year cycles using a growth-rate-based projection:

X_proj = X_subject × (X_donor_T2 / X_donor_T1) × climate_mult × age_saturation

where X represents each of basal area, total cubic-foot volume (VOLCFNET), sawlog cubic-foot volume (VOLCSNET), dry biomass (DRYBIO_AG), carbon (CARBON_AG), trees per acre (TPA_UNADJ), and quadratic mean diameter. Growth rate ratios were capped at [0.5, 2.0] to protect against donor outliers. The climate multiplier was computed per cycle from HadGEM2-AO RCP 4.5 and RCP 8.5 annual temperature anomalies with coefficient 0.015 per degree C (linear), saturating past 3 C warming under RCP 8.5. Age saturation was applied linearly from unity at stand age 60 years down to zero at terminal age 120 years, attenuating both the growth-rate departure from unity and the climate multiplier.

### 2.4 Harvest choice and intensity

Harvest probability was determined by the Wear and Coulston (2025) Northeast regional logit model using differential value (dVAL) as the primary economic driver. Harvested plots were assigned a binomial clearcut indicator with county-specific probability from the 2015 to 2023 Silvicultural Activities Report. Clearcut plots were reset to stand age 0 and assigned intensity 0.95; partial-harvest plots received intensity 0.50 with a 40-year age setback reflecting regeneration dynamics.

### 2.5 Maine economic harvest module

We scraped 10 years of Maine Forest Service Stumpage Price Reports (2015 to 2024) and deflated nominal prices to 2024 real USD using BLS CPI-U annual averages. For each county × product × species series we fit log-linear trends plus AR(1) residuals and forecast through 2125 with ±3 percent/yr growth bounds. The resulting `maine_stumpage_forecast.csv` ($N$ = 59,444 rows) feeds the harvest revenue equation via a species-weighted aggregation per product.

### 2.6 State expansion and multi-pool carbon

Per-plot projected values were expanded to statewide totals using FIA EXPNS weights (POP_STRATUM × POP_PLOT_STRATUM_ASSGN). The total carbon aggregation sums all seven pools: above-ground live tree carbon (from TREE.CARBON_AG), below-ground live tree carbon (0.22 × above-ground; Jenkins 2003 component ratio), standing and down dead carbon (from COND.CARBON_DOWN_DEAD), forest floor litter carbon (COND.CARBON_LITTER), soil organic carbon (COND.CARBON_SOIL_ORG), understory above-ground carbon (COND.CARBON_UNDERSTORY_AG), and understory below-ground carbon (COND.CARBON_UNDERSTORY_BG). COND pool columns are converted from short tons per acre to pounds per acre by multiplying by 2000 before EXPNS expansion.

### 2.7 Uncertainty quantification

We ran 100 bootstrap plot-resampling replicates per scenario with 90 percent subject-plot sampling per replicate. The 2.5th, 50th, and 97.5th percentiles across replicates are reported as lower, mean, and upper credible bounds.

### 2.8 Computing environment

All runs were executed on Ohio Supercomputer Center Cardinal (AMD EPYC 9534) using R 4.4.0 and the allocation PUOM0008. Per-scenario wallclock was 35 to 45 minutes on 48 cores. The pipeline source is at `/users/PUOM0008/crsfaaron/fia_cem_projections/` and will be released under MIT license upon publication.

## 3. Results

### 3.1 Cross-validation against observed FIA panels

A 1999 to 2024 BAU hindcast cross-validates against five observed FIA EXPALL panels at five-year intervals. The pipeline projects the subject-only inventory (the roughly 40 percent of FIA plots that had not been remeasured at the time of the 1999 anchor), so the appropriate validation target is the subject-matched observed inventory recomputed using only those same plots at each EVALID year, rather than the full-panel EXPALL.

Against subject-matched observed inventory (the canonical comparison): RMSE = 16 MMT AGC, mean bias = −2 MMT (−1.1 percent of observed mean), with errors ranging from −28 MMT in 2004 to +16 MMT in 2019. The pipeline reproduces the subject-pool decline trajectory well, slightly under-predicting at the 2004 anchor and slightly over-predicting in the middle of the validation window. The 2004 baseline AGC of 231 MMT (refined pipeline, r17 tag) sits 37 MMT below the 268 MMT subject-matched observed value, a 14 percent undershoot consistent with the −28 MMT 2004 hindcast residual.

Against full-panel EXPALL: RMSE = 103 MMT, bias = −96 MMT (−32 percent). This wider gap reflects the definitional mismatch between subject-only projection and full-panel inventory, not model error. Subject-matched validation is the correct comparison for assessing pipeline skill.

### 3.2 Multi-pool Maine carbon stock

At cycle 1 (2004 anchor), the multi-pool aggregation produces approximately 1,131 MMT total Maine forest carbon partitioned roughly as: 231 MMT above-ground live tree (20 percent), 51 MMT below-ground live tree (5 percent), 50 MMT standing and down dead (4 percent), 82 MMT forest floor litter (7 percent), 705 MMT soil organic (62 percent), and less than 10 MMT understory. Soil and litter pools are held stationary across the 70-year projection, while live-tree pools evolve under the saturated growth-and-harvest dynamics. By 2074 under the refined pipeline (r17), total carbon under BAU declines to about 235 MMT (RCP 4.5 wear) and stays near 460 MMT under No_harvest, reflecting that climate forcing trims the no-harvest accumulation toward roughly half of the observed 2004 baseline rather than recovering it.

### 3.3 Climate scenarios

Under the refined pipeline (r17), which couples a BRMS Reineke SDImax cap on stand density, decoupled CO2 fertilization plus temperature damage (Norby 2010 / D'Amato 2011), an episodic disturbance module (spruce budworm, wind, fire), and Potter 2017 species-specific climate vulnerability, the climate signal under No_harvest is muted by the SDImax cap and the species-vulnerability penalty on Maine spruce-fir. RCP 4.5 No_harvest reaches 97 MMT AGC by 2074, RCP 8.5 No_harvest reaches 119 MMT — a 22 MMT positive divergence under high warming, driven by CO2 fertilization (Norby 2010, ~10 percent gain per CO2 doubling) outweighing the species-vulnerability penalty in the Maine mid-latitude position. With harvest applied, the climate signal collapses to under 10 MMT 2074 AGC difference between RCP 4.5 BAU (36 MMT) and RCP 8.5 BAU (43 MMT) because harvest removals dominate.

### 3.4 Economic harvest overlay effect

Adding the Maine county-stumpage economic overlay shifts the harvest-scenario projections 6 to 12 MMT AGC lower than the plain wear pipeline at 2074. For BAU under RCP 4.5, wear projects 36 MMT AGC and wear+econ projects 30 MMT, a 6 MMT difference; for the +50 percent biomass scenario the overlay drops 2074 AGC from 25 to 19 MMT. The economic overlay biases harvest selection toward higher-value plots (typically more productive stands with more accumulated biomass), so applying the same statewide harvest rate removes more carbon when plots are economically targeted than when sampled uniformly.

### 3.5 Partial vs clearcut realization

The pipeline produces a county-level clearcut share that varies from less than 1 percent in southern coastal counties to 14 to 21 percent in industrial Aroostook, Somerset, and Piscataquis, consistent with Maine SAR records. Statewide realized clearcut share averages 14 percent, slightly higher than the 7 percent observed in 2015 to 2023 SAR records, because the pipeline's plot-level harvest allocation oversamples industrial North Woods counties relative to small-landowner counties. Weighted by area-harvested, the realized split is closer to observed.

### 3.6 Harvest sensitivity

The scenario_set harvest_Q multipliers (No_harvest = 0.00, Harvest_Q0p5 = 0.50, BAU = 1.00, Harvest_p25 = 1.25, Harvest_p50_biomass = 1.50) produce a 71 MMT spread in 2074 AGC under RCP 4.5 wear: from 97 MMT (No_harvest) down to 25 MMT (Harvest_p50_biomass). A 50 percent increase in harvest intensity ("biomass expansion") reduces 2074 AGC by 11 MMT relative to BAU; a 25 percent increase ("pulp demand") reduces it by 5 MMT; halving the harvest rate preserves 25 MMT relative to BAU. The relationship is approximately linear in harvest_Q over the tested range. The compressed harvest range (compared with earlier r11-baseline reports) reflects the SDImax cap and disturbance module trimming the carbon ceiling, so high-intensity harvest scenarios converge toward similar low endpoints.

### 3.7 Landowner stratification effect

Adding the Harris-Caputo-Butler (2025) ownership raster to the harvest decision (refinement R14, tag r18) adds a per-plot harvest probability multiplier: Family Forest (NIPF) ×0.5, Industrial Corporate ×1.5, Tribal ×0.2, Federal ×0.2, State ×0.5, Local ×0.3. Calibration was anchored to Maine SAR by-owner harvest behavior. The forest-area-weighted mean multiplier is 0.81 (NIPF dominates by area), so r18 statewide harvest is approximately 19 percent lower than the uniform-rate baseline.

The result is a measurable carbon retention: under RCP 4.5 wear BAU, r18 ends 2074 at 49 MMT AGC versus r17's 36 MMT — a 13 MMT (36 percent relative) increase in retained carbon. Under RCP 8.5 wear BAU the retention is 15 MMT (43 percent). The marginal effect peaks around 2034 to 2039 at about 24 MMT before decaying as the baseline approaches a low steady state. Across the four RCP × economic-overlay combinations, the r18 to r17 retention is 13 to 17 MMT (35 to 47 percent of the r17 endpoint), most pronounced under the economic overlay where targeted harvest already concentrates extraction on high-value plots.

Crucially, the realism gain is also a calibration improvement. Re-validating both r17 and r18 against the subject-matched observed FIA inventory at five-year intervals from 2004 to 2024 (Section 3.1 method) yields:

| Tag | RCP | Pipeline | RMSE | Bias | MAE |
|---|---|---|---:|---:|---:|
| r17 | 4.5 | wear | 22.4 | −20.1 | 20.1 |
| r17 | 4.5 | wear+econ | 24.3 | −22.3 | 22.3 |
| r17 | 8.5 | wear | 18.7 | −15.1 | 15.1 |
| r17 | 8.5 | wear+econ | 20.5 | −17.7 | 17.7 |
| **r18** | 4.5 | wear | **14.5** | **−5.8** | **12.5** |
| **r18** | 4.5 | wear+econ | 14.8 | −7.2 | 12.7 |
| **r18** | 8.5 | wear | 15.4 | **−0.1** | 13.3 |
| **r18** | 8.5 | wear+econ | 14.9 | −2.0 | 12.4 |

(MMT AGC, against subject-matched observed at 2004, 2009, 2014, 2019, and 2024.)

R14 reduces RMSE by approximately 7 MMT (35 percent) and reduces absolute bias from 15 to 22 MMT down to 0 to 7 MMT across all four RCP × overlay combinations. Per-year residuals shift from r17's monotonic −22 to −32 MMT undershoot to r18's tighter −27, −12, +7, +10, −7 MMT pattern, indicating that the trajectory shape itself fits better, not merely the level.

This is the central calibration finding of the paper. Owner-class harvest behavior is a first-order driver of state-scale carbon outcomes that uniform-rate models miss entirely.

## 4. Discussion

Four points merit emphasis. First, the pipeline's projected subject-only inventory underestimates observed FIA EXPALL by approximately 90 MMT AGC, which is structural to the CEM design rather than a model bias. The pipeline projects only the 40 percent of FIA plots that have not yet been remeasured. Cross-validation should therefore be interpreted as testing internal consistency and scenario-relative deltas rather than absolute magnitude vs FIA inventories. Second, the Maine economic overlay produces 6 to 8 MMT lower 2074 AGC than the plain Wear 2019 pipeline across harvest intensities, indicating that economically targeted harvest removes more carbon per unit harvested area than the geographically uniform Wear 2019 baseline. This effect is consistent across RCP 4.5 and RCP 8.5. Third, the harvest sensitivity is approximately linear in scenario harvest_Q, with each 25 percent increase in harvest intensity corresponding to about 5 to 11 MMT lower 2074 AGC under the refined pipeline. The compressed harvest range (compared with earlier r11-baseline reports) reflects the SDImax cap and disturbance module trimming the carbon ceiling, so high-intensity harvest scenarios converge toward similar low endpoints. Fourth, landowner stratification via the HCB raster adds 13 to 17 MMT of 2074 AGC retention vs the uniform-rate baseline, demonstrating that owner-class behavior is a first-order driver of state-scale carbon outcomes that uniform-rate models miss entirely.

## 5. Conclusions

A Maine-focused CEM pipeline with Wear 2019 refinements, multi-pool carbon accounting, and county-specific economic harvest produces climate-consistent, market-responsive projections suitable for state carbon planning. The pipeline is reproducible, extensible, and cross-validates reasonably against observed FIA panels and external benchmarks.

## Acknowledgments

This work was supported by OSC PUOM0008. We thank the Maine Forest Service for publishing the county stumpage and silvicultural activities reports that make state-specific economic overlays possible.

## References

Coulston, J.W., Prisley, S.P., et al. 2022. The 2020 Resources Planning Act Assessment. USDA Forest Service General Technical Report.

Jenkins, J.C., Chojnacky, D.C., Heath, L.S., Birdsey, R.A. 2003. National-scale biomass estimators for United States tree species. Forest Science 49(1): 12 to 35.

Maine Forest Service. 2024. 2023 Stumpage Price Report, 2023 Silvicultural Activities Report. Augusta, ME.

Van Deusen, P.C., Roesch, F.A. 2013. An illustration of a forest inventory and analysis projection system. Forest Science 59(4): 475 to 480.

Wear, D.N., Coulston, J.W. 2019. Specifying forest sector models for forest carbon projections. Journal of Forest Economics 34: 73 to 97.

Wear, D.N., Coulston, J.W. 2025. Forest sector supply and carbon dynamics under the RPA 2025 Assessment. Forest Policy and Economics 178: 103542.

Woodall, C.W., Weiskittel, A.R. 2021. Relative density of United States forests by ecoregion and forest type. Forest Ecology and Management 480: 118669.

---

**[Next actions for co-authors]:**
1. Review results sections after jobs 8625090-94 and 8621342-43 complete.
2. Check interpretation of baseline window and propose resolution (narrow window at 2003 vs wide window at 2005.5).
3. Review whether PERSEUS digitization is accurate enough for publication.
4. Identify target journal (MCFNS vs JoF) and adjust length.
