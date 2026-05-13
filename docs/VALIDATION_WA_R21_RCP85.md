# WA RCP 85 production run validation

*Generated 2026-05-11 16:00 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/WA_20260510_rcp85_wear_p1*

**Overall: REVIEW (one or two flagged; not blocking).** 6 of 8 checks passed, 2 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 3,136.30 | [2,700.00, 3,300.00] | PASS |
| Per acre BA (sqft/ac) | 110.00 | [95.00, 115.00] | PASS |
| Per acre carbon (kg/ac) | 62,642.40 | [55,000.00, 65,000.00] | PASS |
| Per acre TPA | 340.50 | [280.00, 380.00] | PASS |
| Harvest rate (%) | 9.80 | [13.00, 20.00] | FLAG |
| Statewide total volume (Bcuft) | 69.00 | [55.00, 80.00] | PASS |
| Statewide total carbon (TgC) | 1,378.13 | [900.00, 1,300.00] | FLAG |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 3,136 cuft/ac
- Per acre BA: 110.0 sqft/ac
- Per acre carbon: 62,642 kg/ac
- Per acre TPA: 340
- Harvest rate: 9.8 %
- Statewide total volume: 69.0 Bcuft (assumes 22 M ac forest area)
- Statewide total carbon: 1,378 TgC
- gr_ratio cycle 1 BAU: 0.0120

## Cross state deltas vs ME reference (rcp85_hadgem2_wear_r21)

| Metric | WA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 3,136.3 | 1,542.1 | 103.4 |
| Per acre BA (sqft/ac) | 110.0 | 90.0 | 22.2 |
| Per acre carbon (kg/ac) | 62,642.4 | 44,240.1 | 41.6 |
| Per acre TPA | 340.5 | 741.5 | -54.1 |
| Harvest rate (%) | 9.8 | 8.9 | 10.1 |
| Statewide vol (Bcuft) | 69.0 | 27.1 | 154.2 |
| Statewide carbon (TgC) | 1,378.1 | 778.6 | 77.0 |

## Per ownership distribution

Owner distribution unavailable from per_plot RDS. Inspect schema manually.

## Flags and follow ups

- **Harvest rate (%)**: 9.80, outside bounds [13.00, 20.00]. Investigate.
- **Statewide total carbon (TgC)**: 1,378.13, outside bounds [900.00, 1,300.00]. Investigate.
