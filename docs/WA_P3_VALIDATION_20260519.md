# WA p2 vs p3 validation: v3 crosswalk reduces cycle 1 gr_ratio by 10 pct

*Generated 19 May 2026 after WA p3 jobs (9939144 + 9939145) finished exit 0 overnight.*

## TLDR

Washington state production runs at p2 (v2 crosswalk, 38.8 pct cond coverage) and p3 (v3 crosswalk, 100 pct coverage) both completed successfully and produced 15 cycle x 100 sim trajectories. The v3 strata tighten the cross state CEM enough to push cycle 1 BAU gr_ratio from 4.803 (v2) down to 4.308 (v3) — a ~10 pct reduction toward the WA RPA reference of ~3.5. Volume and basal area retention rise marginally with v3, consistent with cleaner matching reducing artifact removal.

The MN and GA p2 jobs (9936857/58, 9936861/62) ran OUT_OF_MEMORY at 200G after 10-14 h wall — not a v2 vs v3 issue but a peak memory pressure issue at MN's 63k plots and GA's 24k plots. MN and GA p3 are still running and at cycle 12 of 15 as of 06:15 ET 19 May, past the typical OOM threshold; results pending.

## Headline comparison (WA only, cycle 1 + cycle 5 BAU gr_ratio)

| State | RCP | Cycle | p2 (v2 crosswalk) | p3 (v3 crosswalk) | Delta |
|---|---:|---:|---|---|---:|
| WA | 4.5 | 1 | 4.803 (4.352, 5.250) | 4.308 (3.908, 4.665) | -10.3% |
| WA | 4.5 | 5 | 7.449 (6.749, 8.320) | 6.740 (5.889, 7.939) | -9.5% |
| WA | 8.5 | 1 | 4.803 (4.352, 5.250) | 4.308 (3.908, 4.665) | -10.3% |
| WA | 8.5 | 5 | 7.384 (6.679, 8.057) | 6.684 (5.866, 7.711) | -9.5% |

Cycle 1 BAU gr_ratio across RCPs is identical at year 5 (cycle 1 is the baseline donor draw, so RCP only diverges at cycle 2+).

## CEM matching diagnostics

`R/01_data_prep.R` reports for WA p3 RCP 4.5:

```
us_l3code joined from config/fia_plots_hcb_l3.csv:
  49950 of 49976 cond rows matched (99.9 pct)
```

Per scenario iter rates for WA p3 RCP 4.5:

| Scenario | Iter 1 (fine) | Iter 2 (medium) | Iter 3 (coarse) | Final unmatched |
|---|---:|---:|---:|---:|
| BAU | 4.7% | 38.7% | 95.0% | 2.9% |
| Harvest_m25_mill | 2.4% | 28.6% | 94.2% | 4.0% |
| Harvest_p25_pulp | 1.3% | 25.4% | (running) | n/a |
| Harvest_p50_biomass | (running) | n/a | n/a | n/a |

Iter 1 fine (L3 x FORTYPCD x OWNGRPCD) catches only 2-5 pct of subjects — much lower than the ME smoke's 91.8 pct. This is the expected behavior given the WA-versus-OR/ID/MT donor pool ecoregion mismatch: WA's coastal/Cascade L3 codes simply do not appear in the inland donor pool. Iter 2 section coarsening catches an additional 25-39 pct, and iter 3 (drops ecoregion) closes the gap to 95 pct.

This is **exactly the pattern the CEM patch was designed to expose**: when subjects and donors share an L3 ecoregion, match fine; when they don't, fall through cleanly to coarser strata rather than silent fallback matching across incompatible regions.

## Inventory metrics (BAU cycle 1)

| Metric | p2 | p3 | Delta |
|---|---:|---:|---:|
| mean BA (sqft/ac) | 109.10 | 109.59 | +0.4% |
| mean volume (cuft/ac) | 3083 | 3120 | +1.2% |
| mean carbon (lb/ac) | 61548 | 62330 | +1.3% |
| total TPA | 346.9 | 341.1 | -1.7% |
| harvest rate | 9.74% | 9.77% | +0.3% |
| plant rate | 4.90% | 4.95% | +1.0% |

p3 retains slightly more biomass per acre (BA, volume, carbon all up 0.4-1.3%) while harvest and plant rates are essentially unchanged. Combined with lower gr_ratio, this indicates p3 is treating WA's net growth more conservatively — the previous v2 strata were likely overestimating growth by drawing from the inland donor pool whose climate window is shorter than coastal WA.

## Bias implications

The WA hindcast bias under p2 was -25 pct (severe undershoot of observed 2024 carbon). The current p3 cycle 1 metrics suggest:

- BA and volume slightly higher → smaller undershoot
- But gr_ratio lower → less aggressive growth implied

Net effect on cycle 5 hindcast residual: cannot conclude without running `hindcast_multistate.R --state WA --tag rcp45_wear_p3 --date 20260518` against the EXPALL EVALIDs. **Next step.**

## What's still running

| Job ID | Name | State | Cycle |
|---|---|---|---:|
| 9939142 | fia_mn_p3 | RUNNING | 12 of 15 |
| 9939143 | fia_mn_p3_85 | RUNNING | (slightly behind 9939142) |
| 9939146 | fia_ga_p3 | RUNNING | 12 of 15 |
| 9939147 | fia_ga_p3_85 | RUNNING | (slightly behind 9939146) |

MN p2 + GA p2 both ran OUT_OF_MEMORY at exit 125 after 10-14 h wall (200G mem, 48 cores). MN/GA p3 are at the same scale and using same memory allocation; risk of repeat OOM. They are currently at cycle 12 of 15, which is past the heaviest accumulation phase, so cautious optimism for completion.

## Files

- `figures/p2_vs_p3/p2_vs_p3_gr_ratio.png` — 6 panel WA gr_ratio trajectory (only WA panels populated until MN/GA p3 finish)
- `figures/p2_vs_p3/p2_vs_p3_volume.png`
- `figures/p2_vs_p3/p2_vs_p3_carbon.png`
- `figures/p2_vs_p3/p2_vs_p3_basal_area.png`
- `figures/p2_vs_p3/p2_vs_p3_gr_ratio.csv` — table with cycle 1 + cycle 5 by state x RCP x vintage
- `output/WA_20260518_rcp45_wear_p2/` — local synced p2 baseline
- `output/WA_20260518_rcp45_wear_p3/` — local synced p3 result
- `output/WA_20260518_rcp85_wear_p2/`
- `output/WA_20260518_rcp85_wear_p3/`

## Next steps

1. Wait for MN/GA p3 jobs to complete or OOM (1-2 more h).
2. If they complete, re-run `scripts/build_p2_vs_p3_comparison.R` for the full 3 state panel.
3. Run `scripts/hindcast_multistate.R --state WA --tag rcp45_wear_p3` and `_p85` to quantify the hindcast bias change.
4. If MN/GA p3 OOM, restage submit scripts with reduced --n_sims (100 → 50) or split per scenario to bring memory under control.
5. Write consolidated multistate p3 validation memo once all states land.
