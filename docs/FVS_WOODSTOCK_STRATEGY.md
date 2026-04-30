# FVS + Woodstock Yield-Curve Modeling Strategy for Maine Forest Carbon

**Author:** A. Weiskittel
**Date:** 30 April 2026
**Status:** Strategic design — companion to LANDOWNER_INTEGRATION_STRATEGY.md and CLIMATE_ENSEMBLE_DESIGN.md.

## Motivation and positioning

The FIA CEM pipeline (this repo) projects forward by sampling donor plots from the existing FIA pool with stochastic biasing. It is observation-grounded, but the projected dynamics inherit the full distribution of FIA growth-and-mortality realizations rather than imposing process structure. CEM is therefore strong on calibration (RMSE 14.5 MMT after the R14 owner refinement) and weak on counterfactual treatment trajectories (it cannot easily project a stand under a treatment that no donor plots have actually received).

An alternative, complementary modeling approach addresses that gap. It has three pieces:

1. **FVS-NE / FVS-ACD** as the source-of-truth growth-and-yield generator, run on the FIA plot network at the cell level (forest type × ecoregion × owner class) with controlled treatment regimes.
2. **A yield-curve archive** in long format, fitted from FVS output per cell and per treatment, with uncertainty bands.
3. **A Woodstock-class linear/integer programming optimizer** that consumes the yield curves plus user-defined constraints (sustained yield, maximum allowable cut, carbon target, minimum mature-stand acreage) and returns a statewide harvest schedule that meets the constraints while optimizing a chosen objective (max carbon stock, max harvest revenue, max even-flow, etc.).

This is a process-driven, scenario-rich complement to the data-driven CEM. Together they bracket the modeling spectrum: CEM gives the best estimate of "what will happen under business-as-usual" and Woodstock gives the best answer to "what could happen under specified objectives and constraints."

## Stage 1: FVS factorial run on FIA plots

### Stratification

Use the lattice already built in `config/maine_yield_curve_strata.csv`:

- **Forest type (6 buckets):** Spruce-fir, Northern hardwood, Aspen-birch, Mixedwood, White/Red pine, Oak/Pine/Hemlock, Other.
- **Ecoregion (3 zones):** ME_NH (Northern Highlands), ME_NCZ (Northern Central Zone), ME_APH (Acadian Plains/Hills). Aligned with the libcbm Maine AIDB.
- **Owner (6 HCB classes, collapsed to 4 for sample size):** NIPF, Industrial, Public (collapsed Tribal + Federal + State + Local).

Net cell count: 6 × 3 × 4 = 72 cells. About 32 cells have n ≥ 30 FIA plots after the public-class collapse. The 40 remaining cells have n < 30 and will need a fallback (use the next-coarser ecoregion or fortype, or pool all owners within ecoregion × fortype).

### FVS variant choice

- **FVS-NE** (Northeastern variant): use for Maine plots in the Aspen-birch, Northern hardwood, Mixedwood, White/Red pine, and Oak/Pine/Hemlock forest-type buckets.
- **FVS-ACD** (Acadian variant): use for Spruce-fir cells, especially in ME_NH and ME_NCZ ecoregions where ACD has been calibrated for spruce-fir mortality and self-thinning.

The variant choice will be made per cell based on dominant forest type. Where both variants are appropriate, run both and compare.

### Treatment trajectories per cell

Four treatment regimes per cell, all run for 100 years (20 five-year cycles) with posterior draws (BAIMULT) for uncertainty bands:

1. **No-treatment** (`notreat`) — passive succession baseline. Captures the upper bound of carbon accumulation under no harvest.
2. **Light partial cut** (`light_partial`) — single-tree selection or improvement thinning, ~15–20% basal area removal, 30-year return interval. Mimics NIPF and State management practice.
3. **Heavy partial cut** (`heavy_partial`) — shelterwood or group selection, ~50% basal area removal, 40–50 year return interval. Mimics Industrial practice in Acadian spruce-fir.
4. **Clearcut + regeneration** (`clearcut_regen`) — clearcut at year 0, planted spruce or natural regen, 40–50 year rotation, repeated. Mimics intensive industrial management in Aroostook and Piscataquis.

Total run count: 72 cells × 4 treatments = 288 FVS runs, each with ~100 plot members and ~100 BAIMULT posterior draws. Estimated Cardinal compute: 4–6 hours per cell × 288 cells = 1,200–1,800 core-hours, parallelizable on 48-core nodes → ~1 wall-day on Cardinal with proper array-job sizing.

### Outputs per FVS run

Per cycle, per cell, per treatment, per posterior draw:
- AGB (tons/acre)
- Merchantable volume (cu ft/acre)
- Sawtimber and pulpwood split (MBF/acre, cords/acre)
- Standing dead biomass
- Live tree carbon (lb/acre)
- Mortality (volume/yr)
- Regen ingrowth (TPA × DBH bin)
- Stand structure summary (BA, QMD, SDI, RD)

## Stage 2: Yield-curve archive

### Functional form

Fit a Chapman-Richards form per (cell, treatment) combination to produce a smooth yield curve that consumers can interpolate at arbitrary age:

`y(age) = a × (1 − exp(−b × age))^c`

with parameters `a` (asymptote), `b` (rate of approach), and `c` (shape). Fit by nonlinear least squares with bootstrap-derived CIs. For treated trajectories where rotation imposes discontinuities, fit a piecewise smooth (one Chapman-Richards segment per rotation cycle) and concatenate.

For mortality and regen flows, use a flexible local-regression approach (loess) since these tend not to follow a simple monotone form.

### Archive format

Two outputs per response variable:

1. **Long format CSV** — `maine_yield_curves_v1.csv` with columns: `forest_type, ecoregion, owner_class, treatment, age_yr, response, mean, p05, p50, p95`. Suitable for direct consumption by R / Python / Stata.

2. **Parquet** — same data in a columnar binary for fast ingestion by GCBM, LANDIS, and Woodstock (all of which can read Parquet directly).

Response variables: `agb_tonac, merch_volac, c_lbac, mortality_voly, regen_tpa`. Each gets its own long-format file.

### Quality assurance

- Sum across all cells (weighted by Maine area share) and compare to the published Maine state harvest reports (DACF) and the Hagan biomass benchmark.
- Compare the no-treatment trajectory to the FIA observed donor-plot trajectories from the CEM pipeline (subject-matched across the same age range).
- Stress-test the Chapman-Richards fit on the well-sampled cells (n ≥ 100) to verify the asymptote a is biologically reasonable.

### Adapter scripts

Build thin per-model adapters:

- `adapt_to_gcbm.R` — emits `growth_curves.csv` keyed by classifier set for libcbm / GCBM.
- `adapt_to_landis.R` — emits PnET-Succession `BiomassParameters` and `EstablishProbabilities` text files.
- `adapt_to_cem.R` — emits a per-treatment-cell scaling factor that the CEM pipeline can apply as a productivity multiplier.
- `adapt_to_woodstock.R` — emits a Woodstock-format YIELDS table (see Stage 3 below).

## Stage 3: Woodstock optimization

### Background

Woodstock is a forest estate planning tool that solves linear (or mixed-integer) programming problems. Inputs: yield tables per stratum × treatment, allowable management actions, areas, and constraints; output: an optimal harvest schedule maximizing or minimizing a user-chosen objective subject to those constraints. It is the de-facto industry standard for sustainable harvest planning in Canada and the US. Its open-source equivalents include `forestplanR`, `pyforestplan`, and the SImplex-based `formats` package.

### Schedule structure

For Maine, define:

- **Strata** — the 72 cells (forest type × ecoregion × owner) used in Stage 1, plus a `BPL` (Bureau of Parks and Lands) overlay for State land that has explicit no-harvest set-asides.
- **Actions** — the 4 treatments from Stage 1 (notreat, light_partial, heavy_partial, clearcut_regen) plus a `convert` action for forest-to-development land use change.
- **Yield tables** — the Stage 2 yield curves, one set per (stratum, action, response variable).
- **Periods** — 5-year time steps from 2024 to 2074 (10 periods) or to 2099 (15 periods).
- **Objective** — user choice from:
  - Maximize total live tree carbon at the terminal period
  - Maximize cumulative harvest revenue (using the Maine stumpage price forecast already in `config/maine_stumpage_forecast.csv`)
  - Maximize sustained yield (minimize variance in periodic harvest volume)
  - Hybrid: maximize carbon subject to a minimum periodic harvest constraint (the "sustainability" objective most relevant to Maine state policy)

### Constraints

Translate Maine policy and biophysical realities into constraint sets:

1. **Sustained yield (even-flow)** — periodic harvest volume in any period within ±15% of the mean.
2. **Statewide maximum allowable cut (AAC)** — total area harvested per year ≤ historical 2015–2023 SAR mean × 1.5 (the +50% biomass scenario already in CEM).
3. **Owner-class behavioral floor and ceiling** — Industrial cell harvest per period at least 1.0× and at most 2.0× historical rate; NIPF cell harvest at most 0.7× historical (recognizing the social barrier to high-intensity NIPF management).
4. **Conservation easement overlay** — no harvest on the ~3M acres under permanent or term conservation easement (Forest Society of Maine, AMC, TNC inventories).
5. **Spruce-fir species composition floor** — total spruce-fir area at terminal period ≥ X% of current (preserves wildlife habitat under climate stress).
6. **Carbon stock constraint (optional)** — total terminal AGC ≥ Y MMT, used in tandem with the harvest revenue objective to compute the marginal cost of carbon retention.

### Outputs

For each (objective, constraint set) pair Woodstock returns:

- A schedule: per period, per stratum, what action to apply on how much area.
- Implied periodic flows: harvest volume, harvest carbon, growing-stock carbon, total area by stand age.
- The dual variable (shadow price) on each constraint, which tells us the marginal economic value of relaxing that constraint by one unit. The shadow price on the carbon constraint, for example, is the marginal cost of carbon retention in dollars per MT C.

### Comparison with CEM

Run the same constraint set through CEM (using the existing scenario_set framework) and compare:

- The CEM projection asks "what do FIA donor pools predict for this scenario?" — observation-grounded, no policy lever.
- The Woodstock projection asks "what is the optimal schedule that meets these constraints?" — process-driven, fully policy-responsive.

The two should agree on stable (BAU-like) regimes and diverge on extreme regimes (no-harvest, +50% biomass) where Woodstock's optimization will find solutions that CEM's stochastic biasing approximates only loosely.

## Phasing and timeline

| Phase | Work | Owner | Effort | Output |
|---|---|---|---|---|
| 1 | Yield-curve stratification (already done) | this repo | Done | `config/maine_yield_curve_strata.csv` |
| 1.5 | Public-class collapse + sparse-cell handling | Aaron | 0.5 day | Updated strata table |
| 2 | FVS-NE / FVS-ACD factorial on Cardinal | Aaron + grad student | 3–5 days | 288 FVS runs |
| 3 | Yield-curve fitting (Chapman-Richards + bootstrap) | Aaron | 2 days | `maine_yield_curves_v1.csv` and `.parquet` |
| 4 | Adapter scripts (GCBM, LANDIS, CEM, Woodstock) | Aaron | 2 days | 4 adapter R / Python scripts |
| 5 | Woodstock model build (strata + actions + yields + constraints) | Aaron + Adam | 5 days | Woodstock model file |
| 6 | First objective × constraint runs (5 scenarios) | Aaron | 1 day | Schedule + duals per scenario |
| 7 | Comparison with CEM r18/r19 results | Aaron | 2 days | Cross-model methods note |
| 8 | Manuscript draft (Maine FVS+Woodstock methods paper) | Aaron + co-authors | 10 days | Manuscript draft |

Total to-publishable-draft: about 25 working days, parallelizable across 2 people. Phases 2 and 5 dominate.

## Connection to PERSEUS

The FVS+Woodstock pipeline can be the canonical Maine state-level estimate within the four-model PERSEUS ensemble:

- FVS provides the yield curves all four models consume (Phase 2 deliverable).
- Woodstock provides the deterministic optimization-based estimate as a complement to GCBM, LANDIS, and CEM stochastic projections.
- Together, the four models form a model intercomparison, and the spread becomes a defensible structural-uncertainty band.

The PERSEUS workbook ensemble band would then be: `min, max, mean` across (CEM, FVS-Woodstock, GCBM, LANDIS), with the median as the central estimate and the inter-model spread as the structural uncertainty.

## Risks and limitations

1. **FVS calibration scope.** FVS-NE and FVS-ACD are calibrated to specific eastern US plot ranges. Maine spruce-fir under climate change extends beyond the ACD calibration envelope, particularly under RCP 8.5. We will need to flag projected ages and densities that exceed the calibration range and treat those projections as extrapolations.

2. **Treatment realism.** The 4 treatments are stylized; real Maine harvest practice mixes them in proportions that vary by stand, owner, and economic conditions. A more realistic Stage 5 would use the SAR-observed treatment proportions per county to weight the actions in the optimization. This raises the linear program from ~1,000 variables to ~10,000 but is tractable.

3. **Yield curve uncertainty propagation.** Bootstrapping the FVS posterior gives plot-level uncertainty bands, but this does not propagate climate uncertainty (single-GCM driver). Pairing this with the climate ensemble work (CLIMATE_ENSEMBLE_DESIGN.md) closes that gap.

4. **Woodstock licensing.** Commercial Woodstock is licensed; the lab has access through the CRSF FVS license. Open-source equivalents (`forestplanR`, `pyforestplan`) are usable but less mature. Decision needed in Phase 5.

5. **Scale.** The 72-cell × 4-treatment × 10-period optimization is roughly 3,000 decision variables and 500 constraints — easily solvable in Woodstock. Scaling to per-FIA-plot resolution (5,027 plots × 4 treatments × 10 periods = 200,000 variables) is also feasible with modern LP solvers (CPLEX, Gurobi) on a moderate workstation.

## Connection to current pipeline

This strategy is fully complementary to the existing CEM pipeline. No changes are needed to r17–r20 outputs; the Stage 2 yield curves and the Woodstock optimizer build on top of the existing FIA plot stratification table and ownership atlas. Both pipelines can be reported in the same manuscript or as paired companion papers.

The existing CEM r18 output remains the calibrated state-scale projection. The Woodstock output answers a different question: "given those calibrated dynamics, what is the optimal harvest schedule for a chosen objective and constraint set?"

## Files and references

- `config/maine_yield_curve_strata.csv` — current 108-cell stratification with FIA plot counts (Phase 1 complete).
- `manuscript/supplement_S4_yield_curve_strata_v2.docx` — visual companion.
- `docs/LANDOWNER_INTEGRATION_STRATEGY.md` — broader cross-model design context.
- `docs/CLIMATE_ENSEMBLE_DESIGN.md` — climate uncertainty propagation companion.
- Bettinger, P., Boston, K., Siry, J. P., and Grebner, D. L. (2017). *Forest Management and Planning* (2nd ed.). Academic Press. Chapters 7–9 cover Woodstock-class formulations.
- Crookston, N. L. and Dixon, G. E. (2005). The Forest Vegetation Simulator: a review of its structure, content, and applications. *Computers and Electronics in Agriculture* 49: 60–80.
- Maine Forest Service Stumpage Price Reports 2015–2024 (already in `config/maine_stumpage_forecast.csv`).
- Daigneault, A., Sohngen, B., and Sedjo, R. A. (2022). Carbon and market effects of US forest taxation policy. *Ecological Economics* 178: 107170.
