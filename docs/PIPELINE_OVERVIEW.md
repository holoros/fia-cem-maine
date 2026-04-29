# Pipeline overview

A high-level walkthrough of the FIA CEM Maine projection pipeline. For granular history see `MEMORY.md`, for the methods narrative see `manuscript/20260418_fia_cem_maine_methods_note.md`.

## Conceptual flow

```
FIA database (PLOT, COND, TREE)
        │
        ▼
[01_data_prep.R]
  Anchor window 1999±5 yr; subject pool = plots with valid baseline
  + DESIGNCD filter to annualized designs only (R1-v2)
        │
        ▼
[02_cem_matching.R] (not modified in current cycle)
  Coarsened exact matching: subjects → donors with shared FORTYPCD,
  OWNGRPCD, SLICE, SITECLCD bins
        │
        ▼
[05_scenario_biasing.R]
  Van Deusen & Roesch 2013 stochastic biasing
  Scenarios: BAU, No_harvest, Q0p5, +25%, +50% biomass
        │
        ▼
[03_harvest_choice.R]
  Wear & Coulston 2025 logit harvest probability
  + R12 county logit offset (--use_county_harvest)
  + R14 HCB landowner harvest multiplier (--use_owner_stratification)
        │
        ▼
[06_projection_engine.R]
  Per-cycle CEM resampling × harvest choice × growth dynamics
  + R5 BRMS Reineke SDImax cap (--use_brms_sdimax)
  + R8 decoupled CO2/temp climate (--use_decoupled_climate)
  + R6 episodic disturbance (--use_disturbance)
  + R4 species climate (--use_species_climate, --use_potter_vcc)
        │
        ▼
[10_state_expansion.R]
  Plot-to-state aggregation via FIA EXPNS
  Multi-pool C: above-ground live, below-ground live (Jenkins ratio),
                standing/down dead, litter, soil, understory
  + R9/R10 land-use scenario area scaling (scenario_lookup)
        │
        ▼
[11_economic_harvest.R]
  Maine county stumpage overlay, partial vs clearcut split
        │
        ▼
state_summary CSVs: per-cycle, per-scenario, per-sim
```

## Key concepts

**Subject vs donor pools.** The pipeline projects the ~40% of FIA plots that have NOT been remeasured (subjects), using the rest (donors) as a Markov-chain-sampled pool of "possible futures" via CEM matching. Validation uses the subject-matched observed inventory, not the full-panel EXPALL.

**Multi-pool carbon.** 7 pools: above-ground live tree (projected), below-ground live (Jenkins ratio of AGL), standing/down dead (FIA COND), litter (FIA COND), soil organic (FIA COND), understory above- and below-ground (FIA COND). Live pools evolve under projection; dead/litter/soil are held stationary across the 70-yr horizon (defensible first-cut).

**Climate decoupling (R8).** CO2 fertilization (Norby 2010, ~10% productivity per doubling) is applied separately from temperature damage (D'Amato 2011, Iverson 2008). Under RCP 8.5 in Maine, CO2 outweighs temperature damage (Maine is mid-latitude; spruce-fir vulnerable but not yet at thermal limit).

**Disturbance module (R6).** Bernoulli SBW + wind + fire events per cycle, tunable amplitude. Affects mortality and regen rates per plot.

**SDImax cap (R5).** Reineke self-thinning ceiling using BRMS posterior-mean plot-level SDImax. Stand growth throttles multiplicatively as relative density (SDI/SDImax) approaches 0.6–1.0.

**Species climate (R4 / R4-VCC).** Per-SPCD growth penalty under warming. R4 uses FORTYPCD-coarse coefficients; R4-VCC uses Potter 2017 CAPTURE framework (304 species, vulnerability score and β per °C). Maine spruce-fir cluster D (high vulnerability).

**Landowner stratification (R14, new in r18).** Harris–Caputo–Butler 2025 raster splits private OWNGRPCD=40 into NIPF (Class 3, 54% of Maine forest) and Industrial (Class 4, 33%). Per-class harvest probability multipliers applied to the W&C 2025 logit:
- NIPF × 0.5 (light selection on long return intervals)
- Industrial × 1.5 (aggressive partial cutting)
- Tribal/Federal × 0.2 (no harvest baseline)
- State × 0.5 (light improvement thinning)
- Local × 0.3

## r-tag attribution

See `CHANGELOG.md` for the full version history.

## Outputs

Each projection run writes to `output/ME_YYYYMMDD_<tag>/`:
- `per_plot_projections.rds` (1.5–3 GB, deleted after expansion)
- `ci_summaries.csv`, `raw_mc_summaries.csv`
- Diagnostic figures (BA trajectory, carbon trajectory, harvest-planting, etc.)

State expansion (`scripts/run_state_expansion_all.R`) aggregates to:
- `state_summary_progression/state_<tag>_ci.csv` — 95% CI per scenario × cycle
- `state_summary_progression/state_<tag>_sim_totals.csv` — full sim ensemble

## Validation anchor

Subject-matched observed FIA at 2004: **268 MMT AGC** (n=2,819 conditions, EXPNS-weighted area 5.47 M ha).

r17 baseline: 231 MMT (-37 MMT, -14% undershoot). Consistent with r11 hindcast residual of -28 MMT at 2004. RMSE 16 MMT across 5 panels (2004–2024); bias -2 MMT (-1.1% of mean).
