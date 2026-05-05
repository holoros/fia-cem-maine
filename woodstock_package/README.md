# Maine FIA v4 Yield Curve Package for Remsoft Woodstock

**Version:** 1.0 (2 May 2026)
**Source archive:** [github.com/holoros/fia-cem-maine](https://github.com/holoros/fia-cem-maine)
**Contact:** Aaron R. Weiskittel, aaron.weiskittel@maine.edu, Center for Research on Sustainable Forests, University of Maine

This package contains Remsoft Woodstock ready inputs derived from the Maine FIA empirical chronosequence yield curve archive (v4). It includes 42 stratum × treatment yield tables across 35 forest type × ecoregion × ownership cells covering 90.5 percent of forested FIA conditions in Maine. All yields are anchored to FIA observations from the EVALIDator panel (4,547 plots with stand age, fitted with constrained Chapman-Richards growth functions).

## Files in this package

| File | Purpose |
|------|---------|
| `THEMES.txt` | Four classifier themes: forest type, ecoregion, ownership, treatment |
| `YIELDS.txt` | YIELDS section with 42 stratum × treatment age vs response tables |
| `AREAS.txt` | AREAS template with placeholder area = 1.0 ha per stratum |
| `LIFESPAN.txt` | Per stratum maximum age set to age_to_90_percent of the v4 AGB fit |
| `ACTIONS.txt` | CLEARCUT and PARTIAL_CUT templates with Faustmann optimal rotations |
| `maine_v4_yields.csv` | Flat CSV copy of the yield series for QA and visualization |
| `manifest.json` | Provenance metadata |
| `build_woodstock_pkg.R` | The R script that built this package; reproducible from the source archive |

## Quick start in Woodstock

The package follows the standard Remsoft Woodstock section format. Open your model project and either paste the contents of each `*.txt` file into the matching section of your existing model, or import them as fresh sections in a new model:

1. **THEMES.txt** goes into the THEMES section. The four themes are forest type group, ecoregion (3 zones aligned with the libcbm AIDB), ownership (4 classes after Tribal/Federal/Local merge into Public-Other), and treatment history (untreated or harvested).
2. **YIELDS.txt** goes into the YIELDS section. Each `*Y` block is keyed by the four classifier values; columns are AGE, AGB_tonac, Vol_m3ha, and Carbon_tonac. Carbon equals AGB_tonac times 0.45.
3. **AREAS.txt** is a template; replace each 1.0 placeholder with your actual area in hectares per stratum. Maine area distribution by forest type and owner is available in `config/maine_ownership_atlas.csv` in the source repository, or compute it from your FIA expansion.
4. **LIFESPAN.txt** sets the maximum stand age before forced exit. We use age_to_90pct of the v4 AGB Chapman-Richards fit, bounded to [50, 150] years. Adjust to match your model conventions.
5. **ACTIONS.txt** is a starter set with two actions, CLEARCUT and PARTIAL_CUT, plus comments listing the Faustmann optimal rotation per stratum (no carbon floor). Use these comment lines to seed your own constraint logic.

## Stratum naming convention

Each stratum is identified by a four classifier tuple separated by spaces:

> `<forest_type> <ecoregion> <ownership> <treatment>`

Forest type values: Aspenbirch, Mixedwood, Northernhardwood, OakPineHemlock, Other, Sprucefir, WhiteRedpine.

Ecoregion values: ME_NH (Northern Highlands), ME_NCZ (Northern Central Zone), ME_APH (Acadian Plains and Hills).

Ownership values: NIPF (non industrial private forest), Industrial, State, PublicOther (Tribal plus Federal plus Local merged).

Treatment values: untreated (no recorded harvest within 30 yr) or harvested (TRTCD 10/20/30/50 within 30 yr).

## Conversion factors

All yields are stored in two unit systems for convenience.

> AGB tons per acre × 0.45 = carbon tons per acre
> tons per acre × 2.2417 = metric tons (Mg) per hectare
> cubic feet per acre × 0.069972 = cubic meters per hectare
> Jenkins below ground / above ground ratio = 0.22 (multiply AGB_MgHa by 0.22 for root carbon)
> Jenkins component splits: foliage 5 percent of AGB, other above ground (branches plus bark) 18 percent

## Methodology summary

Yield curves are fitted to FIA plot age vs response observations using the Chapman-Richards form:

> y(age) = a × (1 minus exp(minus b × age))^c

Per stratum × treatment (where 6 plots minimum and 3 unique ages are available), we fit five responses: AGB (tons per acre), basal area (ft per acre), trees per acre, carbon (tons per acre = 0.45 × AGB), and merchantable volume (cubic feet per acre). The port algorithm in R nls bounds parameters to a in [max(y), 3 × max(y)], b in [0.005, 0.20], c in [0.5, 5.0]. Uncertainty is from 200 bootstrap resamples on the plot index.

The v4 archive applies an asymptote anchor: where the harvested chronosequence yields an asymptote more than 20 percent above the matched untreated cell, v4 rescales harvested a to the untreated a while preserving harvested b and c (recovery rate and shape). This addresses an upward bias in harvested fits caused by the lack of an explicit time since treatment dimension. Twenty of 60 paired harvested fits triggered the anchor across all five response variables; the rest stayed within tolerance.

## Faustmann optimal rotations included

The ACTIONS.txt file lists the Faustmann optimal rotation R* per untreated stratum under notional Maine 2024 stumpage parameters: 12 dollars per cubic foot blended price, 4 percent real discount, 200 dollars per acre regeneration cost. Headline sweep (untreated cells, mean across all 35 cells):

| Carbon floor (ton/ac time-avg AGB) | Mean R* (yr) | Range | Mean shadow price ($/ton C) |
|---|---|---|---|
| 0 (no constraint) | 26 | 20 to 40 | reference |
| 30 (low) | 86 | 50 to 130 | 403 |
| 45 (medium) | 129 | 105 to 150 | 375 |
| 60 (high) | infeasible | n/a | n/a |

These should be used as starting points for your scenario constraints, not as final policy targets. They are notional in three ways: the discount rate may not match your client's cost of capital, the blended stumpage price treats sawlog and pulp as fungible, and the rotation sweep does not account for inter stratum substitution that a full LP allows. Real Maine industrial rotations under multi product pricing are typically 35 to 70 years.

## Caveats and limitations

The harvested yield curves are observational chronosequences without time since treatment as an explicit covariate. Even with the v4 anchor, the recovery rate (b parameter) is conditioned on the empirical distribution of harvest ages in the FIA panel. For long horizon LP runs with frequent harvest cycling, validate the recovery trajectories against your management experience.

The disturbed class (4 percent of plots with severe DSTRBCD) is held aside in v4. Yield trajectories under spruce budworm, windthrow, or fire scenarios should use a separate disturbance recovery curve (planned for v5).

The CarbonMgHa column is computed from AGB only and does not include below ground, dead wood, or soil pools. For full carbon accounting, layer Jenkins below ground (multiply AGB by 0.22) and use a separate dead wood and soil model.

The stratum × treatment combinations come in two flavors: cells where both untreated and harvested fits exist (35 cells × 2 treatments = 70 max, of which 42 have valid fits), and cells where only one treatment has enough plots. For the 28 cell × treatment combinations without a valid fit, no yield row appears in the package; either parameterize them by analogy to a similar stratum or hold them aside in your model.

## Citation

If you use this package in a publication or presentation, please cite:

> Weiskittel, A.R. (2026). Maine FIA v4 Yield Curve Package for Remsoft Woodstock. Center for Research on Sustainable Forests, University of Maine. github.com/holoros/fia-cem-maine

The full methodology paper is in preparation. Please reach out if you would like a preprint or want to coordinate a cross model PERSEUS comparison.

## Reproducing this package

The R script `build_woodstock_pkg.R` regenerates every output from the source archive. Run it from the root of a clone of [github.com/holoros/fia-cem-maine](https://github.com/holoros/fia-cem-maine):

```bash
git clone https://github.com/holoros/fia-cem-maine.git
cd fia-cem-maine
Rscript woodstock_package/build_woodstock_pkg.R . woodstock_package
```

The script reads three CSVs from `yield_curves/` and emits the package contents in under one second. No external dependencies beyond base R.

## Companion materials

The same v4 archive is also packaged for three other modeling frameworks:

> `yield_curves/adapters_v4/gcbm_growth_v4_curves.csv` for GCBM and libcbm
> `yield_curves/adapters_v4/landis_biomass_parameters_v4.csv` and `.txt` for LANDIS-II PnET-Succession
> `yield_curves/adapters_v4/cem_productivity_multipliers_v4.csv` for the CEM pipeline at github.com/holoros/fia-cem-maine

See `docs/PERSEUS_handoff.md` in the source repository for the cross model orientation guide.
