# WA RCP 4.5 production run validation (job 9327153)

*Generated 2026-05-11 11:02 EDT from /users/PUOM0008/crsfaaron/fia_cem_projections/output/WA_20260510_rcp45_wear_p1*

**Overall: FAIL (multiple flags or missing data).** 5 of 8 checks passed, 3 flagged, 0 missing.

## Sanity bound checks (EVALIDator + smoke baseline)

| Check | Value | Bounds | Status |
|---|---:|---|:---:|
| Per acre volume (cuft/ac) | 3,132.60 | [2,700.00, 3,300.00] | PASS |
| Per acre BA (sqft/ac) | 109.90 | [95.00, 115.00] | PASS |
| Per acre carbon (kg/ac) | 62,569.10 | [55,000.00, 65,000.00] | PASS |
| Per acre TPA | 340.50 | [280.00, 380.00] | PASS |
| Harvest rate (%) | 9.80 | [13.00, 20.00] | FLAG |
| Statewide total volume (Bcuft) | 68.92 | [55.00, 80.00] | PASS |
| Statewide total carbon (TgC) | 1,376.52 | [900.00, 1,300.00] | FLAG |
| gr_ratio cycle 1 BAU (post L1) | 0.01 | [0.00, 0.01] | FLAG |

## Headline numbers, cycle 1 BAU baseline

- Per acre volume: 3,133 cuft/ac
- Per acre BA: 109.9 sqft/ac
- Per acre carbon: 62,569 kg/ac
- Per acre TPA: 340
- Harvest rate: 9.8 %
- Statewide total volume: 68.9 Bcuft (forest area assumed 22 M ac)
- Statewide total carbon: 1,377 TgC
- gr_ratio cycle 1 BAU: 0.0120

## Cross state deltas vs ME r21 RCP 4.5 baseline

| Metric | WA | ME r21 | Delta (%) |
|---|---:|---:|---:|
| Per acre vol (cuft/ac) | 3,132.6 | 1,532.9 | 104.4 |
| Per acre BA (sqft/ac) | 109.9 | 89.5 | 22.8 |
| Per acre carbon (kg/ac) | 62,569.1 | 43,970.3 | 42.3 |
| Per acre TPA | 340.5 | 741.5 | -54.1 |
| Harvest rate (%) | 9.8 | 8.9 | 10.1 |
| Statewide vol (Bcuft) | 68.9 | 27.0 | 155.4 |
| Statewide carbon (TgC) | 1,376.5 | 773.9 | 77.9 |

Expected pattern: WA per acre volume substantially higher than ME (Pacific NW conifer vs Northern mixed forest); harvest rate higher; TPA lower (larger average tree size in WA).

## Per ownership distribution

Owner distribution could not be computed from per_plot_projections.rds (missing owner_class or harvest volume columns). Inspect the RDS schema manually.

## Flags and follow ups

- **Harvest rate (%)**: 9.80, outside bounds [13.00, 20.00]. Investigate before propagating WA to manuscript tables.
- **Statewide total carbon (TgC)**: 1,376.52, outside bounds [900.00, 1,300.00]. Investigate before propagating WA to manuscript tables.
- **gr_ratio cycle 1 BAU (post L1)**: 0.01, outside bounds [0.00, 0.01]. Investigate before propagating WA to manuscript tables.

## Next actions

1. If status PASS, copy WA outputs to local repo: `rsync av crsfaaron@cardinal.osc.edu:fia_cem_projections/output/WA_20260510_rcp45_wear_p1/ output/WA_20260510_rcp45_wear_p1/`
2. Run the template against GA RCP 4.5 (job 9327155) once it lands: `Rscript scripts/validate_template.R --state GA --rcp 45 --tag rcp45_wear_p1`
3. Run the template against MN RCP 4.5 (job 9327152) once it lands.
4. Repeat for the three RCP 8.5 runs (jobs 9327550, 9327551, 9327552).
5. After all six pass, build the dual RCP comparison figures.
