# GA RCP 85 production run validation

*Generated 2026-05-13 06:07 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260510_rcp85_wear_p1*

**Overall: REVIEW (one or two flagged; not blocking).** 6 of 8 checks passed, 2 flagged, 0 missing.

## Sanity bound checks

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 1,328.00 | [1,000.00, 1,400.00] | PASS |
| Per acre BA (sqft/ac) | 67.60 | [50.00, 70.00] | PASS |
| Per acre carbon (kg/ac) | 35,281.10 | [28,000.00, 38,000.00] | PASS |
| Per acre TPA | 497.70 | [400.00, 540.00] | PASS |
| Harvest rate (%) | 9.90 | [16.00, 24.00] | FLAG |
| Statewide total volume (Bcuft) | 32.93 | [25.00, 36.00] | PASS |
| Statewide total carbon (TgC) | 874.97 | [550.00, 850.00] | FLAG |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | PASS |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 1,328 cuft/ac
- Per acre BA: 67.6 sqft/ac
- Per acre carbon: 35,281 kg/ac
- Per acre TPA: 498
- Harvest rate: 9.9 %
- Statewide total volume: 32.9 Bcuft (assumes 24.8 M ac forest area)
- Statewide total carbon: 875 TgC
- gr_ratio cycle 1 BAU: 0.0100

## Cross state deltas vs ME reference (rcp85_hadgem2_wear_r21)

| Metric | GA | ME | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 1,328.0 | 1,542.1 | -13.9 |
| Per acre BA (sqft/ac) | 67.6 | 90.0 | -24.9 |
| Per acre carbon (kg/ac) | 35,281.1 | 44,240.1 | -20.3 |
| Per acre TPA | 497.7 | 741.5 | -32.9 |
| Harvest rate (%) | 9.9 | 8.9 | 11.2 |
| Statewide vol (Bcuft) | 32.9 | 27.1 | 21.3 |
| Statewide carbon (TgC) | 875.0 | 778.6 | 12.4 |

## Per ownership distribution

Owner distribution unavailable from per_plot RDS. Inspect schema manually.

## Flags and follow ups

- **Harvest rate (%)**: 9.90, outside bounds [16.00, 24.00]. Investigate.
- **Statewide total carbon (TgC)**: 874.97, outside bounds [550.00, 850.00]. Investigate.
