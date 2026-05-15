# MN RCP 45 production run validation

*Generated 2026-05-15 17:12 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/MN_20260510_rcp45_wear_p1*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,240.70 | [1,050.00, 1,450.00] | PASS |
| Per acre BA (sqft/ac) | 68.70 | [60.00, 80.00] | PASS |
| Per acre carbon (kg/ac) | 33,650.20 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 543.30 | [450.00, 650.00] | PASS |
| Harvest rate (%) | 9.90 | [8.00, 15.00] | PASS |
| Statewide total volume (Bcuft) | 21.59 | [18.00, 32.00] | PASS |
| Statewide total carbon (TgC) | 585.51 | [550.00, 800.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,241 cuft/ac
- Per acre BA: 68.7 sqft/ac
- Per acre carbon: 33,650 kg/ac
- Per acre TPA: 543
- Harvest rate: 9.9 %
- Statewide total volume: 21.6 Bcuft (assumes 17.4 M ac forest area)
- Statewide total carbon: 586 TgC
- gr_ratio cycle 1 BAU: 0.0070

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_r21)

| Metric | MN | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,240.7 | 1,532.9 | -19.1 |
| Per acre BA (sqft/ac) | 68.7 | 89.5 | -23.2 |
| Per acre carbon (kg/ac) | 33,650.2 | 43,970.3 | -23.5 |
| Per acre TPA | 543.3 | 741.5 | -26.7 |
| Harvest rate (%) | 9.9 | 8.9 | 11.2 |
| Statewide vol (Bcuft) | 21.6 | 27.0 | -20.0 |
| Statewide carbon (TgC) | 585.5 | 773.9 | -24.3 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 47173 | 1,261.3 | 0.099 |
| 30 | State and local | 20949 | 1,081.1 | 0.099 |
| 10 | USDA Forest Service | 8932 | 1,489.1 | 0.101 |
| 20 | Other federal | 200 | 1,074.3 | 0.074 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
