# PERSEUS handoff: how to use the FIA CEM Maine v4 yield curve adapters

This README is the orientation document for downstream modelers (GCBM, LANDIS-II, CEM, Woodstock) using the cross-model adapter files generated from Maine FIA empirical chronosequence yield curves.

## What is in this repository

The `yield_curves/adapters_v4/` directory contains six files in four model-specific formats. All are derived from the same 42 stratum × treatment Chapman-Richards fits, anchored where necessary to keep harvested-stratum asymptotes plausible. The underlying fits are in `yield_curves/maine_yield_curves_v4_fits.csv` and the predicted trajectories are in `yield_curves/maine_yield_curves_v4_long.csv`.

Strata are indexed by a 4-tuple: forest type group × ecoregion × ownership × treatment. The 35 stratification cells that have at least 30 plots cover 90.5 percent of forested FIA conditions in Maine (4,547 of 5,027 plots). Treatment is binary in v4 (untreated vs harvested) based on FIA TRTCD/DSTRBCD flags, where harvested means a recorded harvest within 30 years of measurement.

## Conversion factors (used internally; documented for traceability)

> AGB tons/ac × 0.45 = carbon tons/ac
> tons/ac × 2.2417 = Mg/ha
> cuft/ac × 0.069972 = cubic meters per ha
> Jenkins below-ground / above-ground ratio = 0.22
> Jenkins component splits within above-ground: foliage 5 percent, other (branches, bark) 18 percent

## File 1: GCBM/libcbm growth curves (`gcbm_growth_v4_curves.csv`)

1,260 rows, one per (stratum × treatment × age). Ages span 5 to 150 in 5-year steps. Schema:

> classifier_set: forward-slash-separated 4-tuple (e.g. "Spruce-fir/ME_NH/Industrial/untreated"); use as the `_CLASSIFIER` key in your GCBM project
> ft_group, ecoregion, owner, treatment: parsed components if your tool prefers them separate
> age: stand age in years
> merch_vol_m3_ha: merchantable volume in cubic meters per hectare
> foliage_kgC_m2: foliage carbon in kilograms per square meter
> other_above_kgC_m2: other above-ground carbon (branches, bark) in same units
> total_above_kgC_m2: sum of foliage and other; equals 0.23 × AGB in kg C per square meter

To use in GCBM: load this CSV into your project's growth curve table, key by classifier_set, and let GCBM dispatch the per-pool decompositions through its standard CBM-CFS3 component logic. The volume and pool numbers here are point estimates from the v4 anchored fits; uncertainty is not propagated.

## File 2: LANDIS-II PnETBiomassParameters (`landis_biomass_parameters_v4.csv` and `.txt`)

42 rows in the CSV; the `.txt` is a LANDIS-style fixed-width text block ready to paste into a `BiomassParameters` section. Schema:

> cell_key: pipe-separated stratum identifier
> ft_group, ecoregion, owner, treatment: parsed
> MaxAGB_tonac: above-ground biomass asymptote (Chapman-Richards `a`) in tons/ac
> MaxAGB_MgHa: same in metric units
> BG_root_MgHa: below-ground root carbon at asymptote, computed as MaxAGB_MgHa × 0.22
> age_to_50pct_a: age at which AGB reaches 50 percent of asymptote (years)
> age_to_90pct_a: age at which AGB reaches 90 percent of asymptote (years)
> n_plots: number of FIA plots underlying the fit

For PnET-Succession parameterization: use MaxAGB_MgHa as the species-stratum maximum biomass and the age-to-percent values as inputs to your establishment probability and growth response curves. The 50 and 90 percent ages encode the recovery trajectory; harvested strata have shorter age_to_50 than untreated for the same site type, reflecting faster early growth on cleared sites.

## File 3: CEM productivity multipliers (`cem_productivity_multipliers_v4.csv`)

42 rows, designed for direct ingestion into the CEM growth multiplier in `06_projection_engine.R` of the FIA CEM Maine pipeline (this repository). Schema:

> cell_key, ft_group, ecoregion, owner, treatment: stratum 4-tuple
> asymptote_tonac: AGB asymptote in tons/ac
> prod_mult: scaling factor relative to the v4 mean asymptote (57.3 ton/ac)
> n_plots: plots underlying the fit

Use prod_mult as a per-stratum multiplier on the BRMS SDImax-based growth function. Values range roughly 0.5 to 1.5 (most cells within 0.7 to 1.3); the multiplier captures site productivity effects orthogonal to density. This is the simplest way to back-port the empirical asymptote into the CEM pipeline as an alternative or check against the existing SDImax cap.

## File 4: Woodstock YIELDS table (`woodstock_yields_v4_long.csv` and `_AGB_wide.csv`)

The long form has 1,260 rows, one per (stratum × treatment × period × age). Periods are 5-year intervals: P1 = age 5, P2 = age 10, ..., P30 = age 150. Schema:

> stratum: underscore-separated 3-tuple (forest type, ecoregion, owner)
> ft_group, ecoregion, owner, treatment: parsed
> period: 1 to 30
> age: stand age at end of period
> AGB_tonac, AGB_MgHa: above-ground biomass in two units
> Vol_m3Ha: merchantable volume in cubic meters per hectare
> CarbonMgHa: above-ground carbon in metric tons per hectare

The wide form has 42 rows (one per stratum × treatment) with 30 period columns P1 through P30, AGB in tons/ac. Period columns may not be in numeric order in the CSV due to R reshape semantics; sort them before pasting into Woodstock if order matters for your workflow.

To use in Woodstock: import the long form as a YIELDS table keyed by stratum and treatment, then define ACTIONS in your `*.aac` file referencing those yield series (e.g., a CLEARCUT action consuming the harvested stratum and producing the untreated stratum at age 0). The wide form is faster for direct paste but may need column reordering.

## Demonstration: Faustmann rotation analysis

A worked example of what the v4 curves predict for revenue-maximizing rotations under carbon constraints is in `docs/PERSEUS_demo.md` and `scripts/yc_11_faustmann.R`. Headline numbers using notional Maine 2024 stumpage:

> Unconstrained optimal rotation: 26 yr (4 percent discount rate dominates)
> 30 ton/ac time-averaged C floor: rotation lengthens to 86 yr
> 45 ton/ac floor: rotation lengthens to 129 yr
> 60 ton/ac floor: infeasible on most strata
> Mean carbon shadow price at 30 to 45 ton/ac floor: $375 to $403 per ton C

The shadow prices are notional and high because Maine softwood-dominant strata yield modest SEV under blended 2024 prices. A real LP would use product-specific pricing and yield substantially lower shadow prices on hardwood strata.

## Companion files

Beyond the four adapter formats, the repository carries:

> `scripts/yc_06_empirical_curves_v2.R`: the v2 fitter (constrained Chapman-Richards with 200x bootstrap CIs)
> `scripts/yc_07_treatment_stratified.R`: the v3 treatment dimension layer
> `scripts/yc_09_treatment_v4.R`: the v4 anchor logic
> `scripts/yc_10_adapters_v4.R`: emits the v4 adapters from the v4 fits
> `docs/FVS_WOODSTOCK_STRATEGY.md`: the original 3-stage strategy document including the FVS-NE/FVS-ACD process-driven curves path (paused on legacy fixed-width file format issues; future work)

## Citation

If you use these adapter files in a publication, please cite:

Weiskittel, A.R. (2026). FIA CEM Maine yield curve archive (v4): empirical Chapman-Richards parameterizations of forest type × ecoregion × ownership × treatment combinations across the Maine FIA plot network. github.com/holoros/fia-cem-maine.

The underlying CEM framework methodology paper (forthcoming) will provide the formal citation once published.

## Contact

aaron.weiskittel@maine.edu, Center for Research on Sustainable Forests, University of Maine.
