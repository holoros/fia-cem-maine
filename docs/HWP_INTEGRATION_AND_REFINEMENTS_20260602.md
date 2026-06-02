# HWP long-term storage and additional CEM refinements

**Date:** 2026-06-02
**Author:** A. Weiskittel (CRSF, University of Maine)
**Reviewed:** OSC Cardinal `/fs/scratch/PUOM0008/crsfaaron` and `~/perseus_db` outputs, the CEM harvest module, the PERSEUS YC product/HWP results, and the WPsCS-Estimator model (github.com/xinyuanwylb19/WPsCS-Estimator, Xinyuan Wei).

## The key refinement: harvested wood products and long-term storage

### Current gap

CEM's seven-pool carbon account evolves the live and (stationary) dead/litter/soil pools, but harvested carbon simply leaves the system. `11_economic_harvest.R` already splits each cut into partial vs clearcut, estimates sawlog/pulpwood composition by forest type, and reports `harvest_removals` per cycle, so the harvested-carbon stream exists. What is missing is the downstream fate of that carbon: a fraction stays stored for decades in lumber, panels, and paper, and a further fraction persists in landfills. Without an HWP pool, CEM overstates the climate cost of harvest, especially for the managed scenarios that are the whole point of the policy comparison.

### What already exists to build on

- **WPsCS-Estimator** is a cohort-decay HWP model. Annual harvested carbon, split into Sawlog / Pulpwood / Biomass, is allocated to end-use products (lumber and veneer to building construction, exterior, and home applications; pulpwood to paper and commodity board; biomass to biochar and fuel) and then each product cohort decays over time via disposal-rate functions, with fractions routed to recycling and to landfill (long-term storage) plus charcoal. It ships Maine and US parameterizations (`WP_Data/Maine_WPs.csv`, `US_WPs.csv`) and four scenarios. Input contract: a yearly table `Year, Harvested_Timber, Biomass, Pulpwood, Sawlog` in carbon units. This is an in-house CRSF model and is directly citable.
- **PERSEUS already has a CONUS HWP layer on the YC side.** `ycx_products.R` allocates standing volume and biomass into sawtimber / pulpwood / residue per forest-type x ecoregion cell and age class (FIA size thresholds and volume partitions), and `docs/results/conus_hwp_netstock_bystate.csv` reports HWP `net_stock_Tg` by state, scenario, and year offset, with per-state product fractions (sawtimber share WA 0.87, GA 0.56, ME 0.47, MN 0.37). So the explorer can already show HWP for the YC engine; CEM needs to produce a comparable pool so the two engines are consistent.

### Integration design (CEM gains an HWP pool, aligned with WPsCS and the YC HWP)

1. **Emit annual harvested carbon by product from CEM.** In `06_projection_engine.R` / `11_economic_harvest.R`, accumulate per-cycle harvested carbon and split into Sawlog / Pulpwood / Biomass(residue) using the existing composition estimator, cross-checked against the PERSEUS per-state product fractions for consistency. Interpolate the 5-year cycle to annual (or run the HWP model on the 5-year step). Output a per-scenario `harvested_C_by_product` series.
2. **Port WPsCS to an R module** (`R/12_hwp_storage.R`) or call the Python directly. The decay mathematics is light (disposal-rate integrals per product cohort); an R port keeps the pipeline single-language and lets the HWP pool carry the same bootstrap CI as the live pools. Parameterize from `Maine_WPs.csv` for ME and `US_WPs.csv` for other states initially, refining per region later.
3. **Add HWP as the eighth pool.** Extend the state-summary CI with `mmt_hwp_inuse`, `mmt_hwp_landfill`, and `mmt_hwp_total`, and report a `total_system_c = total_ecosystem_c + hwp_total` metric. This closes the harvest side of the carbon balance and makes the managed-vs-reserve comparison fair (reserve stores more in the forest; managed stores less in the forest but adds the HWP pool).
4. **Validate** by reproducing the WPsCS `Maine_Results.csv` from `Maine_WPs.csv` with the R port (a unit test), then comparing CEM-driven Maine HWP against it.
5. **Ingest into PERSEUS.** Add `hwp_total` (and the flux already present, `harvest_c_yr`) to the metric catalog, and surface the CEM HWP pool through the `--state` adapter alongside the YC HWP `net_stock`, so the explorer shows both engines' product carbon on one axis.

This is the single most defensible addition because it (a) corrects a known bias in the harvest scenarios, (b) uses an in-house, already-parameterized model, and (c) aligns CEM with the HWP layer PERSEUS already publishes for YC.

## Other refinements now possible (each enabled by an artifact already on scratch)

The scratch survey shows the PERSEUS feeders have advanced well past what CEM currently uses. Several map onto open items in the May 30 refinement plan and can now draw on real CONUS products rather than placeholders.

| Refinement | Enabling artifact on scratch | What it replaces in CEM |
|---|---|---|
| Climate-sensitive productivity | `cspi_v3/` (climate-sensitive productivity index v3; BGI/CSI rasters) | The coarse Maine `1 + 0.010*dT` temperature scalar in `06` (plan 2.5); use the CSPI envelope PERSEUS already drives the YC climate ribbon with |
| Empirical disturbance | `conus_mort/`, v5 disturbance probability rasters (fire/insect/disease/weather `_prob_v5` in the metric catalog) | The Maine-hardcoded spruce budworm cycle (plan 2.6); drive per-state disturbance from the CONUS probability layers |
| Dead / litter dynamics | harvest + disturbance inputs now available; HWP closes the harvest side | The stationary dead/litter/soil pools (plan 2.4) |
| Growth realism | `RD_growth_GRM/` (relative-density growth from FIA growth-removal-mortality) | Donor growth-rate caps and SDImax dynamics in `06` |
| Spatialization | `TREEMAP_outputs_v5/`, `yield_curves_conus/` | State-aggregate CEM output, enabling gridded CEM maps for the explorer's raster layers |

Priority order: HWP first (the key ask and the clearest bias fix), then CSPI-based climate response (replaces the most arbitrary remaining constant and improves the RCP 8.5 divergence), then v5 disturbance, then dead/litter dynamics, then growth/GRM and spatialization.

## Recommended first build

1. Port WPsCS to `R/12_hwp_storage.R`; validate it reproduces `Maine_Results.csv` from `Maine_WPs.csv` (unit test).
2. Wire CEM's harvested-carbon-by-product output into it; add the HWP pool and `total_system_c` to the state-summary CI.
3. Run the Maine canonical and the WA/GA refined scenarios with HWP on; confirm the managed-vs-reserve comparison shifts in the expected direction (managed gains an HWP pool that partly offsets the lower in-forest stock).
4. Add `hwp_total` to the PERSEUS metric catalog and ingest via the `--state` adapter, so CEM and YC HWP are shown together.

This is a self-contained module (the harvested-carbon stream already exists), so it can be built and validated against WPsCS before touching the production runs.

## Update (2026-06-02): WPsCS validated in our environment; approach revised

WPsCS-Estimator now runs on Cardinal (clean venv: numpy 2.4.6, scipy 1.17.1, pandas 3.0.3; one Linux path-separator fix) and reproduces its own bundled Scenario_1 reference output to within rounding (max abs diff 1.0 across 119 years x 25 columns). The HWP storage pool extracts cleanly as in-use product stock plus landfill (plus charcoal).

This changes the build decision: **drive Wei's validated Python model directly rather than re-port it to R.** A re-implementation cannot be more accurate than the original and only risks subtle mismatch in the cohort-decay integrals, while the original is citable. The runnable setup, the HWP-pool definition, the decay parameters, and the remaining wiring steps are captured in `perseus_integration/hwp/HWP_SETUP.md`.

Remaining concrete steps (unchanged in substance): emit CEM harvested carbon by product (Year, Biomass, Pulpwood, Sawlog) per scenario, extend the product-allocation parameters past 2020 to the projection horizon, run the bridge, add `hwp_total` plus a `total_system_c` to the state-summary CI, and ingest `hwp_total` into PERSEUS alongside the YC HWP `net_stock`.
