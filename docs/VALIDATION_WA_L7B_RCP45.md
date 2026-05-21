# WA RCP 45 production run validation

*Generated 2026-05-21 12:52 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/WA_20260520_rcp45_wear_l7b*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 3,120.30 | [2,700.00, 3,300.00] | PASS |
| Per acre BA (sqft/ac) | 109.60 | [95.00, 115.00] | PASS |
| Per acre carbon (kg/ac) | 62,329.60 | [55,000.00, 65,000.00] | PASS |
| Per acre TPA | 341.10 | [280.00, 380.00] | PASS |
| Harvest rate (%) | 9.80 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 68.65 | [55.00, 80.00] | PASS |
| Statewide total carbon (TgC) | 621.99 | [500.00, 800.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 4.31 | [3.00, 7.00] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 3,120 cuft/ac
- Per acre BA: 109.6 sqft/ac
- Per acre carbon: 62,330 kg/ac
- Per acre TPA: 341
- Harvest rate: 9.8 %
- Statewide total volume: 68.6 Bcuft (assumes 22 M ac forest area)
- Statewide total carbon: 622 TgC
- gr_ratio cycle 1 BAU: 4.3080

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_econ_l7b)

| Metric | WA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 3,120.3 | 1,521.8 | 105.0 |
| Per acre BA (sqft/ac) | 109.6 | 89.2 | 22.9 |
| Per acre carbon (kg/ac) | 62,329.6 | 43,717.9 | 42.6 |
| Per acre TPA | 341.1 | 743.0 | -54.1 |
| Harvest rate (%) | 9.8 | 8.8 | 11.4 |
| Statewide vol (Bcuft) | 68.6 | 26.8 | 156.3 |
| Statewide carbon (TgC) | 622.0 | 769.4 | -19.2 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 10 | USDA Forest Service | 19219 | 3,256.8 | 0.101 |
| 40 | Private (NIPF + industrial) | 5726 | 2,498.5 | 0.089 |
| 30 | State and local | 1372 | 3,879.0 | 0.088 |
| 20 | Other federal | 1232 | 2,932.5 | 0.089 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
