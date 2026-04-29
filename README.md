# fia-cem-maine

Reproducible R pipeline projecting Maine forest carbon stocks from a 1999 baseline through 2074 (15 cycles) under climate (HadGEM2-AO RCP 4.5/8.5) and harvest scenarios. Built on Van Deusen and Roesch (2013) coarsened exact matching with progressive refinement layers (Wear and Coulston 2019/2025 stratification, BRMS Reineke SDImax cap, Norby 2010 CO2 fertilization, episodic disturbance, Potter 2017 species climate vulnerability, Harris–Caputo–Butler 2025 landowner stratification).

**Author:** Aaron Weiskittel, CRSF, University of Maine
**Compute:** OSC Cardinal HPC (account PUOM0008)
**Pipeline location on Cardinal:** `~/fia_cem_projections/`
**Latest tag:** r17 (canonical refined-pipeline baseline). r18 (with HCB landowner stratification) is in flight.

## Repository layout

```
R/                  Pipeline modules sourced by run_projection.R
  01_data_prep.R          Subject pool selection, anchor window, DESIGNCD filter
  03_harvest_choice.R     Wear & Coulston 2025 logit + R12 county offset + R14 owner stratification
  05_scenario_biasing.R   Van Deusen & Roesch 2013 stochastic biasing
  06_projection_engine.R  CEM projection, multi-pool C, climate decoupling, SDImax, disturbance, species climate
  10_state_expansion.R    Plot-to-state aggregation, EXPNS, multi-pool join, land-use scaling
  11_economic_harvest.R   Maine county stumpage overlay, partial vs clearcut split

scripts/            Driver scripts and one-off builders
  run_projection.R                Main entry point (CLI flags catalog)
  run_state_expansion_all.R       Batch state expansion across r-tags
  build_brms_sdimax_lookup.R      Plot-keyed SDImax from BRMS posterior
  build_county_harvest_lookup.R   Maine SAR-calibrated county logit offset
  build_landowner_atlas.R         HCB raster zonal extraction for FIA plots
  build_sdimax_ecoregion_table.R  SDImax aggregation by ecoregion x forest type
  build_subject_matched_cv.R      Subject-matched observed FIA hindcast
  test_landuse_scaling.R          Sanity test for land-use area scaling math

viz/                Python figure builders
  build_progression_figure.py        r-tag progression with calibration anchor
  build_r17_summary_figure.py        2x2 RCP x econ x scenario summary
  build_r17_vs_r18_figure.py         Marginal effect of HCB owner stratification
  build_sdimax_figure.py             Plot-level SDImax distribution
  build_landowner_figures.py         Maine ownership pies and stacked bars

osc/                SLURM submit scripts (Cardinal)
  submit_rcp{45,85}_wear[_econ]_r{17,18}.sh   Production projection jobs
  expand_r{17,18}.sh                          Dependent state-expansion jobs
  landowner_atlas.sh                          HCB raster zonal stats job

config/             Reference tables and lookups (committed)
  potter2017_VCC_species.csv      Potter 2017 vulnerability scores (304 species)
  spcd_potter_vcc.csv             25 Maine SPCD with vulnerability + beta per °C
  sdimax_brms_*.csv               BRMS posterior SDImax (plot, county+fortyp, fortyp)
  sdimax_by_*.csv                 Aggregations by Maine ecoregion x forest type
  maine_county_harvest_*.csv      SAR-calibrated county harvest behavior
  fia_plots_with_owner.csv        6,288 Maine FIA plots tagged with HCB class
  maine_ownership_atlas.csv       Area by county x HCB class
  owner_class_legend.csv          HCB code-to-label-to-CEM-class crosswalk

figures/            Headline result PNGs
tables/             Endpoint summary CSVs
manuscript/         Methods note draft + supplements (S2 SDImax, S3 ownership, r17 summary)
docs/               MEMORY.md (running log) and LANDOWNER_INTEGRATION_STRATEGY.md
```

## CLI flag catalog (`scripts/run_projection.R`)

```
--state ME                            target state (donor states auto-loaded)
--n_sims 100                          bootstrap replicates per scenario
--cycles 15                           projection cycles (5 yr each)
--cores ${SLURM_CPUS_PER_TASK}        parallelism
--scenario_set harvest                multi-scenario set (5 harvest levels)
--tag rcp45_hadgem2_wear_r17          output dir tag
--baseline_year 1999                  start year
--baseline_window 10                  window width (1999 to 2008)
--include_remeasured                  R1 subject pool expansion
--untreated_donors                    clean donor pool (no harvest events in T1)
--fixed_harvest_rate 0.10             base harvest rate per cycle
--climate_rcp 4.5                     HadGEM2-AO scenario
--bootstrap_plots --bootstrap_frac 0.9
--use_maine_econ                      Maine county stumpage overlay
--use_brms_sdimax                     R5 BRMS Reineke SDImax cap
--use_decoupled_climate               R8 separate CO2/temp multipliers
--co2_effect_mult 0.10                CO2 fertilization (per doubling, Norby 2010)
--use_disturbance                     R6 SBW + wind + fire stochastic events
--insect_amp_mult 1.0                 disturbance amplitude tunables
--use_species_climate                 R4 FORTYPCD-coarse species climate response
--use_potter_vcc                      R4-VCC Potter 2017 SPCD vulnerability
--use_county_harvest                  R12 SAR-calibrated county logit offset
--use_owner_stratification            R14 HCB landowner stratification multipliers
--save_per_plot                       save per-plot RDS for downstream expansion
--skip_supply --no_econ               skip Wear 2025 logit (use fixed-rate branch)
```

## Refinement progression (r-tag history)

| Tag | Refinement | New flag | 2004 AGC (MMT, RCP 4.5 wear BAU) | 2074 AGC |
|---|---|---|---:|---:|
| r6 | Wear 2019 age saturation, multi-pool C | (baseline) | — | — |
| r11 | scenario_Q via fixed_harvest_rate × Q | `--fixed_harvest_rate 0.10` | 240 | 81 |
| r12 | + R1 subject pool expansion (incl. periodic) | `+ --include_remeasured` | 400 | 257 |
| r13 | + R5 BRMS Reineke SDImax cap | `+ --use_brms_sdimax` | 393 | 95 |
| r14 | + R8 decoupled CO2 + R6 disturbance | `+ --use_decoupled_climate, --use_disturbance` | 388 | 96 |
| r15 | + R4 FORTYPCD species climate | `+ --use_species_climate` | 386 | 76 |
| r16 | + R4-VCC Potter species climate | `+ --use_potter_vcc` | (corrupt RDS) | (corrupt RDS) |
| **r17** | **R1-v2 DESIGNCD-filtered (annualized only) + r16 stack** | (no R1 expansion) | **231** | **36** |
| r18 | + R14 HCB landowner stratification | `+ --use_owner_stratification` | (running) | (running) |

Subject-matched observed 2004 AGC: 268 MMT (subject pool of 2,819 conditions).

r17 is the canonical refined-pipeline baseline. The DESIGNCD filter on the subject-pool expansion excluded essentially all of the periodic-design plot adds, so r17 is effectively r11 + R5/R6/R8/R4 stack with no R1 expansion. The 14% undershoot at 2004 (231 vs 268 MMT) is consistent with the −28 MMT 2004 hindcast residual against subject-matched observed FIA.

## Validation

A 1999–2024 BAU hindcast against subject-matched observed FIA EXPALL panels (5 years, 5 evaluations):
- **RMSE 16 MMT** AGC (about 6% of mean stock)
- **Bias −2 MMT** (−1.1% of observed mean)
- Range −28 MMT (2004) to +16 MMT (2019)

This subject-matched comparison is the canonical validation; full-panel EXPALL comparison shows a structural −96 MMT gap that is the projection-vs-inventory definitional mismatch, not model error.

## Cross-model context

This pipeline is one of four models in the multi-institution PERSEUS effort (FIA CEM ⊃ this repo, plus FVS-NE/Acadian, GCBM/libcbm, LANDIS-II). The HCB landowner integration (`docs/LANDOWNER_INTEGRATION_STRATEGY.md`) is the cross-cutting refinement designed to unify owner-class harvest behavior across all four. Phase 1 (atlas) is complete in this repo; Phases 2–4 (model-specific yield curves and disturbance schedules) are pending.

## Reproduction

```bash
# Clone
git clone <this repo>
cd fia-cem-maine

# Required FIA inputs (not committed; download separately):
#   ~/fia_data/ME_PLOT.csv, ~/fia_data/ME_COND.csv, ~/fia_data/ME_TREE.csv
#   plus equivalents for donor states (NH, VT, MA, CT, RI, NY)

# R packages: tidyverse, data.table, here, terra, sf, brms (only for SDImax fit)
# Python packages: pandas, matplotlib, numpy

# Single projection (login node test, small):
Rscript scripts/run_projection.R \
  --state ME --n_sims 10 --cycles 3 --cores 4 \
  --scenario_set bau --tag smoketest \
  --use_brms_sdimax --use_decoupled_climate --use_disturbance --use_potter_vcc \
  --include_remeasured --skip_supply --no_econ

# Production projection on Cardinal: see osc/submit_*.sh

# Build figures from any state_summary CSVs:
python3 viz/build_progression_figure.py --rcp 45
python3 viz/build_r17_summary_figure.py
```

## Citation

If this work is used or extended, please cite the in-prep methods note:

> Weiskittel, A. R. (in prep). A state-scale application of FIA coarsened exact matching for Maine forest carbon projections under climate and economic scenarios. Working draft at `manuscript/20260418_fia_cem_maine_methods_note.md`.

## Sources and dependencies

- **Methods**: Van Deusen and Roesch (2013) Forest Sci 59:475 (CEM); Wear and Coulston (2019) JFE 34:73 and (2025) FPE 178:103542 (harvest logit); Smith et al. (2006) USDA GTR NE-343 (wood product half-lives); Norby et al. (2010) NCC (FACE CO2 meta-analysis); Iverson et al. (2008), D'Amato et al. (2011), Janowiak et al. (2018) (climate vulnerability); Potter et al. (2017) New Forests 48:275 (CAPTURE framework); Reineke (1933) (self-thinning); Woodall and Weiskittel (2021) FEM 480:118669 (SDImax by ecoregion x forest type); Harris, Caputo, and Butler (2025) USDA FS RDS-2025-0045 (forest ownership raster).
- **Data**: USDA FIA database, Maine Forest Service Stumpage Reports (2015–2024), Silvicultural Activities Reports (2015–2023), Harris–Caputo–Butler 2025 NewEngland_LandOwners.tif (8.4 GB raster), BRMS posterior plot-level SDImax (Weiskittel et al., 1-27-24 dataset, 173,740 plots).

## License

MIT — see `LICENSE`.
