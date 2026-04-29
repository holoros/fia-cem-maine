# Changelog

## r18 — 29 April 2026 (active landowner-stratified pipeline)
- Added Harris–Caputo–Butler 2025 landowner stratification (R14) — **landed in v2**
- Built `config/fia_plots_with_owner.csv` (6,288 Maine FIA plots × HCB class)
- Patched `R/06_projection_engine.R` with `get_owner_harvest_mult()` helper and per-plot owner multiplier in both fixed_harvest_rate and donor-rate branches (the v1 patch in 03_harvest_choice.R turned out to be on a code path that production runs don't take, so v2 moved the patch to 06)
- Patched `R/03_harvest_choice.R` with `cfg$harvest$use_owner_stratification` flag (kept for econ-overlay path)
- New CLI flag `--use_owner_stratification`
- Added `docs/LANDOWNER_INTEGRATION_STRATEGY.md`
- New supplement: `manuscript/supplement_S3_maine_ownership_atlas.docx`
- **Result:** r18 retains 13–17 MMT MORE 2074 AGC than r17 across the four RCP × econ-overlay combinations. NIPF (54% of forest) at ×0.5 multiplier dominates the area-weighted mean to 0.81, so statewide harvest is ~19% lower than uniform-rate baseline. Marginal effect peaks at ~24 MMT around 2034–2039 then decays.
- New figures: `fig_r17_vs_r18_rcp{45,85}.png`, `fig_r18_summary_2x2.png`

## r17 — 27 April 2026 (canonical refined-pipeline baseline)
- DESIGNCD filter on subject-pool expansion (excludes pre-1999 periodic plots)
- 2004 BAU AGC = 231 MMT (vs r12 overshoot 400 MMT, vs r11 baseline 240 MMT)
- 2074 RCP 4.5 wear BAU AGC = 36 MMT
- Manuscript Section 3 refreshed with r17 numbers
- New summary docx: `manuscript/r17_progression_summary.docx`

## r12–r16 — 26 April 2026
- r12: R1 subject pool expansion via `--include_remeasured` (overshoots 2004 baseline by +120 MMT due to inclusion of pre-1999 periodic plots; fixed in r17)
- r13: R5 BRMS Reineke SDImax cap (`--use_brms_sdimax`)
- r14: R8 decoupled CO2 + temperature climate (`--use_decoupled_climate`); R6 episodic disturbance (`--use_disturbance`)
- r15: R4 FORTYPCD species climate (`--use_species_climate`)
- r16: R4-VCC Potter 2017 SPCD-resolved climate vulnerability (`--use_potter_vcc`)
- Added BRMS posterior plot-level SDImax dataset to `config/`
- Added Potter 2017 CAPTURE 304-species vulnerability database

## r11 — 19 April 2026 (manuscript headline at submission)
- Hindcast validation: RMSE 16 MMT, bias −2 MMT vs subject-matched observed
- 1999 baseline, 10-yr anchor window, 5 harvest scenarios, RCP 4.5/8.5 HadGEM2-AO

## r10 — 17 April 2026
- Removed `--no_econ` flag misuse so the Wear 2025 supply logit actually runs
- Maine economic harvest module (`R/11_economic_harvest.R`) finalized

## R12 calibration — 27 April 2026
- Built `config/maine_county_harvest_logit_offset.csv` (16-county SAR-calibrated additive logit offsets, range −1.46 Aroostook to +1.50 Sagadahoc cap)
- Patched `R/03_harvest_choice.R` with `cfg$harvest$use_county_harvest` flag
- New CLI flag `--use_county_harvest`

## R9/R10 land-use — 26 April 2026
- Added `maine_land_use_scenarios()` to `R/05_scenario_biasing.R`
- Wired `scenario_lookup` and `new_forest_c_frac` into `R/10_state_expansion.R`
- BAU loses 2% AGC by 2074; Develop2x 4%; Reforest50k +4%; LowDev_HiRefor +5%

## SDImax tables — 26 April 2026
- New supplement `manuscript/supplement_S2_sdimax_ecoregion.docx`
- Aggregated 3,253 Maine BRMS plot estimates by 4 ecoregions × 7 forest-type groups

## Earlier (r6–r9)
- Initial Wear 2019 age saturation, multi-pool C decomposition (7 pools)
- Subject pool collapse fix
- Hindcast bias diagnostics
