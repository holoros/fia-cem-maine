# WA RCP 45 production run validation

*Generated 2026-05-15 20:28 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/WA_20260510_rcp45_wear_p1*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 3,132.60 | [2,700.00, 3,300.00] | PASS |
| Per acre BA (sqft/ac) | 109.90 | [95.00, 115.00] | PASS |
| Per acre carbon (kg/ac) | 62,569.10 | [55,000.00, 65,000.00] | PASS |
| Per acre TPA | 340.50 | [280.00, 380.00] | PASS |
| Harvest rate (%) | 9.80 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 68.92 | [55.00, 80.00] | PASS |
| Statewide total carbon (TgC) | 624.38 | [500.00, 800.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 3,133 cuft/ac
- Per acre BA: 109.9 sqft/ac
- Per acre carbon: 62,569 kg/ac
- Per acre TPA: 340
- Harvest rate: 9.8 %
- Statewide total volume: 68.9 Bcuft (assumes 22 M ac forest area)
- Statewide total carbon: 624 TgC
- gr_ratio cycle 1 BAU: 0.0120

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_r21)

| Metric | WA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 3,132.6 | 1,532.9 | 104.4 |
| Per acre BA (sqft/ac) | 109.9 | 89.5 | 22.8 |
| Per acre carbon (kg/ac) | 62,569.1 | 43,970.3 | 42.3 |
| Per acre TPA | 340.5 | 741.5 | -54.1 |
| Harvest rate (%) | 9.8 | 8.9 | 10.1 |
| Statewide vol (Bcuft) | 68.9 | 27.0 | 155.4 |
| Statewide carbon (TgC) | 624.4 | 773.9 | -19.3 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 10 | USDA Forest Service | 19277 | 3,264.3 | 0.100 |
| 40 | Private (NIPF + industrial) | 5716 | 2,508.4 | 0.092 |
| 30 | State and local | 1376 | 3,956.8 | 0.096 |
| 20 | Other federal | 1237 | 2,923.3 | 0.093 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
