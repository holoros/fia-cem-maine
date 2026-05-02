# PERSEUS demonstration: rotation optimization with carbon constraints

**Date:** 2 May 2026
**Pipeline tag:** v4 yield curves
**Author:** A.R. Weiskittel
**Status:** internal demonstration; preliminary numbers; not for external citation

## Purpose

Demonstrate the headline use case for the FIA empirical yield curves: a Faustmann rotation optimization showing how the soil expectation value (SEV) maximizing rotation lengthens as a time-averaged carbon constraint tightens. Provides a worked example of what a downstream Woodstock LP would solve at scale, but tractable analytically on the v4 stratum-treatment fits alone.

## Method

For each of the 42 stratum × treatment fits in `yield_curves/maine_yield_curves_v4_fits.csv`, sweep rotation age R from 20 to 150 yr and compute:

1. Time-averaged above-ground biomass over the rotation, mean(AGB) for ages 1 to R, in tons per acre.
2. Merchantable volume at rotation V(R) from the v4 Chapman-Richards volume curve in cubic feet per acre.
3. Soil expectation value SEV(R) from the Faustmann formula:

> SEV(R) = (p × V(R) × exp(-rR) - R0) / (1 - exp(-rR))

For each carbon floor C_floor, find R* maximizing SEV subject to mean(AGB) ≥ C_floor. Compute the carbon shadow price as the SEV loss per additional ton of time-averaged carbon retained, where carbon equals 0.45 × AGB.

Notional Maine 2024 stumpage parameters (from MFS Stumpage Price Reports, blended species mix):

> Stumpage price: $12 per cuft (whole-stand merchantable; blended sawlog and pulp)
> Regeneration cost: $200 per acre (planting plus site prep, amortized)
> Real discount rate: 0.04 per year
> Reference carbon price: $50 per ton C for shadow-price comparison

These are deliberately notional. A real Woodstock implementation would use product-specific prices, owner-specific operational costs, and discount rates calibrated to the relevant landowner cohort.

## Results

Optimal rotation by carbon floor, untreated stratum-treatment cells only:

| Carbon floor (ton/ac) | Mean R* (yr) | SD (yr) | Range |
|---|---|---|---|
| 0 (unconstrained) | 26.0 | 6.5 | 20 to 40 |
| 30 (low) | 86.2 | 17.5 | 50 to 130 |
| 45 (medium) | 129.3 | 17.7 | 105 to 150 |
| 60 (high) | infeasible | — | — |

The 60 ton/ac floor is infeasible for nearly all untreated cells because mean AGB across the v4 untreated asymptotes is 57 ton/ac. This is a useful negative result: a Maine-wide carbon floor at 60 ton/ac time-averaged AGB cannot be achieved on most stratum-treatment combinations within a finite rotation. Reaching that floor requires unmanaged stands or strata with the highest productivity (Aspen-birch on Northern Central Zone NIPF; Northern hardwood on the same).

Mean carbon shadow prices, untreated cells only:

| Carbon floor (ton/ac) | Mean shadow price ($/ton C) |
|---|---|
| 30 | 402.82 |
| 45 | 375.27 |

Shadow prices are an order of magnitude above the $50/ton C reference. This reflects the modest SEV achievable on Maine softwood pulpwood-dominant strata under notional 2024 prices: when SEV is small, even small SEV losses divided by small carbon gains produce large per-ton costs. The numbers are plausible for the high marginal cost of pushing rotations past 80 to 100 yr on commercial industrial land. They are not estimates of a market clearing carbon price.

The qualitative finding stands: a 30 ton/ac carbon floor lengthens optimal rotations by a factor of roughly three over the unconstrained case, and a 45 ton/ac floor pushes rotations to the upper bound of the analysis. Carbon retention is achievable at scale but at substantial opportunity cost relative to revenue-maximizing rotations.

## Caveats for a real PERSEUS run

The unconstrained R* of 26 yr is shorter than typical Maine industrial rotations (35 to 70 yr) because the 4% discount rate dominates over yield curve shape on these slow-growing strata. Sensitivity to lower discount rates (2 to 3% real, more typical for landowners with carbon storage objectives) or higher early-rotation prices for pulp would shift the unconstrained R* upward.

Real Woodstock implementations would solve a multi-period LP rather than per-stratum analytical optima, allowing inter-stratum substitution, even-flow constraints across the planning horizon, and product-specific value at different ages (pulp at 40 yr, sawlog at 80 yr). The single-rotation Faustmann here brackets the answer that an LP would produce.

The harvested-treatment curves should be used carefully as separate yield strata: their `b` (recovery rate) is empirically meaningful, but the `a` is anchored to the matched untreated cell rather than free-fit. For pure regeneration scenarios with no treatment history, use the untreated curves; for managed stand projections, parameterize separately by the treatment intensity expected.

## Files

> yield_curves/faustmann_rotation_sweep.csv (1,134 rows: cell × treatment × R)
> yield_curves/faustmann_optimal_rotation.csv (168 rows: cell × treatment × C_floor)
> yield_curves/faustmann_carbon_shadow_price.csv (41 rows: shadow price by floor)
> figures/fig_faustmann_rotation_carbon.png (left: R* by forest type and floor; right: shadow price boxplot by floor)
> scripts/yc_11_faustmann.R (reproduces the above)

## Next step

Hand the v4 adapters and this Faustmann analysis to a Woodstock practitioner (Wilfried at NRCAN, or via the Remsoft user community) for a full LP implementation with realistic Maine parameters. A 30-period planning horizon, 8 to 12 forest type aggregations, and three carbon-floor scenarios would produce a publishable PERSEUS comparison paper alongside CEM, GCBM, and LANDIS runs on the same strata.
