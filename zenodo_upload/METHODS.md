# Methods: PERSEUS FIA hybrid yield-curve projections

## Growth form

Each stock response is projected with a hybrid Chapman-Richards growth curve with a
senescence decline tail:

    y(age) = A * (1 - exp(-k*age))^p * exp(-d * max(0, age - Astar))

fit per cell (forest-type group x EPA level-3 ecoregion province x ownership class), with
fallback cell -> forest type -> state. Astar is the empirical culmination age. Responses fit:
above-ground carbon, above-ground dry biomass, total stem volume, merchantable volume, and
merchantable bole biomass.

## Recalibration to the FIA longitudinal record

Age-based curves fit to a chronosequence underestimate near-term growth (space-for-time
bias). The hybrid increment is blended toward the FIA longitudinal remeasurement increment
(g_obs, fit per cell from remeasured undisturbed plots) with weight w = (Astar - age)/Astar
decaying to zero at culmination, and capped at the 95th percentile of observed standing
stock per cell. State totals are anchored to FIA design-based (EXPNS) estimates at 2025.

## Scenarios

Twelve buckets: four management regimes x three variants.

Reserve is no harvest. The three managed regimes apply an owner-typical harvest regime to a
FIADB-derived fraction of the land base, blended with the reserve trajectory:

    managed = phi * full_rotation + (1 - phi) * reserve

with phi = harvested_share (observed FIA harvest treatment share) for harvest and
conservation, and phi = planted_share (STDORGCD = 1 plantations) for intensive. FIA reserved
(RESERVCD) plots are excluded from harvest. This calibrates the managed scenarios to the
observed landscape harvest intensity (about 0.02 %/yr removal nationally; net FIA carbon
change is +1.1 %/yr), rather than a whole-landscape rotation.

Disturbance-exposed variants apply a fire/insect disturbance drag calibrated to FIA observed
disturbance frequency and severity (and v5 CONUS disturbance probability rasters).
Mortality-stressed variants apply density-dependent mortality m(C) fit from the FIA
growth-removal-mortality (GRM) record.

## Comparison engines

The PERSEUS dashboard places these FIA projections alongside an independent TreeMap 2022
pixel application of the same growth form, and CBM, FVS, and LANDIS engines, for
cross-model comparison.

## Validation

Near-term reserve growth across the five metrics is positive and tightly clustered
(1.44 to 1.77 %/yr), consistent with the FIA net carbon sink. The recalibrated reserve
trajectory matches the FIA longitudinal increment by construction and is bounded by observed
standing stock.

Full source, decision records, and methods notes:
https://github.com/holoros/perseus-forest-intelligence
