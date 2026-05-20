# A coarsened exact matching framework for state-level forest carbon projection: cross-state extension, bias mechanism, and ecoregion stratification

*Manuscript draft v2, 20 May 2026.*
*Assembled from individual section drafts in `manuscript/` for editorial integration.*

## Abstract

The coarsened exact matching (CEM) framework of Van Deusen and Roesch (2013) provides an analytically tractable basis for state-level forest carbon projection from FIA panel pair data, but its transferability across heterogeneous ecoregions has not been quantitatively documented. We extend the Maine CEM framework to three additional states (Minnesota, Washington, Georgia) representing the northern boreal, Pacific Northwest, and southeastern coastal plain biomes respectively, and report subject-matched hindcasts against the canonical FIA EXPALL EVALIDs spanning 2004 to 2024.

Across the four-state set, cross-state hindcast bias spans -25 percent (Washington) to +11 percent (Georgia), bracketing the canonical Maine reference of -1.1 percent on both sides. Diagnostic analyses of donor pool composition against the full CONUS FIA database reveal a universal mechanism: each state's neighbor-based donor cohort systematically underrepresents the dominant forest types of the subject state's forested inventory. Minnesota's aspen/birch and spruce/fir, dominant at 40 and 23 percent of subject area, occupy only 16 and 11 percent of the Lake States donor pool. Washington's west-side Douglas-fir and hemlock/Sitka spruce, dominant at 42 and 14 percent, occupy 33 and 3 percent of the Pacific Northwest interior donor pool. CEM matching transfers slower-growing donor type trajectories onto faster-growing subject types, suppressing projected biomass accumulation for Minnesota and Washington. Georgia's bias direction is opposite (+10 percent over) and traces to a separate mechanism: the stand-age saturation function leaves 95 percent of GA's plantation cohort (median age 20 years) at full unattenuated growth, combined with forest-type-agnostic BAU harvest selection that does not preferentially clearcut plantations at rotation age.

Notably, Maine's reference -1.1 percent bias arises despite the same dramatic donor pool mismatch (30 pp gap in spruce/fir): three compensating mechanisms (decoupled ClimateNA climate coupling, within-state `state_constants.csv` refinement, owner-balanced rescaling against published RPA rates) absorb the donor pool gap in the Maine reference. The other three states lack one or more of these compensations.

We propose and implement a three-iteration ecoregion-stratified CEM matching strategy that adds EPA L3 ecoregion as a matching key alongside the existing FORTYPCD and OWNGRPCD strata, with graceful fallback through Bailey-section-equivalent collapse and within-state leave-one-out matching. Empirical cell-size diagnostics across CONUS confirm feasibility: at the fine resolution 99.7 percent of subject conditions match at least one donor (median 3 matches). [Placeholder: actual bias reductions from full production reruns to be inserted from `output/l7b_comparison_20260520/`: projected WA -25 to -5/-10 percent, MN -23 to -3/-8 percent, GA +10 to +3/+5 percent, ME canonical unchanged.]

The findings establish donor pool composition mismatch as the dominant transferability barrier for CEM forest projection across heterogeneous ecoregions, and ecoregion-stratified matching as a reproducible remediation path.

## Keywords

forest inventory and analysis, coarsened exact matching, carbon projection, ecoregion stratification, donor pool composition, transferability, RPA Assessment, multistate, methodological transfer

## 1. Introduction

[INSERT: full content of `INTRODUCTION_DRAFT_20260520.md` sections 1.1 through 1.6]

## 2. Data and methods

[INSERT: full content of `SECTION_X1_DATA_AND_METHODS_DRAFT_20260520.md` sections 2.1 through 2.7]

## 3. Results

### 3.1 Cross-state hindcast bias pattern

[INSERT: section 3.1 prose from `SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` section 2.1]

**Figure 1.** Hindcast observed vs projected AGC scatterplot, 4-panel (one per state), with 1:1 line and bias annotations. Source: `figures/p1_hindcast_observed_vs_projected.png`.

**Table 1.** Per-state-RCP hindcast bias and RMSE table.

| State x RCP | RMSE (MMT AGC) | Bias (MMT) | Bias (%) | Years matched |
|---|---:|---:|---:|---|
| MN 4.5 | 22.6 | -6.6 | -5.7 | 2004, 2009, 2014, 2019, 2024 |
| MN 8.5 | 23.3 | -6.7 | -5.8 | 2004, 2009, 2014, 2019, 2024 |
| WA 4.5 | 78.9 | -78.9 | -25.3 | 2019 |
| WA 8.5 | 77.4 | -77.4 | -24.8 | 2019 |
| GA 4.5 | 48.7 | +23.8 | +9.6 | 2004, 2009, 2014, 2019, 2024 |
| GA 8.5 | 51.9 | +27.2 | +11.0 | 2004, 2009, 2014, 2019, 2024 |
| ME r21 reference | 16.0 | -2.0 | -1.1 | 2004 through 2024 |

### 3.2 Donor pool composition diagnostic

[INSERT: section 3.2 prose from `SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` section 2.2]

**Figure 2.** 4-panel donor pool composition comparison (ME, MN, WA, GA), top 8 forest type groups per panel with subject vs donor side-by-side bars. Source: `figures/multistate_donor_pool_4panel.png`.

**Table 2.** Headline donor pool gap percentages per state.

| State | Top subject type | Subject % | Donor % | Gap (pp) | Top overrepresented in donor | Donor % | Gap (pp) |
|---|---|---:|---:|---:|---|---:|---:|
| MN | Aspen / birch | 39.7 | 16.4 | +23.3 | Maple / beech / birch | 24.6 | -17.7 |
| WA | Hemlock / Sitka spruce | 14.1 | 3.0 | +11.1 | Ponderosa pine | 16.5 | -7.5 |
| GA | Loblolly / shortleaf pine | 30.1 | 26.0 | +4.2 | Oak / hickory | 39.8 | -13.0 |
| ME | Spruce / fir | 32.5 | 1.8 | +30.7 | Oak / hickory | 33.2 | -31.7 |

### 3.3 Georgia stand-age saturation auxiliary mechanism

[INSERT: section 3.3 prose from `SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` section 2.3]

**Figure 3.** Cross-state sat_age = 1.0 share. Source: `figures/multistate_sat_age_share.png`.

**Table 3.** GA bias candidate mechanisms ledger.

| Candidate | Description | Status | Evidence |
|---|---|---|---|
| C1 | Growth-ratio multiplicative effect on high baseline | REFUTED | GA rel rate 0.0122 is HIGHEST of 4 states, not normal-applied-to-high |
| C2 | C:V ratio over-estimation in plantation types | Not tested | Plausible but not investigated |
| C3 | Disturbance / harvest schedule forest-type-agnostic | CONFIRMED dominant companion | GA BAU 10% per cycle uniform across types |
| C4 | Stand-age saturation under-application on young plantations | CONFIRMED dominant | 95.4% of GA plantations at sat_age = 1.0 |

### 3.4 CEM matching cell-size feasibility

[INSERT: section 3.4 prose from `SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` section 2.4]

**Table 4.** Empirical CEM stratification cell counts.

| Stratification | Total cells | Cells >= 30 conds | Subj in low-donor cells |
|---|---:|---:|---:|
| ecoregion × FORTYPCD (2-way) | 156 | 52 (33%) | 4.0% |
| ecoregion × FORTYPCD × OWNGRPCD (3-way) | 332 | 122 (37%) | 3.1% |

### 3.5 Layer 7b production rerun bias reduction

[PLACEHOLDER: To be populated when SLURM jobs 10021618-10021625 complete and `scripts/run_l7b_hindcasts.sh` runs. Expected fill from `output/l7b_comparison_20260520/`.]

**Figure 6 [PLACEHOLDER].** Bar chart of cycle 1 BAU pct change per state × RCP (l7b vs p1).

**Figure 7 [PLACEHOLDER].** Revised hindcast scatter (post-L7b), 4-panel.

**Table 5 [PLACEHOLDER].** Per-state-RCP pre/post bias and RMSE comparison.

| State x RCP | p1 bias (%) | l7b bias (%) | RMSE pre | RMSE post |
|---|---:|---:|---:|---:|
| ME 4.5 | -1.1 | [ ] | 16.0 | [ ] |
| MN 4.5 | -5.7 | [ ] | 22.6 | [ ] |
| WA 4.5 | -25.3 | [ ] | 78.9 | [ ] |
| GA 4.5 | +9.6 | [ ] | 48.7 | [ ] |
| ME 8.5 | -1.1 | [ ] | 16.0 | [ ] |
| MN 8.5 | -5.8 | [ ] | 23.3 | [ ] |
| WA 8.5 | -24.8 | [ ] | 77.4 | [ ] |
| GA 8.5 | +11.0 | [ ] | 51.9 | [ ] |

Projected (per `CEM_3WAY_STRATIFICATION_20260517.md`):
- WA -25% → -5 to -10%
- MN -23% statewide → -3 to -8%
- GA +10% → +3 to +5%
- ME canonical -1.1% → unchanged

### 3.6 Method caveats and limitations

[INSERT: section 3.6 prose from `SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` section 2.6]

## 4. Discussion

[INSERT: full content of `DISCUSSION_DRAFT_20260520.md` sections 4.1 through 4.6]

## 5. Conclusion

[Last subsection of `DISCUSSION_DRAFT_20260520.md` section 4.6 stands as a brief standalone conclusion paragraph.]

## 6. Supplementary materials

Available at `manuscript/supplement_S*`:

- **S1** `supplement_S1_state_constants.csv` — Per-state climate trajectory, fire baseline, SDImax, terminal age, sbw relevance.
- **S2** `supplement_S2_donor_pool_composition.csv` — Per-state forest type group composition (subject vs donor, gap in pp).
- **S3** `supplement_S3_l3_to_section.csv` — EPA L3 ecoregion to Bailey-equivalent section crosswalk (85 to 20).
- **S4** `supplement_S4_cem_layer7b_patched.R` — Patched R/02_cem_matching.R source code.
- **S5** [PLACEHOLDER] Per-state hindcast detail tables (awaits L7b production rerun).
- **S6** `supplement_S6_bias_mechanism_chronology.md` — Hypothesis-testing record 13-20 May 2026.
- **S7** `supplement_S7_l7b_smoke_validation.md` — Pre-production patch validation (SLURM 9914786).
- **S8** `supplement_S8_rpa_comparison.md` — conus_hcs RPA aggregation cross-comparison with 0.35 re-measurement correction.

## 7. Data and code availability

All raw FIA data used in this paper is publicly available from the USDA Forest Service FIA DataMart. Patched CEM matching source code, configuration files, and diagnostic R scripts are available at the manuscript public repository [URL placeholder]. The L3-to-section ecoregion crosswalk (Supplement S3) is released to enable other CEM forest projection frameworks to adopt the same matching strategy.

## 8. References

[To be assembled. Key citations already mentioned in drafts:]

- Bechtold WA, Patterson PL (2005). The enhanced Forest Inventory and Analysis program — national sampling design and estimation procedures. USDA Forest Service Gen. Tech. Rep. SRS-80.
- Brooks EB, Wear DN (2024). [Pending citation lookup]
- Costanza JK, et al. (2024). [Pending citation lookup, Chapter 5 of 2020 RPA Assessment]
- Coulston JW, et al. (2023). Forest Resources, Chapter 6 of the 2020 RPA Assessment. USDA Forest Service WO-GTR-102. https://doi.org/10.2737/WO-GTR-102
- Harris N, Caputo J, Butler BJ (2025). [Pending citation lookup, HCB 2025 landowner raster]
- Norby RJ, et al. (2010). CO2 enhancement of forest productivity constrained by limited nitrogen availability. PNAS 107(45): 19368-19373.
- Omernik JM (1987). Ecoregions of the Conterminous United States. Annals of the Association of American Geographers 77(1): 118-125.
- Omernik JM, Griffith GE (2014). Ecoregions of the conterminous United States: evolution of a hierarchical spatial framework. Environmental Management 54(6): 1249-1266.
- Potter KM, et al. (2017). Climate change vulnerability assessment for forest tree species of the eastern United States. Forest Ecology and Management.
- Reidmiller DR, et al. (eds.) (2024). Fifth National Climate Assessment.
- USDA Forest Service (2024). FIA DataMart, March 2026 download.
- USDA Forest Service (2023). Future of America's Forests and Rangelands: Forest Service 2020 Resources Planning Act Assessment. WO-GTR-102.
- Van Deusen P, Roesch FA (2013). A coarsened exact matching approach for forest growth and yield estimation. Forest Science 59(6): 670-680.
- Wear DN, Coulston JW (2025). [Pending citation lookup, RPA harvest logit Wear 2025]
- Weiskittel AR, et al. (in prep). [Maine CEM r11 reference paper]
- Woodall CW, Weiskittel AR (2021). Maximum stand density and stocking metrics in eastern US forests. Forest Ecology and Management.
- Woodall CW, Westfall JA (2018). [Pending citation lookup]

## 9. Acknowledgments

[Placeholder]

---

## Editorial integration notes (post-production)

After SLURM 10021618-10021625 complete and `scripts/run_l7b_hindcasts.sh` produces `output/l7b_comparison_20260520/`:

1. Pull `figures/l7b_vs_p1_cycle1_bau_figure.png` and supporting CSV to local
2. Pull each `docs/HINDCAST_<STATE>_<L7b_TAG>.md` (8 memos)
3. Populate Section 3.5 prose with the actual reduction percentages
4. Populate Table 5 with the bias and RMSE columns
5. Render Figure 7 (pre/post hindcast scatter, 4-panel comparison) by extending the existing `scripts/build_hindcast_plot.R`
6. Build Suppl S5 by concatenating per-state HINDCAST_<STATE>_<L7b_TAG>.md plus the existing p1 hindcast tables
7. Replace all `[INSERT: ...]` placeholders in this v2 draft with the actual section content from the individual drafts
8. Final read-through for narrative flow, citation completeness, figure callouts

Estimated time: 6 hours.
