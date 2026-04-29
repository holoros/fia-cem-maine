# Climate Ensemble Sampling — Design Note

**Status:** Scaffolding only — not yet implemented as of r20.
**Author:** A. Weiskittel
**Date:** 29 April 2026

## Motivation

The FIA CEM pipeline currently uses HadGEM2-AO point-estimate climate forcing (MACAv2 downscaled, RCP 4.5 and RCP 8.5). Reported confidence intervals reflect plot-level bootstrap uncertainty only — they do not propagate climate uncertainty.

Across CMIP5, the inter-model spread for Maine end-of-century temperature is roughly 1.5 to 4.5 °C under RCP 8.5; precipitation spread is roughly −10 to +20 percent. HadGEM2-AO is on the warm-and-wet end of the ensemble, so single-GCM projections may overstate growth under high-CO2 / high-precipitation conditions and understate vulnerability for boreal species at warm thermal limits.

A proper climate uncertainty band requires sampling from the GCM ensemble.

## Proposed approach

**MACAv2 CMIP5 GCMs available** (already preprocessed for the eastern US):
1. bcc-csm1-1
2. bcc-csm1-1-m
3. BNU-ESM
4. CanESM2
5. CCSM4
6. CNRM-CM5
7. CSIRO-Mk3-6-0
8. GFDL-ESM2G
9. GFDL-ESM2M
10. **HadGEM2-AO** ← currently used
11. HadGEM2-CC
12. HadGEM2-ES
13. inmcm4
14. IPSL-CM5A-LR
15. IPSL-CM5A-MR
16. IPSL-CM5B-LR
17. MIROC5
18. MIROC-ESM
19. MIROC-ESM-CHEM
20. MRI-CGCM3
21. NorESM1-M

**Sampling design.** 4-tier ensemble:
- **Cool-dry**: GFDL-ESM2M, MIROC5, NorESM1-M
- **Cool-wet**: bcc-csm1-1, CCSM4, MRI-CGCM3
- **Warm-dry**: IPSL-CM5A-LR, MIROC-ESM, BNU-ESM
- **Warm-wet**: HadGEM2-AO (current), HadGEM2-CC, CanESM2

Total: 12 GCMs × 2 RCPs × ~3 statistical bootstrap reps = 72 climate realizations.

**Implementation plan.**
1. **Pre-process climate**: extend `download_macav2.sh` to fetch all 12 GCMs for ME plot coordinates (8 hours on Cardinal compute node, ~30 GB pre-downloaded).
2. **Refactor `08_climate_interface.R`**: add a `climate_realization` argument that selects which GCM × RCP series to use for the current sim.
3. **Refactor `06_projection_engine.R`**: pass `climate_realization` through `project_one_cycle()`. Each Monte Carlo sim picks one realization at random per scenario_set call.
4. **Submit script naming**: `submit_<rcp>_<owner_strat>_climate_ensemble_r21.sh` runs 100 sims × 12 GCMs = 1,200 sims per scenario × 5 scenarios = 6,000 sims. Memory budget: 240 GB (vs 180 GB for r20). Walltime: estimated 6 hours.
5. **Aggregation**: `10_state_expansion.R` already groups by sim. Posterior CI now reflects climate ensemble + plot bootstrap jointly.

## Expected effect

Empirical CMIP5-derived AGC uncertainty bands for the southeastern US (Wear and Coulston 2019) widen the 95 percent confidence interval by roughly 1.5x to 2x compared with single-GCM bootstrap-only intervals. Maine should fall in a similar range.

For the manuscript, this would produce a separate Section 3.8 on "Climate ensemble uncertainty" and would shift the message from "harvest dominates climate" (which is true at the GCM mean) to "harvest dominates climate at the GCM mean but climate uncertainty alone covers a 20 to 40 MMT 2074 AGC band, so harvest decisions are confident only in the ensemble-averaged sense."

## Resource budget

- Disk: 30 GB for preprocessed MACAv2
- Compute: 6 hours × 4 (RCP × overlay) = 24 GPU-hours = ~$30 of compute
- Engineer-time: 1 to 2 days for preprocessing pipeline + climate interface refactor

## Decision point

Climate ensemble sampling is a clean future refinement (r21+) but not required for the current manuscript. The current r18/r19 result (R14 owner stratification dominant calibration improvement) stands on its own. Recommended sequencing:

1. **r20** (mass-balanced R14, in flight) — disentangle spatial redistribution from net rate effect of ownership
2. **Manuscript first draft submission** (with r18/r19/r20 results) — let the calibration improvement story drive the narrative
3. **r21 climate ensemble** as a revision response if reviewers ask about climate uncertainty propagation, OR as a follow-on paper focusing on uncertainty decomposition
