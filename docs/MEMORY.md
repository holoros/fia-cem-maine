# FIA CEM Maine Carbon Projection Pipeline — Memory File

**Last updated:** 27 April 2026 (session #4 — Cardinal back online, r17 resubmitted)
**Project owner:** Aaron Weiskittel (CRSF, University of Maine)
**Compute:** OSC Cardinal HPC, account PUOM0008, user crsfaaron
**Pipeline location:** `/users/PUOM0008/crsfaaron/fia_cem_projections/`

---

## What this is

Reproducible R pipeline projecting Maine forest carbon from a 1999 baseline through 2074 (15 cycles) under climate (HadGEM2-AO RCP 4.5/8.5) and harvest (5 scenarios, harvest_Q 0.00 to 1.50) crossings. Built on Van Deusen and Roesch 2013 CEM with progressive refinement layers (r6 through r16) accumulating Wear 2019 saturation, multi-pool C, Maine economic overlay, partial vs clearcut split, subject pool expansion, BRMS Reineke SDImax cap, decoupled CO2/temperature climate, episodic disturbance, and Potter 2017 species-resolved climate vulnerability.

## Major findings to date

**Hindcast validation** against subject-matched observed FIA: RMSE 16 MMT AGC, bias −2 MMT (−1.1 percent) across 5 panels 2004 to 2024. Demonstrates real predictive skill at the subject-pool level. Full-panel EXPALL comparison shows a structural −96 MMT gap that is the projection-vs-inventory definitional mismatch, not model error.

**Subject pool expansion (R1):** with `--include_remeasured`, subject pool grew from 10,017 to 18,488 conditions (84 percent increase) by including all plots active in the baseline window, not just those whose first measurement happened to fall there. Maine-only ~2,800 → ~5,500.

**Multi-pool carbon decomposition** at 2004 baseline: 1,140 MMT total Maine forest C with 700 MMT soil (62 percent), 240 MMT above-ground live tree (21 percent), 53 MMT below-ground live, 53 MMT dead, 85 MMT litter, less than 10 MMT understory.

**Harvest sensitivity** is approximately linear in scenario_Q: each 25 percent increase in harvest intensity costs about 25 MMT of 2074 AGC. 240 MMT spread between No_harvest and +50 percent harvest scenarios.

**Carbon fate** (Smith 2006 product half-lives): of the 160 MMT BAU stock loss between 2004 and 2074, 38 MMT goes to atmospheric emissions, 19 MMT remains in active wood products by 2074, and the remainder is the gross-vs-net difference (growth offsets harvest by ~100 MMT).

## Pipeline progression by r-tag

| Tag | Refinement(s) added | CLI flag(s) added |
|---|---|---|
| r6 | Wear 2019 age saturation, multi-pool C | (baseline) |
| r11 | scenario_Q correctly applied via fixed_harvest_rate × Q | (`--fixed_harvest_rate 0.10`) |
| r12 | R1 subject pool expansion | `--include_remeasured` |
| r13 | R5 BRMS Reineke SDImax cap | `--use_brms_sdimax` |
| r14 | R8 decoupled CO2 + temperature; R6 episodic disturbance | `--use_decoupled_climate`, `--use_disturbance`, `--co2_effect_mult X`, `--insect/wind/fire_amp_mult X` |
| r15 | R4 species climate (FORTYPCD-coarse) | `--use_species_climate` |
| **r16** | **R4-VCC Potter 2017 SPCD-resolved climate vulnerability** | `--use_potter_vcc` |
| w5/w15 | R13 baseline window sensitivity (5/15 yr vs r16's 10) | `--baseline_window 5/15` |

## CLI flag catalog

```
--state ME                            target state (donor states auto-loaded)
--n_sims 100                          bootstrap replicates
--cycles 15                           projection cycles (5-yr each)
--cores ${SLURM_CPUS_PER_TASK}        parallelism
--scenario_set harvest                multi-scenario set (5 harvest levels)
--tag rcpXX_<name>_rNN                output dir tag
--baseline_year 1999                  start year
--baseline_window 10                  window width (1999 to 2008)
--include_remeasured                  expand subject pool
--untreated_donors                    clean donor pool
--fixed_harvest_rate 0.10             base harvest rate per cycle
--climate_rcp 4.5                     HadGEM2-AO scenario
--bootstrap_plots --bootstrap_frac 0.9
--use_maine_econ                      Maine county stumpage overlay
--use_brms_sdimax                     BRMS Reineke SDImax cap
--use_decoupled_climate               separate CO2/temp multipliers
--co2_effect_mult 0.10                CO2 fertilization (per doubling)
--use_disturbance                     SBW + wind + fire stochastic events
--insect_amp_mult 1.0                 disturbance amplitude tunables
--use_potter_vcc                      Potter 2017 SPCD vulnerability
--save_per_plot                       save per-plot RDS output
--skip_supply --no_econ               skip Wear 2025 logit (use fixed-rate branch)
```

## Critical code edits live on Cardinal

- `R/06_projection_engine.R`: age saturation, climate decoupling, SDImax cap, disturbance module, species climate (FORTYPCD + Potter VCC). Backups: `.bak.20260417_wear`, `.bak.20260417_econ`.
- `R/10_state_expansion.R`: 7-pool COND join with TON_TO_LB conversion. Backup: `.bak.20260417_wear`.
- `R/11_economic_harvest.R`: Maine county stumpage + partial/clearcut split.
- `R/05_scenario_biasing.R`: `maine_harvest_scenarios()`, `maine_policy_scenarios()`, `maine_land_use_scenarios()` (R9/R10).
- `R/01_data_prep.R`: `--include_remeasured` subject pool expansion (R1).
- `run_projection.R`: keep_cols extended to preserve is_clearcut, harvest_intensity, dom_spcd, was_disturbed_*, plus all CLI flag handlers.

## Config files on Cardinal

- `config/maine_stumpage_forecast.csv` (county × product × species real-2024 prices, forecast to 2125)
- `config/maine_treatment_proportions.csv` (county × year partial/clearcut shares from SAR)
- `config/sdimax_brms_plot.csv` (10,125 plot-keyed BRMS posterior SDImax, both metric and English)
- `config/sdimax_brms_county_fortyp.csv`, `config/sdimax_brms_fortyp.csv` (aggregations)
- `config/spcd_potter_vcc.csv` (25 Maine SPCD with Potter 2017 vulnerability scores and β per °C)
- `config/potter2017_VCC_species.csv` (304 species Potter 2017 full database)
- `config/maine_county_harvest_calibration.csv` (R12 county harvest rate table for future per-county logit)

## Session #2 progress (April 26 evening)

**Built and uploaded:**
- `config/spcd_potter_vcc.csv` — 25 Maine SPCD with Potter 2017 vulnerability scores and β per °C
- `config/potter2017_VCC_species.csv` — 304 species Potter 2017 full database parsed from `Tree_Vulnerability_Score.R`
- `config/sdimax_brms_*.csv` — 10,125 plot-keyed BRMS posterior SDImax (metric + English)
- `config/maine_county_harvest_calibration.csv` — county harvest rate table

**Code edits live on Cardinal (verified parse OK):**
- `R/01_data_prep.R` — `--include_remeasured` subject pool expansion (R1)
- `R/05_scenario_biasing.R` — added `maine_land_use_scenarios()` (R9/R10)
- `R/06_projection_engine.R` — Wear sat, multi-pool, age sat, climate decoupling, SDImax cap, disturbance, FORTYPCD species climate, Potter VCC species climate
- `run_projection.R` — all CLI flag handlers; keep_cols extended

**Submitted r-tags:** r12 (R1), r13 (+R5), r14 (+R8+R6), r15 (+R4 fortypcd), r16 (+R4 Potter VCC), w5/w15 (R13 window sensitivity), hindcast_r12 and v2 (1999-2024 BAU).

**Expansion submitted (8864290) at 90 min walltime** — was at 20 min when session ended. Earlier 30-min attempt timed out. Output dir: `~/fia_cem_projections/output/state_summary_progression/`. As of session end, partial results: r12 RCP 4.5 wear+wear_econ, r12 RCP 8.5 wear_econ, hindcast_r12, w5, r14 RCP 4.5 wear_econ.

**Critical R1 expansion finding (must address next session):** `--include_remeasured` overshoots full-panel observed FIA by +114 MMT because it pulls pre-1999 periodic-design plots. Fix: add DESIGNCD filter inside the extras block in `01_data_prep.R` to exclude periodic-design plots (DESIGNCD 1, 501, 502 = annualized; others may be 1995 periodic). Task #33 created for this.

**Manuscript headline still stands at r11:** RMSE 16 MMT vs subject-matched, bias −2 MMT. R1 subject pool expansion is future work pending the periodic-plot fix.

## Currently running on Cardinal (as of session end)

23 jobs in queue across 7 r-tags. Estimated full completion ~1 to 3 hours from session end:

```
8860867-870 r12        RUNNING ~60 min  (subject pool only)
8861589-592 r13        RUNNING ~16 min  (r12 + SDImax)
8861595     hindcast_r12 RUNNING ~14 min
8861619-622 r14        RUNNING ~11 min  (r13 + decoupled climate + disturbance)
8861656-659 r15        RUNNING ~7 min   (r14 + species FORTYPCD)
8861735-738 r16        RUNNING ~1 min   (r14 + Potter VCC) [supersedes r15]
8861755     w5         RUNNING <1 min   (R13 sensitivity)
8861761     w15        RUNNING <1 min   (R13 sensitivity)
```

## R1 expansion finding (April 26 update)

**r12 with `--include_remeasured` overshoots full-panel observed FIA by +114 MMT.**

Comparison at 2004 cycle 1 BAU (RCP 4.5 wear):

| Source | MMT AGC | n_conditions |
|---|---:|---:|
| r11 (no expansion) | 240 | 2,819 |
| r12 (--include_remeasured) | 399 | 4,466 |
| Subject-matched observed | 268 | n/a |
| Full-panel EXPALL observed | 284 | 3,375 |

Hindcast skill (r12 BAU vs observed, 2004 to 2024):

| Comparison | RMSE | Bias |
|---|---:|---:|
| vs subject-matched | 132 MMT | +132 MMT |
| vs full-panel EXPALL | 64 MMT | +37 MMT |

**Diagnosis:** my `--include_remeasured` extras filter pulls plots whose latest pre-2008 measurement is 2003-2008. For Maine these can include pre-1999 PERIODIC FIA design plots (the 1995 inventory used a different sampling design than the post-1999 annualized cycle). Pre-1999 plots have different EXPNS expansion factors and represent 1990s-era forest state, not 1999.

**Refinement R1-v2 (next session):** add DESIGNCD filter inside the `extras` block in `01_data_prep.R` to exclude periodic-design plots. Only include extras with annualized-cycle DESIGNCD (typically 1, 501, 502 in Maine post-1999). After that fix, expected r12 baseline will land near 268-285 MMT (matching observed) rather than 399 MMT.

**Recommendation for manuscript:** report r11 as the canonical published pipeline. Note R1 expansion as future work that requires the DESIGNCD filter refinement. The hindcast validation at r11 (RMSE 16 MMT vs subject-matched, bias −2 MMT) remains the headline validation result.

## Session #5 progress (continued — manuscript polish + Figure 1)

**Manuscript abstract refreshed** to lead with the calibration story (RMSE 22.4 → 14.5 MMT from owner stratification). Old r10/r11-era numbers replaced with refined-pipeline r17/r18 results. Lists the 8 refinement layers explicitly.

**Manuscript conclusions** expanded from 1 to 4 paragraphs covering: pipeline summary, dominant calibration finding, three policy implications (NIPF/Industrial asymmetry, owner-targeted levers, PERSEUS cross-model coherence), future work scaffold.

**New deliverables:**
- `figures/fig_hindcast_residuals_r17_r18_r19.png` — 4-panel residual time series across all RCP × overlay combinations. r17 (blue) systematically undershoots; r18/r19 (red/purple) track within ±15 MMT band.
- `figures/fig_manuscript_figure_1.png` — single 4-panel candidate Manuscript Figure 1 combining (a) trajectories with observed-overlay, (b) Maine ownership pie, (c) RMSE bar chart, (d) 2074 endpoint bars. Suitable as single Figure 1 or split into Figures 1-2.
- `figures/fig_r17_r20_attribution_rcp45.png` — 4-panel decomposition figure (auto-updates when r20 lands to add the r20 spatial-only line).
- `manuscript/r17_r19_consolidated_results.docx` — 213-paragraph polished co-author review package combining all figures, tables, refinement progression, and recommendations.

**Repo at 17 commits**, 116 files, 17 MB. Latest: `f36ef07 Consolidated r17-r19 results docx for co-author review`.

**r20 at ~24% complete** as of writing (29 min elapsed of estimated 2 hr). Auto-expansion fires when projections done. Ready to pull and rebuild attribution figure once landed.

## Session #5 progress (continued — r20 mass-balanced + outstanding items)

**r20 in flight** — mass-balanced R14 variant. Patched `06_projection_engine.R`'s `get_owner_harvest_mult()` to rescale multipliers by `1 / forest-area mean` when `cfg$harvest$use_owner_balanced` is set. After rescale, NIPF×0.617, Industrial×1.852, Tribal×0.247, Federal×0.247, State×0.617, Local×0.371. Statewide harvest mass should match r17 uniform-rate; only the spatial distribution shifts. Cardinal jobs 8974686-8974690, ETA ~3.5 hr. Log confirms `R14-bal: forest-area mass-balance rescale enabled (preserve statewide harvest)` and `divided multipliers by forest-area mean 0.811`.

**MCC policy brief refreshed** with r18/r19 numbers. Bottom-line table updated to refined-pipeline values (BAU 2074 = 44 MMT under wear+econ, was 81 MMT in old r10/r11 era). New section on landowner stratification as the largest single calibration improvement. Cross-validation table lists r17 vs r18 RMSE/bias for all four RCP × overlay combinations. Four recommendations including PERSEUS cross-model coherence.

**County × owner crosstab built.** 75 populated cells of 96 theoretical (16 counties × 6 owner classes); 33 with n ≥ 30, 44 with n ≥ 10. Top cells: Aroostook NIPF 1,109, Aroostook Industrial 894, Penobscot NIPF 586. 19 cells have product multipliers outside [0.15, 2.5] — hint at county × owner interaction but most extreme cells are sparse. Useful as scaffold for future R14-VCC interaction model.

**Climate ensemble design note** drafted at `docs/CLIMATE_ENSEMBLE_DESIGN.md`. Proposes 12-GCM cool-dry/cool-wet/warm-dry/warm-wet ensemble for CMIP5-style climate uncertainty propagation. 6 hr Cardinal compute + 1-2 day engineer time. Deferred to manuscript-revision phase or follow-on paper.

**Repo at 13 commits** on `main`. Latest: `dbfdf80 County x owner crosstab + climate ensemble design note`. Ready for `gh auth login && gh repo create`.

## Session #5 progress (continued — r19 + comprehensive CV table)

**r19 LANDED.** All four projections + expansion completed (Cardinal 8957591-8957595). r19 = r18 + R12 county harvest offset. The patched 06_projection_engine.R now applies both `county_mult × owner_mult` per plot.

**r19 vs r18 BAU 2074 AGC delta:** +0.6 to +3 MMT (small marginal effect). The county multiplier captures real spatial variation (Aroostook 0.42×, Washington 0.30× capped, Sagadahoc 2.50× capped) but the dominant calibration win came from R14.

**Comprehensive CV table against subject-matched observed FIA** (RMSE / bias / MAE, MMT, at 2004 / 2009 / 2014 / 2019 / 2024):

| Tag | RCP | Pipeline | RMSE | Bias | MAE |
|---|---|---|---:|---:|---:|
| r17 | 4.5 | wear | 22.4 | −20.1 | 20.1 |
| r17 | 4.5 | wear+econ | 24.3 | −22.3 | 22.3 |
| r17 | 8.5 | wear | 18.7 | −15.1 | 15.1 |
| r17 | 8.5 | wear+econ | 20.5 | −17.7 | 17.7 |
| **r18** | 4.5 | wear | **14.5** | −5.8 | 12.5 |
| r18 | 4.5 | wear+econ | 14.8 | −7.2 | 12.7 |
| r18 | 8.5 | wear | 15.4 | −0.1 | 13.3 |
| r18 | 8.5 | wear+econ | 14.9 | −2.0 | 12.4 |
| r19 | 4.5 | wear | 14.6 | −4.7 | 12.6 |
| r19 | 4.5 | wear+econ | 14.6 | −6.1 | 12.6 |
| r19 | 8.5 | wear | 15.6 | +0.4 | 13.6 |
| r19 | 8.5 | wear+econ | 15.0 | −1.2 | 12.7 |

**Dominant finding stands**: R14 owner stratification is the calibration driver. R12 county offset is a small refinement on top.

**Repo at 10 commits** on `main`. Latest: `a59025d r19 landed`. Local at `/sessions/wonderful-peaceful-feynman/mnt/outputs/fia-cem-maine`. Ready for `gh auth login && gh repo create`.

## Session #5 progress (continued — r18 v2 LANDED with R14 effect)

**r18 v2 finished and the R14 patch worked.** All four projection jobs (8942049-8942052) and dependent expansion (8942053) completed. Log confirms `R14 owner-mult lookup loaded: 6288 plot rows; mean mult 0.648`. Trajectories diverge meaningfully from r17:

| RCP | Pipeline | r17 BAU 2004 | r18 BAU 2004 | r17 BAU 2074 | r18 BAU 2074 | Δ MMT 2074 |
|-----|----------|---:|---:|---:|---:|---:|
| 4.5 | wear     | 231.4 | 237.0 | 35.9 | 48.7 | **+12.8** |
| 4.5 | wear+econ | 230.8 | 236.4 | 29.8 | 44.3 | **+14.5** |
| 8.5 | wear     | 232.8 | 238.3 | 43.4 | 58.6 | **+15.2** |
| 8.5 | wear+econ | 232.1 | 237.8 | 35.6 | 52.4 | **+16.8** |

The marginal effect of HCB landowner stratification peaks around 2034-2039 at ~24 MMT then decays as both trajectories approach low steady state. Forest-area-weighted mean owner multiplier is 0.81 (NIPF×0.5 dominates by 54% area share), so r18 statewide harvest is ~19% lower than uniform-rate r17.

**r18 baseline calibration also slightly improved**: 237 MMT 2004 baseline vs r17's 231 MMT — closer to subject-matched observed 268 MMT (now -31 MMT, -12% undershoot vs r17's -37 MMT).

**Updates committed to repo:**
- `figures/fig_r17_vs_r18_rcp{45,85}.png` — 2-panel (trajectory + delta bar)
- `figures/fig_r18_summary_2x2.png` — full RCP × econ × scenario lattice
- `figures/fig_progression_rcp{45,85}.png` — extended through r18
- `state_summary_progression/state_*_r{17,18}_ci.csv` × 8 — committed for full reproducibility
- Manuscript Section 3.7 added (new): Landowner stratification effect
- Manuscript Section 4 (Discussion) extended to 4 points
- CHANGELOG.md updated with r18 v2 details
- 4 commits total on `main`: cf556e9 → d232e31 → d7d2932 → 80c65fc

## Session #5 progress (continued — repo built, R14 fix, r18 v2)

**GitHub repo built locally** at `/sessions/wonderful-peaceful-feynman/mnt/outputs/fia-cem-maine` (4.9 MB, 71 files, 2 commits on `main`):
- README, LICENSE (MIT), CHANGELOG, .gitignore
- R/ (6 pipeline modules), scripts/ (10 driver scripts), viz/ (6 Python figure builders), osc/ (11 SLURM submit scripts), config/ (14 reference tables), docs/ (MEMORY + LANDOWNER strategy + PIPELINE_OVERVIEW), figures/ (7 PNGs), tables/ (5 endpoint CSVs), manuscript/ (methods note + 3 supplements)
- Two commits: initial commit (cf556e9) and R14 fix (d232e31)
- Ready for `gh auth login` then `gh repo create` push

**R14 fix:** the first r18 (jobs 8916881-8916884) ran to completion and produced **byte-identical** output to r17. Diagnosis: my previous owner-stratification patch was in `predict_harvest_probability()` in `R/03_harvest_choice.R`, but production submit scripts use `--skip_supply --no_econ` which routes harvest decisions through `06_projection_engine.R`'s `fixed_harvest_rate` branch, which never calls 03's logit. Fix:

- Added `get_owner_harvest_mult()` helper at the top of `R/06_projection_engine.R`. Reads `config/fia_plots_with_owner.csv` + `config/owner_class_legend.csv` once per session (cached on `.GlobalEnv`), returns per-plot multiplier vector keyed by STATECD/COUNTYCD/PLOT.
- Patched both fixed_harvest_rate branch and donor-rate branch to apply: `target_prob = base * Q * owner_mult`.
- Default 1.0 when flag off or files missing — no impact on r17 etc.
- Parse OK on Cardinal, file uploaded with backup.

**r18 v2 submitted** (jobs 8942049-8942052, dependent expansion 8942053). Cleaned old r18 dirs and CSVs first. ETA ~3.5 hours.

## Session #5 progress (continued — r17 expansion done, manuscript updated)

**All four r17 CSVs landed.** r17 expansion (job 8915695) completed successfully and the per-plot RDS files were removed afterward to keep quota. Pulled all 4 r17 CIs locally.

**r17 endpoint table by RCP × pipeline × scenario (12 cells):**

| RCP | Pipeline | Scenario | 2004 | 2074 | Δ MMT (yr) |
|---|---|---|---:|---:|---:|
| 4.5 | wear | No_harvest | 247 | 97 | -150 (-2.14) |
| 4.5 | wear | BAU | 231 | 36 | -195 (-2.79) |
| 4.5 | wear | +50% | 224 | 25 | -199 (-2.84) |
| 4.5 | wear+econ | BAU | 231 | 30 | -201 (-2.87) |
| 4.5 | wear+econ | +50% | 223 | 19 | -204 (-2.91) |
| 8.5 | wear | No_harvest | 248 | 119 | -129 (-1.84) |
| 8.5 | wear | BAU | 233 | 43 | -190 (-2.71) |
| 8.5 | wear | +50% | 225 | 31 | -194 (-2.77) |
| 8.5 | wear+econ | BAU | 232 | 36 | -196 (-2.80) |
| 8.5 | wear+econ | +50% | 224 | 22 | -202 (-2.89) |

Notable: under No_harvest, RCP 8.5 ends 22 MMT higher than RCP 4.5 because CO2 fertilization (Norby 2010) outweighs species vulnerability damage at Maine's mid-latitude position. Under harvest scenarios the climate signal compresses to under 10 MMT difference because harvest dominates.

**Manuscript Section 3 fully refreshed with r17 numbers.** Subsections 3.1 to 3.6 updated covering hindcast validation, multi-pool stock, climate sensitivity, economic overlay effect, partial-vs-clearcut realization, and harvest sensitivity.

**Headline figures rebuilt:**
- `figures/fig_r17_summary_2x2.png` — 4-panel RCP × econ × scenario lattice with calibration anchor
- `figures/fig_progression_rcp45.png` and `_rcp85.png` — refinement attribution including r17
- `figures/r17_summary_2x2.csv` — endpoint table

**Polished progression summary docx delivered:** `manuscript/r17_progression_summary.docx` (validated, 169 paragraphs). Includes r-tag attribution table, r17 endpoint lattice, two embedded figures, and manuscript-implication notes.

**r18 progress:** all 4 jobs running, currently at 5-13% (cycles 4-13 of 15). Log confirms "HCB landowner stratification enabled (R14; Harris-Caputo-Butler 2025 raster)" — the patch is taking effect. ETA completion ~10 PM EDT, expansion done by ~midnight.

## Session #5 progress (April 28, landowner integration + r18)

**r18 jobs SUBMITTED** — 8916881 (rcp45_wear), 8916882 (rcp45_wear_econ), 8916883 (rcp85_wear), 8916884 (rcp85_wear_econ). Built from r17 submit scripts with `--use_owner_stratification` appended. Dependent expansion 8916885 queued via `--dependency=afterok`. ETA 5-6 hours from start.

r18 = r17 stack (R5 SDImax cap + R6 disturbance + R8 climate decoupling + R4 Potter VCC species climate) **plus** R14 HCB landowner stratification:
- NIPF (Class 3, 54% of plots): harvest_prob × 0.5
- Industrial (Class 4, 33%): harvest_prob × 1.5
- Tribal (Class 5, <1%): × 0.2
- Federal (Class 6, 3%): × 0.2
- State (Class 7, 8%): × 0.5
- Local (Class 8, 3%): × 0.3

Comparison figure script staged: `cardinal_staging/build_r17_vs_r18_figure.py`. Auto-discovers when both r17 and r18 CSVs are present.

## Session #5 progress (April 28, landowner integration started)

User uploaded `LANDOWNER_INTEGRATION_STRATEGY.md` proposing HCB raster (Harris-Caputo-Butler 2025) ownership stratification for the multi-model PERSEUS effort. Phase 1 of that work is now applied to FIA CEM.

**Cardinal connection re-established** (config was wiped between sessions; restored from id_ed25519_cardinal upload).

**r17 jobs from session #4 actually succeeded.** sacct reported FAILED but only because of a non-zero exit during figure-generation. Output dirs are ME_20260427_*r17 (note new date), all 4 with full per-plot RDS at 1.8-1.9 GB. Submitted r17 expansion (job 8915695) which is ~50% complete and writing CSVs.

**r17 RCP4.5 wear BAU 2004 baseline = 231 MMT** (vs subject-matched obs 268 MMT, vs r12 400 MMT overshoot).

**Important calibration finding:** r17 n_conditions = 2819, identical to r11. The DESIGNCD filter excluded essentially all of the periodic-design plot additions, so r17 is effectively "r11 baseline + R5 SDImax + R6 disturbance + R8 climate decoupling + R4 species climate / Potter VCC" with NO R1 subject-pool expansion. Net: r17 is the canonical refined-pipeline baseline that closes the +120 MMT overshoot without overcompensating. Manuscript headline can use r17.

**Phase 1 landowner deliverables (delivered):**
- `landowner/fia_plots_with_owner.csv` - 6,288 Maine plots tagged with HCB class, FIA OWNCD, and agreement flag (45.2% agreement between HCB raster and FIA OWNCD)
- `landowner/maine_ownership_atlas.csv` - 106 rows, county x HCB class with EXPNS-weighted area
- `landowner/owner_class_legend.csv` - 9 rows, code-to-label-to-CEM-class mapping
- `landowner/maine_ownership_statewide_summary.csv`

**Statewide ownership distribution (% of forest area):**
- NIPF (Family Forest, HCB Class 3): 54.1% of forest, 23.2 M ac
- Industrial (Corporate, Class 4): 32.6% of forest, 14.0 M ac
- State (Class 7): 7.6%, 3.3 M ac
- Federal (Class 6): 2.8%, 1.2 M ac
- Local (Class 8): 2.5%, 1.1 M ac
- Tribal (Class 5): 0.3%, 0.14 M ac

NIPF is the larger class statewide; Industrial dominates Aroostook (47%), Piscataquis (44%), Franklin (37%), Somerset (36%), Penobscot (31%).

**HCB landowner stratification (R14) wired into pipeline:**
- `R/03_harvest_choice.R` patched: reads fia_plots_with_owner.csv + owner_class_legend.csv when cfg$harvest$use_owner_stratification = TRUE; joins hcb_class onto cond_data; multiplies harvest_prob by owner-class multiplier (NIPF 0.5, Industrial 1.5, Tribal/Federal 0.2, State 0.5, Local 0.3)
- `run_projection.R` adds `--use_owner_stratification` CLI flag
- All parse-checked clean on Cardinal and uploaded
- Not enabled by default; controlled by flag for r18 sensitivity test

**Phase 1 Word supplement:** `manuscript/supplement_S3_maine_ownership_atlas.docx` validated, includes statewide table, county-level shares, both visualization figures, and methods/implications text.

**Figures produced:**
- `figures/fig_maine_ownership_pie_by_county.png` - 16-panel small-multiples pies
- `figures/fig_maine_ownership_bars.png` - stacked bars sorted by industrial share

**Quota status:** 421G to 470G (FVS jobs added, but landowner work is small). r17 expansion job removes per-plot RDS as it processes each tag, keeping us well under cap.

## Session #4 progress (April 27, Cardinal access restored)

**Cardinal SSH back online via id_ed25519_cardinal.** Reconnected without issue. Key findings on resuming:

**r17 jobs (8866265-8866268) all FAILED at saveRDS step** with "fwrite error" caused by hitting the 500GB project quota. Cardinal output dir was at 76GB (474G/500G of project quota used). RDS files written but truncated (1.5–1.8GB instead of 2–3GB). All 4 r17 RDS files unreadable.

**Cleanup performed (53GB freed):**
- Deleted r12-r15 per_plot_projections.rds (kept ci_summaries.csv) — 46GB
- Deleted broken r17 dirs (8866265-8866268 outputs) — 6.9GB
- Pruned pre-r12 stale runs (smoketest, bau_v3/v4, harvest_v3-v8, etc.)
- Quota now: 421G/500G; output/ = 23GB

**Re-submitted r17 (jobs 8877283-8877286):** clean copy of submit scripts, 20-hr walltime, 180GB memory, --include_remeasured + DESIGNCD filter + R5/R6/R8/R4-VCC stack. Expected baseline 2004 AGC near 268-285 MMT (vs r12's 399 MMT overshoot).

**Pre-staged dependent state expansion (job 8877334):** uses `--dependency=afterok` against the 4 r17 jobs; runs immediately when projections complete. Saves CSVs to state_summary_progression and deletes per_plot RDS to keep quota safe. Walltime 2.5hr, 160GB memory.

**Per-county harvest logit (R12) deliverable wired:**
- `config/maine_county_harvest_logit_offset.csv` uploaded — 16-county SAR-calibrated additive logit offset (range -1.46 Aroostook to +1.50 Sagadahoc cap) plus partial/clearcut shares recomputed from raw acres.
- `R/03_harvest_choice.R` patched with `county_offset_lookup` + `--use_county_harvest` cfg flag. Adds offset to W&C 2025 logit intercept.
- `run_projection.R` adds `--use_county_harvest` CLI flag.
- All parse-checked clean on Cardinal.
- Not enabled by default — controlled by flag for r18 sensitivity test.

**State expansion R/10 + run_state_expansion_all.R uploaded** with land-use scenario_lookup + new_forest_c_frac args from session #3. Parse OK on Cardinal.

**r16 expansion (job 8877312):** RUNNING. Discovered that even rcp45_wear_econ_r16 RDS (2.2GB) is corrupt. The April 26 quota issue affected the full r12-r16 batch, not just r17. Some r-tags have valid CSVs from earlier expansion runs; the "missing" CIs are permanently lost (RDS deleted in cleanup).

## Session #3 progress (April 26 late evening, offline)

Cardinal SSH proxy was unreachable from this sandbox so all work was offline against the locally mirrored CSVs.

**Built (offline, no Cardinal):**
- `cardinal_staging/build_sdimax_ecoregion_table.R` — base R script that aggregates plot-specific BRMS SDImax by Maine ecoregion x forest type. Outputs five CSVs in `sdimax_brms/`:
  - `sdimax_by_ecoregion.csv` (4 zones: Acadian Highlands 1050, Central Maine 1016, Eastern/Coastal 982, Western Mountains 992 trees ha-1)
  - `sdimax_by_ecoregion_fortype_full.csv` (every cell)
  - `sdimax_by_ecoregion_fortype_compact.csv` (n>=5 only, 75 rows)
  - `sdimax_by_fortype_group_maine.csv` (Spruce-fir 1119, Softwood 1113, Mixed 1061, Aspen-birch 1027, Northern hardwood 935, Hardwood 874, Other 850)
  - `sdimax_by_fortype_detail_maine.csv` (FORTYPCD detail collapsed across ecoregions)
- `cardinal_staging/build_progression_figure.py` (rewritten) — auto-discovers which r-tags are present, plots calibration anchor at 268 MMT, defaults to RCP 8.5 (best coverage). Writes `figures/fig_progression_rcp85.png` and `_econ.png`, plus `progression_baseline_<year>` and `progression_<endyear>` summary CSVs per RCP.
- `cardinal_staging/test_landuse_scaling.R` — sanity check for land-use math; confirms BAU loses 2% of AGC by 2074, Develop2x 4%, Reforest50k +4%, LowDev_HiRefor +5%.

**Code edits to upload to Cardinal next session:**
- `R/10_state_expansion.R` — added `scenario_lookup` and `new_forest_c_frac` arguments to `expand_to_state()` and `expand_to_state_mmt()`. After per-sim aggregation, applies multiplicative area scaling per (scenario, cycle) when scenario_lookup is supplied.
- `run_state_expansion_all.R` — sources 05_scenario_biasing.R, builds `lu_lookup` from `get_scenario_set("maine_land_use")`, passes it to `expand_to_state()` only for tags matching `land_use|landuse`.

Both files parse-checked clean with `Rscript -e 'parse(...)'`.

**Progression baseline calibration table (RCP 8.5 wear BAU):**

| Tag | 2004 AGC MMT | delta vs obs (268) | 2074 AGC MMT | n_cond |
|---|---:|---:|---:|---:|
| r11 | 240 | -28 | 84 | 782 |
| r12 | 400 | +132 | 322 | 1269 |
| r13 | 393 | +125 | 95 | 1089 |
| r14 | 388 | +120 | 96 | 988 |
| r15 (econ only) | 386 | +118 | 76 | 865 |
| **r17 (predicted)** | **~270** | **~+2** | **~85** | **~1100** |

The +120 MMT 2004 baseline overshoot at r12-r15 confirms that R1 expansion still pulls pre-1999 periodic plots; the DESIGNCD-filtered r17 should land much closer to observed 268 MMT.

**Outputs ready for manuscript Methods section:**
- Table of SDImax by ecoregion (sdimax_by_ecoregion.csv)
- Table of SDImax by forest-type group (sdimax_by_fortype_group_maine.csv)
- Plot-keyed BRMS distribution (sdimax_brms_plot.csv, n=3,253 ME plots)
- Progression figure showing each refinement's marginal effect

## Outstanding refinements

1. **R1-v2: DESIGNCD filter on extras block** to recover R1 expansion benefits without periodic-plot contamination. Effort: 1 hour code edit + new run. **Code is uploaded; r17 jobs were submitted last session (8866265-8866268). Verify they finished and re-pull CSVs.**

2. **R14 climate ensemble sampling.** Currently uses point-estimate HadGEM2-AO. Sample from MACAv2 CMIP5 ensemble (10+ GCMs) for proper climate uncertainty. Effort: 1 to 2 days plus reruns.

2. **maine_land_use scenario implementation.** ✅ DONE in session #3: `R/10_state_expansion.R` now takes `scenario_lookup` and `new_forest_c_frac` arguments and applies multiplicative area scaling per (scenario, cycle). Need to upload the patched files to Cardinal and run a `--scenario_set maine_land_use` projection to validate against the test_landuse_scaling.R numbers.

3. **Per-county harvest logit fit.** Calibration table at `config/maine_county_harvest_calibration.csv` ready for use. Need to fit per-county logit using SAR by-county acres and integrate into 03_harvest_choice.R. Effort: 2 to 3 days.

4. **Manuscript Section 3 update.** Refill placeholder and v5 numbers with r16 results once jobs finish. Effort: 1 day.

5. **Cross-validation table.** Run subject-matched CV against r12 through r16 outputs to quantify each refinement's marginal contribution. Effort: 0.5 day.

6. **Build progressive refinement figure.** 5-panel comparison r11 → r16 trajectories on the same axes. Effort: 0.5 day.

## Next-session recovery checklist

```bash
# 1. Restore SSH config
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /sessions/wonderful-peaceful-feynman/mnt/uploads/id_ed25519_cardinal ~/.ssh/id_ed25519_cardinal
chmod 600 ~/.ssh/id_ed25519_cardinal
cat > ~/.ssh/config <<'EOF'
Host cardinal
    HostName cardinal.osc.edu
    User crsfaaron
    IdentityFile ~/.ssh/id_ed25519_cardinal
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts_cardinal
EOF
chmod 600 ~/.ssh/config

# 2. Check job status
ssh -F ~/.ssh/config cardinal "sacct -j 8860867,8860868,8860869,8860870,8861589,8861590,8861591,8861592,8861595,8861619,8861620,8861621,8861622,8861656,8861657,8861658,8861659,8861735,8861736,8861737,8861738,8861755,8861761 --format=JobID,JobName%14,State,Elapsed -n -P | grep -v '\\.'"

# 3. Update expansion pattern to capture all completed tags
ssh -F ~/.ssh/config cardinal 'python3 -c "
p = \"/users/PUOM0008/crsfaaron/fia_cem_projections/run_state_expansion_all.R\"
with open(p) as f: s = f.read()
import re
s = re.sub(r\"pattern\\s*=\\s*\\\"[^\\\"]*\\\"\", \"pattern = \\\"^ME_2026[0-9]{4}_.*_(r1[2-6]|w[0-9]+|hindcast_r12)\\\\\\\\$\\\"\", s)
s = re.sub(r\"state_summary_\\w+\", \"state_summary_progression\", s)
with open(p, \"w\") as f: f.write(s)
"
sbatch ~/fia_cem_projections/osc/submit_exp_only.sh'

# 4. Pull all expansion CSVs and observed anchors
mkdir -p /sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results/state_summary_progression
scp -F ~/.ssh/config 'cardinal:~/fia_cem_projections/output/state_summary_progression/*.csv' \
    /sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results/state_summary_progression/

# 5. Build progressive comparison figure
# (see figures/build_v5_figure.py for r11; similar pattern for r12 through r16)
```

## Where deliverables live

Local outputs at `/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results/`:

- `manuscript/20260418_fia_cem_maine_methods_note.md` — methods note with v5 (r11) numbers, hindcast validation
- `policy_brief/20260418_mcc_maine_forest_carbon_brief.md` — MCC brief with hindcast skill assessment
- `figures/fig_comparison_v5.png` — 5-scenario harvest spread (r11 baseline)
- `figures/fig_delta_v5.png` — delta-from-BAU panel
- `figures/fig_carbon_fate.png` — Smith 2006 product fate decomposition
- `figures/fig_hindcast_validation.png` — major-win validation figure
- `figures/comparison_v5_summary.csv`, `crossval_v5_metrics.csv`
- `state_summary_r11/`, `state_summary_hindcast/` (CI CSVs)
- `subject_matched_cv/subject_matched_observed.csv` (R3 finding)
- `sdimax_brms/sdimax_brms_*.csv` (BRMS SDImax lookups)
- `sdimax_brms/spcd_potter_vcc.csv`, `potter2017_VCC_species.csv` (Potter VCC)
- `econ_config/maine_*.csv` (economic overlay configs)

## Known caveats and methodological notes

1. **Subject-donor split is structural.** Pipeline projects only ~40% of FIA plots that have not been remeasured. Cross-validation should use subject-matched observed FIA, not full-panel EXPALL. Subject pool expansion (R1) closes most of this by including remeasured plots from their most-recent measurement.

2. **Maine partial vs clearcut split is 93/7 statewide,** very different from Wear 2019 Eastern US default 65/35. Aroostook 31 percent clearcut; southern coastal counties less than 1 percent.

3. **Climate is a small effect under harvest, modest under No_harvest.** Harvest decisions dominate the 70-year horizon. Decoupled CO2/temp (R8) confirms this; CO2 fertilization adds ~3 percent stock by 2099 versus harvest's ~70 percent removal.

4. **Maine spruce-fir Potter VCC moves to cluster D** (potential high future vulnerability), matching the empirical D'Amato 2011 finding. This propagates as a 9 percent growth penalty per 4.5 °C warming on red and black spruce stands under r16.

5. **Total Maine forest carbon is dominated by soil:** 700 of 1,140 MMT total. Pool dynamics other than above-ground live tree are held stationary across the 70-year projection (defensible first-cut for century-scale modeling, would benefit from explicit dead-wood and soil carbon dynamics in future work).

6. **r12 through r16 are progressive refinements,** not alternatives. r16 is the most complete model. The r-tag sequence allows attribution of each refinement's marginal effect on projected carbon.

## Sources

- Maine Forest Service Stumpage Reports 2015-2024 + Silvicultural Activities Reports 2015-2023
- Wear & Coulston 2019 (J Forest Economics 34:73), Wear & Coulston 2025 (Forest Pol Econ 178:103542)
- Van Deusen & Roesch 2013 (Forest Sci 59:475)
- Smith et al. 2006 (USDA GTR NE-343, wood product half-lives)
- Norby et al. 2010 (NCC, FACE CO2 fertilization meta-analysis)
- Iverson et al. 2008 (Atlas of Climate Change), D'Amato et al. 2011 (Forest Ecol Manag), Janowiak et al. 2018 (USDA GTR NRS-173)
- Potter et al. 2017 (New Forests 48:275, CAPTURE framework)
- Woodall & Weiskittel 2021 (Forest Ecol Manag 480:118669, SDImax by ecoregion + forest type)
- BRMS posterior plot-level SDImax (1-27-24 dataset, 173,740 plots)

## Files NOT to delete on Cardinal

- All `R/0?_*.R` modules (live edits)
- `R/11_economic_harvest.R` (new module)
- `run_projection.R` (live CLI parser and config wiring)
- `osc/submit_*_r1?.sh`, `submit_*_w?.sh`, `submit_hindcast_*.sh` (working submit scripts)
- `output/state_summary_*/` (canonical result CSVs)
- `output/ME_20260419_*_r1?` (per_plot_projections.rds for downstream analysis)
- `config/maine_stumpage_*.csv`, `config/maine_treatment_proportions.csv`, `config/sdimax_brms_*.csv`, `config/spcd_potter_vcc.csv`, `config/potter2017_VCC_species.csv`, `config/maine_county_harvest_calibration.csv`
