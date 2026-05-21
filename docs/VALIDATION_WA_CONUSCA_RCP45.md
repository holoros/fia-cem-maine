# WA RCP 45 production run validation

*Generated 2026-05-21 13:18 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/WA_20260521_rcp45_wear_conusCA_l7b*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 2,967.30 | [2,700.00, 3,300.00] | PASS |
| Per acre BA (sqft/ac) | 108.00 | [95.00, 115.00] | PASS |
| Per acre carbon (kg/ac) | 60,705.20 | [55,000.00, 65,000.00] | PASS |
| Per acre TPA | 334.10 | [280.00, 380.00] | PASS |
| Harvest rate (%) | 9.70 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 65.28 | [55.00, 80.00] | PASS |
| Statewide total carbon (TgC) | 605.78 | [500.00, 800.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 4.27 | [3.00, 7.00] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 2,967 cuft/ac
- Per acre BA: 108.0 sqft/ac
- Per acre carbon: 60,705 kg/ac
- Per acre TPA: 334
- Harvest rate: 9.7 %
- Statewide total volume: 65.3 Bcuft (assumes 22 M ac forest area)
- Statewide total carbon: 606 TgC
- gr_ratio cycle 1 BAU: 4.2680

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_econ_l7b)

| Metric | WA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 2,967.3 | 1,521.8 | 95.0 |
| Per acre BA (sqft/ac) | 108.0 | 89.2 | 21.1 |
| Per acre carbon (kg/ac) | 60,705.2 | 43,717.9 | 38.9 |
| Per acre TPA | 334.1 | 743.0 | -55.0 |
| Harvest rate (%) | 9.7 | 8.8 | 10.2 |
| Statewide vol (Bcuft) | 65.3 | 26.8 | 143.7 |
| Statewide carbon (TgC) | 605.8 | 769.4 | -21.3 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 10 | USDA Forest Service | 22739 | 3,209.9 | 0.101 |
| 40 | Private (NIPF + industrial) | 8974 | 2,297.4 | 0.091 |
| 20 | Other federal | 1664 | 2,384.7 | 0.088 |
| 30 | State and local | 1482 | 3,808.5 | 0.090 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
