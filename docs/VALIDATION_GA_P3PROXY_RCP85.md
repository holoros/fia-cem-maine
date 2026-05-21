# GA RCP 85 production run validation

*Generated 2026-05-21 13:13 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260519_rcp85_wear_p3hindcast*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,326.50 | [1,000.00, 1,400.00] | PASS |
| Per acre BA (sqft/ac) | 67.70 | [50.00, 70.00] | PASS |
| Per acre carbon (kg/ac) | 35,274.90 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 496.70 | [400.00, 540.00] | PASS |
| Harvest rate (%) | 9.90 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 32.90 | [25.00, 36.00] | PASS |
| Statewide total carbon (TgC) | 396.81 | [330.00, 500.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 5.62 | [3.00, 7.00] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,326 cuft/ac
- Per acre BA: 67.7 sqft/ac
- Per acre carbon: 35,275 kg/ac
- Per acre TPA: 497
- Harvest rate: 9.9 %
- Statewide total volume: 32.9 Bcuft (assumes 24.8 M ac forest area)
- Statewide total carbon: 397 TgC
- gr_ratio cycle 1 BAU: 5.6190

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_econ_l7b)

| Metric | GA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,326.5 | 1,521.8 | -12.8 |
| Per acre BA (sqft/ac) | 67.7 | 89.2 | -24.1 |
| Per acre carbon (kg/ac) | 35,274.9 | 43,717.9 | -19.3 |
| Per acre TPA | 496.7 | 743.0 | -33.1 |
| Harvest rate (%) | 9.9 | 8.8 | 12.5 |
| Statewide vol (Bcuft) | 32.9 | 26.8 | 22.8 |
| Statewide carbon (TgC) | 396.8 | 769.4 | -48.4 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 56448 | 1,289.4 | 0.100 |
| 10 | USDA Forest Service | 2755 | 1,762.3 | 0.094 |
| 30 | State and local | 2644 | 1,514.1 | 0.101 |
| 20 | Other federal | 1178 | 1,707.7 | 0.077 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
