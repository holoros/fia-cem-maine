# GA RCP 45 production run validation

*Generated 2026-05-15 20:58 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260510_rcp45_wear_p1*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,325.50 | [1,000.00, 1,400.00] | PASS |
| Per acre BA (sqft/ac) | 67.40 | [50.00, 70.00] | PASS |
| Per acre carbon (kg/ac) | 35,214.20 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 497.70 | [400.00, 540.00] | PASS |
| Harvest rate (%) | 9.90 | [9.00, 18.00] | PASS |
| Statewide total volume (Bcuft) | 32.87 | [25.00, 36.00] | PASS |
| Statewide total carbon (TgC) | 396.13 | [330.00, 500.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,326 cuft/ac
- Per acre BA: 67.4 sqft/ac
- Per acre carbon: 35,214 kg/ac
- Per acre TPA: 498
- Harvest rate: 9.9 %
- Statewide total volume: 32.9 Bcuft (assumes 24.8 M ac forest area)
- Statewide total carbon: 396 TgC
- gr_ratio cycle 1 BAU: 0.0100

## Cross state deltas vs ME reference (rcp45_hadgem2_wear_r21)

| Metric | GA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,325.5 | 1,532.9 | -13.5 |
| Per acre BA (sqft/ac) | 67.4 | 89.5 | -24.7 |
| Per acre carbon (kg/ac) | 35,214.2 | 43,970.3 | -19.9 |
| Per acre TPA | 497.7 | 741.5 | -32.9 |
| Harvest rate (%) | 9.9 | 8.9 | 11.2 |
| Statewide vol (Bcuft) | 32.9 | 27.0 | 21.8 |
| Statewide carbon (TgC) | 396.1 | 773.9 | -48.8 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 80406 | 1,290.7 | 0.100 |
| 10 | USDA Forest Service | 4082 | 1,770.5 | 0.093 |
| 30 | State and local | 3902 | 1,510.5 | 0.108 |
| 20 | Other federal | 1730 | 1,723.0 | 0.085 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
