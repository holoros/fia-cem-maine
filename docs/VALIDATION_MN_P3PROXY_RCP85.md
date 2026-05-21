# MN RCP 85 production run validation

*Generated 2026-05-21 13:06 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/MN_20260520_rcp85_wear_p3hindcast*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,240.80 | [1,050.00, 1,450.00] | PASS |
| Per acre BA (sqft/ac) | 68.90 | [60.00, 80.00] | PASS |
| Per acre carbon (kg/ac) | 33,682.50 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 546.80 | [450.00, 650.00] | PASS |
| Harvest rate (%) | 10.00 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 21.59 | [18.00, 32.00] | PASS |
| Statewide total carbon (TgC) | 265.84 | [180.00, 320.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 3.94 | [3.00, 7.00] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,241 cuft/ac
- Per acre BA: 68.9 sqft/ac
- Per acre carbon: 33,682 kg/ac
- Per acre TPA: 547
- Harvest rate: 10.0 %
- Statewide total volume: 21.6 Bcuft (assumes 17.4 M ac forest area)
- Statewide total carbon: 266 TgC
- gr_ratio cycle 1 BAU: 3.9410

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_econ_l7b)

| Metric | MN | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,240.8 | 1,521.8 | -18.5 |
| Per acre BA (sqft/ac) | 68.9 | 89.2 | -22.8 |
| Per acre carbon (kg/ac) | 33,682.5 | 43,717.9 | -23.0 |
| Per acre TPA | 546.8 | 743.0 | -26.4 |
| Harvest rate (%) | 10.0 | 8.8 | 13.6 |
| Statewide vol (Bcuft) | 21.6 | 26.8 | -19.4 |
| Statewide carbon (TgC) | 265.8 | 769.4 | -65.5 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 34667 | 1,263.8 | 0.099 |
| 30 | State and local | 14330 | 1,075.2 | 0.100 |
| 10 | USDA Forest Service | 6200 | 1,488.5 | 0.102 |
| 20 | Other federal | 139 | 1,068.7 | 0.062 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
