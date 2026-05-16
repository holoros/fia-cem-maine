# MN RCP 85 production run validation

*Generated 2026-05-15 20:49 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/MN_20260510_rcp85_wear_p1*

**Overall: PASS (all checks within bounds).** 8 of 8 checks passed, 0 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,241.70 | [1,050.00, 1,450.00] | PASS |
| Per acre BA (sqft/ac) | 68.80 | [60.00, 80.00] | PASS |
| Per acre carbon (kg/ac) | 33,676.60 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 543.30 | [450.00, 650.00] | PASS |
| Harvest rate (%) | 9.90 | [8.00, 15.00] | PASS |
| Statewide total volume (Bcuft) | 21.61 | [18.00, 32.00] | PASS |
| Statewide total carbon (TgC) | 265.79 | [180.00, 320.00] | PASS |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,242 cuft/ac
- Per acre BA: 68.8 sqft/ac
- Per acre carbon: 33,677 kg/ac
- Per acre TPA: 543
- Harvest rate: 9.9 %
- Statewide total volume: 21.6 Bcuft (assumes 17.4 M ac forest area)
- Statewide total carbon: 266 TgC
- gr_ratio cycle 1 BAU: 0.0070

## Cross state deltas vs ME reference (rcp85_hadgem2_wear_r21)

| Metric | MN | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,241.7 | 1,542.1 | -19.5 |
| Per acre BA (sqft/ac) | 68.8 | 90.0 | -23.6 |
| Per acre carbon (kg/ac) | 33,676.6 | 44,240.1 | -23.9 |
| Per acre TPA | 543.3 | 741.5 | -26.7 |
| Harvest rate (%) | 9.9 | 8.9 | 11.2 |
| Statewide vol (Bcuft) | 21.6 | 27.1 | -20.4 |
| Statewide carbon (TgC) | 265.8 | 778.6 | -65.9 |

## Per ownership distribution (cycle 1 BAU)

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 40 | Private (NIPF + industrial) | 47173 | 1,262.4 | 0.099 |
| 30 | State and local | 20949 | 1,081.7 | 0.099 |
| 10 | USDA Forest Service | 8932 | 1,489.7 | 0.101 |
| 20 | Other federal | 200 | 1,075.6 | 0.074 |

OWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, 20 Other federal, 30 State and local, 40 Private. HCB sub classification lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.

## Flags and follow ups

None. All sanity bounds satisfied.
