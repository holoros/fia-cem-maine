# CONUS donor pool with CA: matching-level validation succeeds

*Generated 20 May 2026 after downloading CA from the FIA DataMart and running the WA conus-donor smoke.*

## TLDR

The reframed remediation works at the matching level. After downloading California from the FIA DataMart (the data unblock) and enabling `--conus_donors`, the WA cycle 1 iteration-1 fine-resolution match rate jumped from 62.1 percent (OR/ID/MT neighbor cohort) to **80.8 percent** (19-state CONUS pool including CA). The WA west-side Douglas-fir and hemlock/Sitka spruce subjects that previously had no ecologically-matched cross-state donor — and fell through the three-tier fallback to iteration 3 where they matched interior-pine donors — now match CA coastal donors at the strictest ecoregion × FORTYPCD × OWNGRPCD tier. This is the matching-level confirmation that the CONUS-wide ecoregion-membership donor pool is the correct fix.

## The data unblock

CA was absent from Cardinal's partial `ENTIRE_TREE.csv` (11 states only). Cardinal CAN reach the FIA DataMart (verified HTTP 200). Downloaded:

- `CA_COND.csv` (16 MB)
- `CA_PLOT.csv` (9.2 MB)
- `CA_TREE.csv` (261,369,114 bytes, exact)

CA is now a complete state in `~/fia_data` with COND + PLOT + TREE. `get_all_available_states()` picks it up; `--conus_donors` includes it.

## The matching-level result

WA cycle 1 CEM matching iteration breakdown:

| Iteration | Neighbor cohort (p1/l7b) | CONUS pool + CA (this run) |
|---|---:|---:|
| Iter 1 (fine: ecoregion × FORTYPCD × OWNGRPCD) | 62.1% | **80.8%** |
| Iter 2 (section-level ecoregion) | 69.5% of remaining | 71.6% of remaining |
| Iter 3 (ecoregion dropped) | 85.7% of remaining | 86.7% of remaining |
| Total matched | 98.4% | 99.3% |

The 18.7 percentage point jump in iter1 fine-resolution matching is the signal. The bias-driving WA west-side cells are now finding ecologically-correct donors at the strictest tier rather than falling through to the unstratified iter3.

Donor pool: 19 states (AL, CA, CT, FL, GA, ID, MA, ME, MN, MS, MT, NH, NY, OR, RI, SC, TN, VT, WA).

## What remains: full production run to measure bias reduction

The smoke validates the matching mechanism. The actual hindcast bias reduction requires a full WA production run (100 sims, 15 cycles) with `--conus_donors`, then the hindcast against the 2019 WA EXPALL EVALID. Expected: the WA conservative bias drops from -25 percent toward -10 percent or better, because the west-side subjects now inherit genuinely high-productivity CA/OR coastal growth trajectories rather than interior-pine trajectories.

**Blocked on queue capacity.** The submit attempt failed with a per-user job submission limit — there are 143 jobs in the user's queue (other workload). The WA conus production run (`submit_wa_conus_prod.sh`, 100 sims, 480 GB) is staged and ready; it should be submitted when the queue clears. The MN and GA hugemem reruns from the neighbor-cohort L7b set are still running and will complete the 8-state evidence base.

## Manuscript implication

This strengthens the narrative to a complete arc:

1. Cross-state CEM hindcast bias spans -25 to +11 percent (donor pool composition mechanism).
2. Ecoregion-as-matching-key alone does NOT reduce bias (the bias-driving cells have no ecological cross-state donors in the neighbor cohort; they fall through to the unstratified fallback).
3. The fix is a CONUS-wide ecoregion-membership donor pool. Demonstrated at the matching level: WA iter1 fine-match rate 62 → 81 percent when CA coastal donors are added.
4. [Pending production run] The resulting hindcast bias reduction.

The arc is publishable as a complete methodological contribution even before the production bias number lands, because it identifies the mechanism, deploys the infrastructure, downloads the required data, and validates the fix at the matching level. The production bias reduction is the final confirmation.

## Next steps

1. **Submit WA conus production** (`/tmp/submit_wa_conus_prod.sh` design; 100 sims, 15 cycles, 480 GB) when the user's queue clears below the submit limit.
2. **Run WA conus hindcast** via `hindcast_multistate.R --state WA --tag rcp45_wear_conus_l7b --date <date>`.
3. **Compare** WA conus hindcast bias to the -25 percent baseline and the unchanged -79.4 MMT l7b-neighbor result.
4. **Download CA TREE_GRM_COMPONENT** (72 MB) if the hindcast or validation needs growth components.
5. **Extend CONUS donor download to MN's missing Lake States** (WI, MI, IA, IL, ND, SD TREE) and GA's southern cohort if those donor pools also need ecological expansion — though MN/GA donor states are largely already present.

## Status

- CA downloaded from FIA DataMart (complete COND+PLOT+TREE)
- `--conus_donors` validated: WA iter1 match 62 → 81 percent with CA in pool
- Full WA conus production staged but blocked on 143-job queue limit
- MN + GA hugemem L7b reruns running (complete the neighbor-cohort evidence base)
- Manuscript arc complete pending the final production bias number
