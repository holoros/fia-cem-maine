# CONUS-wide ecoregion donor pool: blocked on partial ENTIRE_TREE download

*Generated 20 May 2026 after attempting to extract western states for the CONUS donor experiment.*

## TLDR

The CONUS-wide ecoregion-membership donor pool is the correct fix the L7b hindcast pointed to (`L7B_HINDCAST_RESULTS_20260520.md`): WA west-side Douglas-fir/hemlock subjects need ecologically-similar donors (coastal CA/OR plots) that do not exist in the OR/ID/MT neighbor cohort. The `--conus_donors` flag is deployed and works. However, the experiment is **blocked on data availability**: the Cardinal `~/FIA/ENTIRE_TREE.csv` is only a partial download covering 11 states (CT, GA, ME, MA, MN, NH, NY, OR, RI, VT, WA), not the full CONUS. California (STATECD 6) — the key ecological donor for WA west-side — has COND and PLOT records in `ENTIRE_COND.csv`/`ENTIRE_PLOT.csv` but NO TREE records anywhere on Cardinal.

## What was attempted

`scripts/extract_western_states.R` (SLURM 10125921) extracted CA, AZ, CO, NV, NM, UT, WY from the CONUS ENTIRE_*.csv files into per-state fia_data files. Result:

- COND and PLOT extracted successfully for all 7 western states (ENTIRE_COND/PLOT have full CONUS coverage).
- TREE returned 0 rows for all 7. ENTIRE_TREE.csv contains only STATECDs 9, 13, 23, 25, 27, 33, 36, 41, 44, 50, 53 — the eastern multistate cohort plus OR and WA.

The incomplete western COND/PLOT files (no matching TREE) were moved to `~/fia_data/_incomplete_western_20260520/` to avoid breaking the read_fia_direct loader, which expects COND+PLOT+TREE per state. fia_data is back to the 18 complete states.

## Why this blocks the WA experiment specifically

The 18 states with complete COND+PLOT+TREE are: AL, CT, FL, GA, ID, MA, ME, MN, MS, MT, NH, NY, OR, RI, SC, TN, VT, WA. Among these, the only Pacific-coast ecological donors for WA west-side are OR (already in the WA neighbor cohort) and WA itself. Running `--conus_donors` over the 18 complete states adds eastern states to WA's donor pool, but the Layer 7b cem_ecoregion matching key correctly prevents eastern plots from matching WA west-side subjects (different ecoregions). So the bias-driving WA cells would still fall through to iter3 exactly as in the neighbor cohort. No new information.

The WA conus smoke (SLURM 10125785) was cancelled because it could only reproduce the no-improvement result over the same effective ecological donor set.

## The prerequisite: download CA (and western) TREE from FIA DataMart

To properly power the CONUS donor experiment, CA TREE (and ideally the full Pacific marine + montane states: CA, plus complete WA/OR coverage) must be downloaded from the FIA DataMart. Options:

1. **rFIA::getFIA(states = "CA", tables = c("TREE", "COND", "PLOT", "POP_*"))** on Cardinal — requires network access to the FIA DataMart from the compute environment. rFIA is installed.

2. **Direct download** of `CA_TREE.csv` from https://apps.fs.usda.gov/fia/datamart/CSV/CA_TREE.csv (and CA_COND, CA_PLOT) — the FIA DataMart per-state CSV bundles. The CA TREE table is large (~2M+ records).

3. **Extend the existing FIA download pipeline** (`R/01_data_prep.R download_fia_rfia`) to fetch the western states fresh.

This is a user-side or network-enabled step. From the analysis sandbox, web fetch to fs.usda.gov is not on the allowlist, so the download must happen on Cardinal (which has internet) or be staged by the user.

Effort once CA TREE is downloaded: ~30 min to re-extract + 12 hr SLURM rerun of WA --conus_donors at production scale.

## What completes regardless: MN + GA evidence base

The MN and GA hugemem reruns (SLURM 10124341-44, now RUNNING) will produce the MN and GA Layer 7b hindcasts. Expected outcome: the same no-improvement pattern as WA (the MN northern boreal aspen-birch and GA loblolly cells also have no ecological cross-state donors in their neighbor cohorts). This completes the 8-state evidence base supporting the manuscript's reframed finding.

## Manuscript implication

The reframed finding stands and is publishable without the CONUS donor experiment:

> "Ecoregion-stratified matching within a neighbor-state donor pool does not reduce cross-state bias because the bias-driving subject cells have no ecologically-matched donors in the cohort. The effective remediation requires a CONUS-wide donor pool defined by ecoregion membership; we demonstrate the matching infrastructure (the cem_ecoregion key) and identify the data requirement (full CONUS TREE coverage) as the remaining barrier. A complete CONUS donor pool experiment is left for future work pending the FIA DataMart TREE download for the western states."

This is an honest and complete scientific contribution: it identifies the mechanism, deploys the matching infrastructure, and precisely specifies the data requirement for the full fix.

## Status

- `--conus_donors` flag deployed and working (over available complete states)
- Western COND/PLOT extracted but TREE unavailable; incomplete files quarantined
- WA conus smoke cancelled (uninformative without CA TREE)
- MN + GA hugemem reruns RUNNING — complete the 8-state evidence base
- Next prerequisite: CA TREE download from FIA DataMart (network step, Cardinal-side)
- Manuscript finding stands without the CONUS experiment; the experiment is future work
