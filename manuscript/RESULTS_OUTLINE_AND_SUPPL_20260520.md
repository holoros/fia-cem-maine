# Results section outline + supplementary materials index

*Drafted 20 May 2026 for the multistate CEM paper.*

## 3. Results section outline (to be populated when L7b production lands)

### 3.1 Cross-state hindcast bias pattern (Section X.2.1 prose)

Figure 1: Hindcast observed vs projected AGC scatterplot, 4-panel (one per state), with 1:1 line. Source: `figures/p1_hindcast_observed_vs_projected.png`. Caption highlights the bias range and ME canonical reference.

Table 1: Per-state-RCP hindcast bias and RMSE table (8 rows: 4 states × 2 RCPs plus ME r21 reference). Source: derived from `figures/p1_hindcast_summary.csv` and the per-state HINDCAST memos.

### 3.2 Donor pool composition diagnostic (Section X.2.2 prose)

Figure 2: 4-panel donor pool composition comparison (ME, MN, WA, GA), top 8 forest type groups per panel with subject vs donor side-by-side bars. Source: `figures/multistate_donor_pool_4panel.png` (manuscript-ready, already built).

Table 2: Headline donor pool gap percentages per state, top forest type group, with mechanism notes. Source: derived from `figures/multistate_donor_pool_comparison.csv`.

### 3.3 Georgia stand-age saturation auxiliary mechanism (Section X.2.3 prose)

Figure 3 (optional): GA stand age distribution by plantation vs natural with sat_age zones marked. Source: `figures/ga_bias_candidate_diagnostic.png`.

Figure 4 (optional): Cross-state sat_age = 1.0 share comparison (GA at 85% vs ME/MN/WA at 44-60%). Source: `figures/multistate_sat_age_share.png`.

Table 3 (optional): GA bias candidate mechanisms ledger (Candidate 1 refuted, Candidate 4 confirmed, Candidate 3 dominant). Source: derived from `docs/GA_BIAS_CANDIDATES_20260517.md`.

### 3.4 CEM matching cell-size feasibility (Section X.2.4 prose)

Figure 5: Cell-size distribution histogram for 2-way (ecoregion × FORTYPCD) and 3-way (+ OWNGRPCD) stratification. Source: build from `figures/cem_strat_cell_sizes_overall.csv` and `figures/cem_3way_strat_cell_sizes_overall.csv` (build script: TBD).

Table 4: Empirical cell counts, low-donor subject percentages, comparison between 2-way and 3-way. Source: from cell-size diagnostic memos.

### 3.5 Layer 7b production rerun bias reduction (Section X.2.5 prose, populated post-production)

Figure 6: Bar chart of cycle 1 BAU pct change in mean_carbon, gr_ratio, harvest_rate per state × RCP (l7b vs p1). Source: `figures/l7b_vs_p1_cycle1_bau_figure.png` (built by `scripts/build_l7b_vs_p1_comparison.R`).

Figure 7: Revised hindcast observed vs projected scatter (post-L7b), 4-panel, with both p1 and l7b lines per state for direct comparison. To be built post-production.

Table 5: Per-state-RCP pre/post bias and RMSE comparison. From `figures/l7b_vs_p1_pct_change.csv` plus post-L7b hindcast outputs.

## 4. Discussion section figures

Figure 8 (Section 4.1 supporting): Conceptual cartoon showing the donor pool composition mechanism (subject state center, donor cohort around, with forest type composition bars). Could be built as a schematic. Optional.

## 5. Supplementary materials index

### S1. State_constants.csv parameters

Filename: `manuscript/supplement_S1_state_constants.csv`

Content: full per-state parameter table including dT trajectories, fire baseline, SDImax, terminal age, growth_start_age, SBW relevance, plus the per-state references for each parameter.

### S2. Forest type composition by state and donor cohort

Filename: `manuscript/supplement_S2_donor_pool_composition.csv`

Content: row-per-(state-rcp-fortyp), columns: state, RCP, subject_pct_area, donor_pct_area, gap_pp. Built from `figures/multistate_donor_pool_comparison.csv`.

### S3. EPA L3 to Bailey section crosswalk

Filename: `config/l3_to_section.csv` (manuscript supplement, already deployed)

Content: 85 EPA L3 ecoregions mapped to 20 broader section codes for CEM iter2 coarsening.

### S4. CEM Layer 7b patch source

Filename: `manuscript/supplement_S4_cem_layer7b_patch.R`

Content: the patched R/02_cem_matching.R with the coarsen_ecoregion helper and cem_ecoregion in iter1/2/3 matching keys. Released as a standalone supplement so other CEM frameworks can adopt the same matching strategy.

### S5. Per-state hindcast detail tables

Filename: `manuscript/supplement_S5_hindcasts_<state>_<rcp>_<patch>.csv` (8 files)

Content: per-year hindcast residual table (observed AGC, projected AGC, residual, % residual) for ME/MN/WA/GA × RCP4.5/8.5 under both p1 baseline and Layer 7b patched configurations.

### S6. Bias mechanism investigation chronology

Filename: `manuscript/supplement_S6_bias_mechanism_chronology.md`

Content: bullet-point chronology of the 17-20 May diagnostic suite as a methodological transparency record. References to each docs/*MEMO with brief one-line explanation. Documents what hypotheses were tested, which were confirmed, which were refuted.

### S7. Layer 7b smoke validation

Filename: `manuscript/supplement_S7_l7b_smoke_validation.csv`

Content: ME 10-sim 5-cycle smoke output showing 99.7 percent CEM match rate, iter-by-iter breakdown, BA/volume/carbon trajectories within sampling of pre-patch baseline. Documents that the patch produces sensible output before scaling to production.

### S8. conus_hcs RPA comparison

Filename: `manuscript/supplement_S8_rpa_comparison.md`

Content: cross-reference to the conus_hcs RPA aggregation work (`docs/RPA_COMPARISON_RESULTS_20260517.md` and `docs/M2_UNIT_RESOLUTION_20260517.md`). Reports the unit-corrected 2.5x-3.7x over-prediction relative to RPA 2016 baseline, with the re-measurement bias correction factor of approximately 0.35 documented as a future iteration.

## 6. Build order

When production reruns land (8 SLURM jobs at 10021618-10021625), the analysis workflow is:

1. `bash scripts/run_l7b_hindcasts.sh` on Cardinal
2. Pull `figures/l7b_vs_p1_cycle1_bau_*.csv` and `.png` to local
3. Pull `docs/HINDCAST_<STATE>_<L7b_TAG>.md` (8 new memos)
4. Update manuscript Section X.2.5 prose with the actual reduction percentages
5. Update manuscript Table 5 with the pre/post comparison
6. Re-render Figure 7 with both p1 and l7b lines
7. Merge SECTION_X1, SECTION_X2_BIAS_MECHANISM, INTRODUCTION, DISCUSSION drafts into the main MULTISTATE_METHODS_DRAFT
8. Build supplementary materials S1-S8

Effort post-production: ~6 hours of editorial integration once the SLURM outputs are pulled. Total manuscript skeleton at that point: introduction, methods, results, discussion all in place, with figures and tables resolved. Targeting journal of forestry or canadian journal of forest research as candidate venues.
