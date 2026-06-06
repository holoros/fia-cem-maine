# Flag for decision: CEM managed-harvest intensity vs FIADB working fraction

**Date:** 2026-06-06
**Author:** A. Weiskittel (Cowork, autopilot)
**Status:** DECISION NEEDED before publishing CEM managed (non-reserve) forward series.
The reserve (No_harvest) scenario is unaffected and is cleared for publication.

## The discrepancy

After the ingrowth and QMD fixes, the CEM forward trajectories are internally sound, but
the managed scenarios disagree in sign with the recalibrated PERSEUS YC engine for Maine:

| engine | ME managed-harvest carbon, 75 yr | basis |
|---|---|---|
| CEM BAU (3-part fixed engine, ME smoke) | **-16%** | county harvest calibration + fixed_harvest_rate |
| PERSEUS YC managed-harvest (recalibrated) | **+27%** | FIADB harvested_share working fraction |
| CEM No_harvest (reserve) | +35% | no harvest; matches reserve expectation |

Both engines now agree on the reserve case. They diverge only where harvest is applied.

## Why

The two engines use fundamentally different harvest-intensity bases:

- **CEM BAU** uses `--fixed_harvest_rate 0.10` (10% of conditions per 5 yr cycle, ~2%/yr)
  combined with `--use_county_harvest`, which applies
  `config/maine_county_harvest_calibration.csv`. Those county rates are 0.045 to 0.12 per
  year of active-management acres over forested acres (e.g. Sagadahoc 0.12/yr, Androscoggin
  0.072/yr). Over a 5 yr cycle that touches roughly a quarter to over half of acres.
- **PERSEUS YC** uses the FIADB `harvested_share` working fraction: only about 0.8% of plots
  are cut per remeasurement (~0.16%/yr landscape-average removal). This is the recalibration
  documented in PERSEUS_yield_curve_memo.md that moved the YC managed curves from an
  implausible decline to a realistic gain.

The CEM managed scenario is therefore modeling a much heavier, county-active-management
harvest intensity than the YC landscape-average working fraction. The -16% vs +27% gap is a
direct consequence of that choice, not a residual engine bug.

## The decision

This is a modeling-intent question, not a code fix, so it is yours to make:

1. **Keep the CEM county-active-management basis** as a deliberately heavier "what active
   management does on the working land base" scenario, and present it as such alongside the
   reserve. Then the -16% is a feature, and the manuscript/PERSEUS framing should label the
   CEM managed scenario as active-management intensity, distinct from the YC landscape-average.
2. **Recalibrate the CEM BAU to the FIADB working fraction** (drop `--use_county_harvest` or
   scale the fixed rate down to the FIADB harvested_share in
   `zenodo_upload/fia_mgmt_shares_bystate.csv`) so CEM and YC managed scenarios are
   apples-to-apples. Expected effect: CEM managed carbon moves up toward the reserve, likely
   into agreement with the YC +27%.

## Recommendation

For the immediate PERSEUS publish, publish the **reserve** CEM forward series now (defensible,
agrees with YC) and hold the **managed** series until you pick option 1 or 2. If the goal is a
clean multi-engine comparison in the explorer, option 2 makes CEM and YC directly comparable;
if the goal is to show the cost of active management, option 1 is the right framing and only
needs a label. Either way the reserve line is publishable today.
