# PERSEUS Landowner Stratification Strategy

**Date:** 28 April 2026
**Author:** A. Weiskittel
**Status:** Strategy proposal — no model code written yet. Asks for sign-off from Adam before Phase 1 work.

## Source data

`/users/PUOM0008/crsfaaron/landowner/NewEngland_LandOwners.tif` (8.4 GB) and the CONUS companion `US_forest_ownership.tif`. Both are cuts of:

> Harris V, Caputo J, Butler B. 2025. *Forest ownership in the conterminous United States circa 2022: distribution of seven ownership types.* USDA Forest Service Research Data Archive RDS-2025-0045. Family Forest Research Center / USDA FS Northern Research Station.

10 m raster, NAD83 geographic, NE extent covers all of Maine plus surrounding states. NoData = 15. Class legend:

| Code | Label | Maine relevance |
|---:|---|---|
| 0 | Unknown Forest | Edge/buffer, treat as private-default proxy |
| 1 | Non-Forest | Mask out for forest models |
| 2 | Water | Mask |
| 3 | Family Forest (NIPF) | ~33% of Maine forest, dominant ownership in southern/coastal counties |
| 4 | Corporate/Other Private Forest | ~43% — Maine's signature TIMO/REIT-dominated industrial north |
| 5 | Tribal Forest | Small but politically meaningful (Penobscot Nation, Passamaquoddy) |
| 6 | Federal Forest | Acadia, White Mtn NF fragments — small in Maine |
| 7 | State Forest | Public Reserved Lands, BPL-managed — ~5% |
| 8 | Local Forest | Town forests, small |

This is a single, harmonized, peer-curated classification. Citable, version-pinned, FAIR-aligned. No need to home-brew owner attribution from MeGIS parcels.

## Why this matters scientifically

PERSEUS today treats Maine as a uniform forest by ecoregion. Reality: harvest intensity, species selection, rotation length, conservation status, and salvage behavior all vary by **landowner class**, not ecoregion. The most consequential split in Maine is the NIPF (Class 3) vs industrial/TIMO (Class 4) divide — these two classes manage on completely different time horizons and with completely different silvicultural regimes. Lumping them is a real source of bias in any state-total carbon projection.

Stratifying gives us:

1. **Behavioral realism** — owner-specific harvest schedules instead of uniform "50% harvest" applied state-wide
2. **Policy traction** — Maine policy levers (BPL management, conservation easement programs, Farm Bill payments to NIPF) act on owner classes, not ecoregions
3. **Cross-model coherence** — CEM already has NIPF/Industrial/Public stratification baked in. Bringing FVS, GCBM, and LANDIS to the same scheme makes ensemble bands meaningful at the owner level
4. **A defensible reporting axis** — state totals broken down by owner are far more interpretable to land managers than "RCP 8.5 ensemble"

## Cross-model crosswalk

The Harris–Caputo–Butler 8-class scheme is the lingua franca. Each model gets a mapping to its native categorization:

| HCB class | CEM class | FIA OWNGRPCD/OWNCD | GCBM classifier | LANDIS MA |
|---:|---|---|---|---|
| 3 Family | NIPF | OWNGRPCD 40, OWNCD 45/46 | `owner=family` | MA 3 |
| 4 Corporate | Industrial | OWNGRPCD 40, OWNCD 41/42/43/44 | `owner=corporate` | MA 4 |
| 5 Tribal | Public-Other | OWNGRPCD 40, OWNCD 47 | `owner=tribal` | MA 5 |
| 6 Federal | Federal | OWNGRPCD 10, 20 | `owner=federal` | MA 6 |
| 7 State | State | OWNGRPCD 30 | `owner=state` | MA 7 |
| 8 Local | Public-Other | OWNGRPCD 31 | `owner=local` | MA 8 |
| 0 Unknown | proportional reallocation | NA | `owner=unknown_proportional` | NA (assign by area weights) |

Class 0 ("Unknown Forest") gets reassigned proportionally to the Maine-wide forest distribution after masking 1/2/15. This avoids dropping ~10% of the raster.

## Per-model integration design

### 1. FVS-NE and FVS-Acadian (plot-based)

**Easiest integration of the four** because FIA plots already carry OWNCD/OWNGRPCD. The raster confirms and refines.

Workflow:
1. Pull OWNCD per FIA plot from PLOT table.
2. Spatial-join each plot lat/lon against the raster (extract pixel value); use the raster value when it disagrees with FIA OWNCD beyond a confidence threshold (raster is more recent than some FIA cycles).
3. Tag each plot with `owner_class ∈ {3,4,5,6,7,8}`.
4. Generate owner-specific harvest keyword sets:
   - **Class 3 (Family)**: probabilistic light thinning every 30–50 yr, ThinDBH at modest intensity, retention focus. Roughly 30–40% of plots harvested in any given decade.
   - **Class 4 (Corporate)**: aggressive ThinBBA at residual ≈ 50% current BA, 25–35 yr return; periodic clearcut endpoints in some scenarios. 70–80% of plots active.
   - **Class 5–8 (Public/Tribal)**: light improvement thinning only, ~50–80 yr return, no clearcut. ~10–20% of plots active per decade.
5. Re-aggregate state totals as `Σ_owner (plot_count_owner × scaling_factor × per_plot_AGB)`. Owner becomes a new dimension in the workbook (replacing or augmenting the binary harvest cell).

Implementation cost: 2–3 days. The hardest part is calibrating the owner-specific harvest behavioral parameters — Adam's CEM parameter set is the cleanest existing source.

### 2. GCBM / libcbm

GCBM treats classifiers as first-class. Adding `owner` as a classifier requires:

1. Extend the inventory CSV with an `owner_class` column derived by zonal stats over each inventory polygon (or per-pixel if running pixel-based).
2. Write owner-specific disturbance schedules in the JSON or CSV event tables: separate harvest event series for `owner=corporate` (high frequency), `owner=family` (low frequency), `owner=tribal/federal/state/local` (no harvest baseline + occasional salvage).
3. Optionally split the existing 4 spatial units × 6 owner classes = 24 stratification cells, but this is wasteful — better to keep 4 SUs and pivot ownership behavior into the disturbance schedule.
4. Re-run the 6 PERSEUS scenarios with owner-stratified harvest, then aggregate state totals by owner for the workbook.

Implementation cost: 4–6 days, mostly disturbance schedule construction and re-running the climate factorial. The Maine AIDB (per-ecoregion patch from this morning) already supports per-classifier stratification.

### 3. LANDIS-II

LANDIS already uses a Management Area raster as a first-class input. The HCB raster maps almost directly:

1. Reproject and resample the 10 m HCB raster to the LANDIS grid resolution (typically 100 m or 250 m for Maine state runs) using majority resampling.
2. Output 5 distinct MA codes (3, 4, 5, 6 collapsed with 7 and 8 as "public").
3. Write 3 or 5 separate Biomass Harvest prescriptions, one per MA, with owner-specific:
   - Stand age range / target species
   - Cohort selection rule (clearcut, single-tree selection, group selection, shelterwood)
   - Repeat interval
   - Site condition rules (e.g., no harvest on wetlands)
4. Pair with a single PnET-Succession config — climate axis stays per-cell.

Implementation cost: 1 day for the raster work, 2–3 days for the prescription drafting (rules need to come from Maine BMP guidance + Daigneault literature for behavioral parameters).

This also unblocks the LANDIS smoke test — the previous species.txt parsing failure is unrelated, but having a real MA raster gives us a defensible input for the eventual PnET run.

### 4. CEM (Daigneault model)

CEM already stratifies. The raster lets us **calibrate the relative areas** rather than relying on aggregate FIA tabulations.

Workflow:
1. Compute pixel-counts of each owner class within each Maine FIA county (or each PERSEUS ecoregion).
2. Hand the area-weighted owner shares per spatial unit to Adam to update CEM's stratification weights.
3. Adam adjusts the supply curves and harvest allocation in CEM accordingly.

Implementation cost: 1 day on my end (zonal stats + handoff CSV); CEM-side rework is Adam's call.

## Implementation roadmap

| Phase | Work | Owner | Cost | Output |
|---|---|---|---|---|
| 1 | Build Maine ownership atlas: clip raster to Maine, area-by-class × ecoregion × county, FIA plot tag | Aaron | 1–2 days | `maine_ownership_atlas.csv`, `figs/maine_ownership_map.png` |
| 2 | FVS owner-stratified harvest config + run on one PERSEUS cell | Aaron | 2–3 days | Per-owner state totals validated against published Maine harvest stats |
| 3 | GCBM owner classifier + disturbance schedules + 6-cell rerun | Aaron | 4–6 days | Owner-stratified libcbm bands |
| 4 | LANDIS MA raster + prescriptions | Aaron | 3–4 days | LANDIS-ready MA input + Biomass Harvest config |
| 5 | CEM stratification handoff CSV | Aaron → Adam | 1 day | `cem_owner_shares.csv` |
| 6 | Workbook redesign: add owner dimension to ensemble blocks | Aaron | 2 days | Updated `_PERSEUS_UM_Model_Comparison_OWNERSHIP.xlsx` |

Total before workbook: ~3 weeks of focused work, parallelizable in places. Phases 1, 4, 5 can run in parallel.

## Key methodological questions for Adam

1. **Factorial structure.** Does PERSEUS treat owner stratification as a refinement of the existing 6 cells (each cell now reports both aggregate and owner-broken-down totals), or as a new factorial axis (6 cells × N owners = 30+ cells)? My recommendation: refinement, not expansion — keep the 6 published scenarios as the main reporting unit, surface owner detail in supplementary tabs.
2. **Behavioral parameters.** Where do owner-specific harvest probabilities, intensities, and return intervals come from? CEM's calibration is the obvious anchor. Worth confirming that FVS, GCBM, and LANDIS use the *same* owner-behavioral parameters across the four models, otherwise we're recreating the cross-model uncertainty problem at the owner level.
3. **Conservation easement overlay.** ~3 million acres of Maine private forest are under permanent or term easements (Forest Society of Maine, Appalachian Mountain Club, TNC). These don't show up in HCB classes — they live as a separate vector layer with the State of Maine. Should we overlay easements as a "no-harvest" mask on Classes 3 and 4? Strong recommendation: yes, but in Phase 6 once the base stratification is wired.
4. **Tribal forest treatment.** Class 5 is a small share by area but matters politically. Should we run it under the Public/State assumption (low harvest) or leave it as a separate "Tribal" reporting category? Recommend separate category, no harvest in baseline scenario, with explicit footnote.
5. **Class 0 (Unknown Forest) handling.** Allocate proportionally as proposed, or leave unallocated and report as a residual? Recommend proportional reallocation but report the residual in supplementary methods.

## Caveats and risks

- **Raster vintage (2022).** Maine ownership has churned heavily since then. Recent TIMO sales, conservation acquisitions (Pingree-Crown easement in particular), and consolidation are not captured. Long-term, a Maine-specific update cycle would help.
- **Raster resolution mismatch.** 10 m source vs ~100 m typical model grid. Majority resampling loses minority owners (small Tribal/Local parcels). Consider proportional area weighting at the model grid cell instead of majority assignment for GCBM/LANDIS.
- **Behavioral calibration is the bottleneck.** Adding ownership without calibrated owner-specific harvest behavior just reshuffles the same numbers. The real value comes from owner-specific Markov harvest probabilities (Daigneault has published these for Maine).
- **Workbook complexity.** Adding owner stratification doubles the dimensions. Worth thinking about whether the deliverable workbook stays as-is with a supplementary Ownership Tab, or whether we redesign around an Owner × Cell × Model lattice.

## Phase 1 deliverables (first concrete step)

If you greenlight Phase 1, the immediate deliverable in 1–2 days:

1. `maine_ownership_atlas.csv` — area (acres) by owner class × FIA county × ecoregion × ME spatial unit
2. `fia_plots_with_owner.csv` — every Maine FIA plot tagged with HCB class from raster zonal extraction, joined with FIA-reported OWNCD for cross-validation
3. `figs/maine_ownership_map.png` — statewide map at 250 m, color-coded by owner class
4. `figs/maine_ownership_pie_by_county.png` — small-multiples pie chart, one per county
5. Brief data note documenting the area discrepancy between HCB raster and Hagan/Whitman published 2005 estimates

That set is enough to inform the team conversation about whether to proceed to Phases 2–6.

## Addendum: Yield curves as the cross-model integration backbone

(Added 28 Apr 2026 in response to AW: "the key is also generating yield curves by forest type × ecoregion × landowner given management differences.")

This is the right framing. Owner stratification without owner-specific growth and yield trajectories just reshuffles the same biomass numbers. The deliverable that every model actually needs is a **5D yield curve lattice** — and it's also the most natural artifact for Adam, Bob, Erin, and Ben to inspect, critique, and version-control.

### The lattice

`yield(t) = f(forest_type, ecoregion, owner, treatment, age)`

Forest type — 6 classes for Maine, aligned with FIA forest type groups:
1. Spruce/Fir (FORTYPCD 120s)
2. Northern Hardwoods — sugar maple/beech/birch (800s)
3. Aspen/Birch (900s)
4. Mixedwood — spruce/hardwood (700s)
5. White/Red Pine (100s, excl SF)
6. Oak/Pine and Hemlock (400s, 500s)

Ecoregion — 3 (ME_NH, ME_NCZ, ME_APH), already in our libcbm Maine AIDB.

Owner — 6 HCB classes (3,4,5,6,7,8) collapsed where sample size demands.

Treatment — 4 trajectories per cell:
- `notreat` — passive succession baseline
- `light_partial` — single-tree selection / ITS, ~15-20% BA removal, 30-yr return
- `heavy_partial` — shelterwood/group selection, ~50% BA removal, 40-50 yr return
- `clearcut_regen` — clearcut + planted spruce or natural regen, 40-50 yr rotation

Age axis — 0 to 150 yr at 5-yr resolution.

That's 6 × 3 × 6 × 4 × 31 = ~13,400 yield points per response variable. Response variables: AGB (tons/ac), merchantable volume (cu ft/ac or MBF/ac), live carbon, mortality, regen.

### How each model consumes the lattice

- **GCBM/libcbm** — yield curves are the *primary* input via `growth_curves.csv` keyed by classifier set. Drop-in replacement for the current single-curve-per-spatial-unit setup. This is the model that benefits most.
- **LANDIS-II PnET-Succession** — uses the curves as cohort-level biomass references / growth multipliers (`PnETOutputSites` calibration anchor).
- **FVS-NE / FVS-Acadian** — these *produce* the curves. Run FVS on plot subsets stratified by forest type × ecoregion × owner, fit a smooth (Chapman-Richards or Korf) to the per-cell ensemble of plot trajectories, archive as the canonical yield curve.
- **CEM** — uses the curves as supply-side productivity assumptions per management class.

So FVS is the source-of-truth generator; the other three are consumers. That makes the workflow linear and version-controllable: build curves once, distribute to all models.

### Build pipeline (Phase 1.5, inserted before model integration)

1. **Stratify FIA plots** by FORTYPCD → forest type bucket, ecoregion overlay, HCB raster owner extraction. Expect ~3,000 Maine plots distributed across the 6 × 3 × 6 = 108 cells. Many cells will be sparse (Federal in southern lowland, Tribal in mountains) — pre-screen and collapse where n < 30.
2. **Run FVS-NE and FVS-ACD** for each populated cell, four treatment trajectories per cell, 100 yr horizon, posterior draws (now that BAIMULT works) for uncertainty bands. This is essentially a re-purposing of the current `perseus_factorial` infrastructure with finer stratification.
3. **Fit smoothed yield curves** to the per-plot output. Chapman-Richards (`y = a*(1 - exp(-b*age))^c`) for AGB; flexible piecewise for treated trajectories where rotation imposes discontinuities. Fit per cell × treatment.
4. **Archive** as `maine_yield_curves_v1.csv` (long format) plus `.parquet` for fast model ingestion. Include 5/50/95 quantile columns so consumers can use bands not just the mean.
5. **QA** — sum-up to state total, compare against the published Maine state harvest reports (DACF) and against the Hagan biomass benchmark.
6. **Distribute** — write thin model-specific adapters: GCBM ingestion script (already partly written for libcbm), LANDIS PnET parameter writer, CEM stratification CSV.

### Why this is the right leverage point

- **One artifact, four models.** Curves are model-agnostic. Once they exist, GCBM/LANDIS/CEM consume identical biology — eliminating one big source of cross-model disagreement that we currently treat as "structural uncertainty."
- **Behavioral parameters become explicit.** Owner-class harvest behavior is no longer hidden in scenario assumptions; it's visible in the treatment dimension and the curve shapes.
- **Version-controllable.** `maine_yield_curves_v1.csv` is the kind of object that goes in a repo with a DOI. Reviewers can challenge the curves directly.
- **Decouples ownership from harvest behavior.** A Class 4 plot under "notreat" follows the same biology as a Class 3 plot under "notreat" — the differences live entirely in *which treatments which owners apply, and how often.* That's the right place for the differences to live.

### Cost estimate

Phase 1.5 (yield curve generation) sits between Phase 1 (atlas) and Phases 2–4 (model integration). Honest scoping:
- Stratification + FIA tagging: 1 day (subsumes Phase 1)
- FVS factorial across 108 × 4 = 432 cells × 100 draws on Cardinal: 1 wall day with proper array job sizing, given today's BAIMULT infrastructure
- Smoothing + fitting + QA: 2 days
- Adapter scripts (GCBM, LANDIS, CEM): 2 days

Total: ~1.5 weeks for the curve lattice + adapters. Phases 2–4 then become much faster because they're just consumption.

### What can be done with 2% session left

1. ✅ Strategy + addendum captured in this doc (done).
2. (Next session) Stage a Cardinal-side stub script `build_yield_curves.py` that reads HCB raster, joins FIA plots, emits the 108-cell stratification table. ~30 min of work.
3. (Next session) Run a small smoke test: 1 cell (e.g., Spruce/Fir × ME_NCZ × Class 4 × notreat) at full FVS resolution, fit a Chapman-Richards, plot. Sanity-check the curve makes biological sense.

If posterior factorial v3 finishes overnight and looks clean, this becomes the natural Phase 2 of the PERSEUS arc.

## Files

- Raster source: `/users/PUOM0008/crsfaaron/landowner/NewEngland_LandOwners.tif`
- CONUS companion: `/users/PUOM0008/crsfaaron/landowner/US_forest_ownership.tif`
- QGIS project: `/users/PUOM0008/crsfaaron/landowner/Forest_Landowners.qgz`
- Citation source: `RDS-2025-0045_Metadata_Fileindex.zip` in the same dir
