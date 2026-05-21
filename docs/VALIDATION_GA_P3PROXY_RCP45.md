# GA RCP 45 production run validation

*Generated 2026-05-21 13:09 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260519_rcp45_wear_p3hindcast*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,324.00 | [1,000.00, 1,400.00] | PASS |
| Per acre BA (sqft/ac) | 67.50 | [50.00, 70.00] | PASS |
| Per acre carbon (kg/ac) | 35,208.10 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 496.70 | [400.00, 540.00] | PASS |
| Harvest rate (%) | 9.90 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 32.84 | [25.00, 36.00] | PASS |
| Statewide total carbon (TgC) | 396.06 | [330.00, 500.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 5.62 | [3.00, 7.00] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,324 cuft/ac
- Per acre BA: 67.5 sqft/ac
- Per acre carbon: 35,208 kg/ac
- Per acre TPA: 497
- Harvest rate: 9.9 %
- Statewide total volume: 32.8 Bcuft (assumes 24.8 M ac forest area)
- Statewide total carbon: 396 TgC
- gr_ratio cycle 1 BAU: 5.6190

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_econ_l7b)

| Metric | GA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,324.0 | 1,521.8 | -13.0 |
| Per acre BA (sqft/ac) | 67.5 | 89.2 | -24.3 |
| Per acre carbon (kg/ac) | 35,208.1 | 43,717.9 | -19.5 |
| Per acre TPA | 496.7 | 743.0 | -33.1 |
| Harvest rate (%) | 9.9 | 8.8 | 12.5 |
| Statewide vol (Bcuft) | 32.8 | 26.8 | 22.6 |
| Statewide carbon (TgC) | 396.1 | 769.4 | -48.5 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 56448 | 1,286.9 | 0.100 |
| 10 | USDA Forest Service | 2755 | 1,759.7 | 0.094 |
| 30 | State and local | 2644 | 1,511.3 | 0.101 |
| 20 | Other federal | 1178 | 1,704.5 | 0.077 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
