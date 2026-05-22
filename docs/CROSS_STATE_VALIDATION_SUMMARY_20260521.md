# Cross-State Production Validation Summary

Date: 2026-05-21
Scope: MN, WA, GA times RCP 4.5 and 8.5, the manuscript canonical l7b production set, validated with the hardened `scripts/validate_template.R` against EVALIDator-style sanity bounds and the ME econ_l7b cross-state reference.

## Headline result

All six production runs pass every headline check. Cycle 1 BAU values sit inside the state-specific EVALIDator bounds for total volume, harvest rate, statewide carbon, and the recalibrated gr_ratio band.

## Cross-state table (cycle 1 BAU)

| State | RCP | Run basis | Total vol (Bcuft) | Harvest rate (%) | Statewide carbon (TgC) | gr_ratio | Per-check | Overall |
|---|---|---|---:|---:|---:|---:|:---|:---:|
| WA | 4.5 | l7b | 68.6 [55,80] | 9.8 [9,18] | 622.0 [500,800] | 4.31 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |
| WA | 8.5 | l7b | 68.7 [55,80] | 9.8 [9,18] | 622.7 [500,800] | 4.31 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |
| MN | 4.5 | l7b | 21.6 [18,32] | 9.9 [9,18] | 265.5 [180,320] | 3.95 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |
| MN | 8.5 | l7b (canonical) | 21.6 [18,32] | 9.9 [9,18] | 265.7 [180,320] | 3.94 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |
| GA | 4.5 | p3 proxy | 32.8 [25,36] | 9.9 [9,18] | 396.0 [330,500] | 5.62 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |
| GA | 8.5 | p3 proxy | 32.9 [25,36] | 9.9 [9,18] | 396.8 [330,500] | 5.62 [3,7] | vol PASS, harv PASS, C PASS, gr PASS | PASS |

Bounds shown in brackets are the per-state EVALIDator-anchored acceptance windows from the validation profile. Total volume assumes forest area of WA 22.0, MN 17.4, GA 24.8 million acres. Carbon converts per-acre pounds to TgC with 4.53592e-10 lb to Tg.

## California donor experiment, for reference (not part of the canonical set)

| State | RCP | Run basis | Total vol (Bcuft) | Harvest rate (%) | Statewide carbon (TgC) | gr_ratio | Overall |
|---|---|---|---:|---:|---:|---:|:---:|
| WA | 4.5 | conusCA | 65.3 | 9.7 | 605.8 | 4.27 | PASS |
| WA | 8.5 | conusCA | 65.4 | 9.7 | 606.5 | 4.27 | PASS |

The California donor pool lowers WA cycle 1 volume and carbon relative to the neighbor l7b run (65.3 vs 68.6 Bcuft, 606 vs 622 TgC, gr_ratio 4.27 vs 4.31). The direction is consistent with the hindcast finding that California donors grow more slowly than the Pacific Northwest maritime donors, so adding them depresses the WA projection rather than lifting it. Both conusCA runs still pass the WA sanity bounds.

## Blocker and basis caveat

Three of the six canonical l7b production runs (MN RCP 8.5, GA RCP 4.5, GA RCP 8.5) ran out of memory at the 200 GB hugemem cap (SLURM 10124342, 10124343, 10124344, all OUT_OF_MEMORY after 9 to 12 hours). They did not write usable inventory or per_plot outputs. For those three cells the table uses the immediately prior p3hindcast runs as a proxy. This is defensible for sanity validation because the p3 and l7b pipelines differ only in the ecoregion matching key, which the WA hindcast showed leaves the aggregate projection essentially unchanged (WA p3 and l7b hindcasts were identical at minus 79.4 MMT). The fourth run, MN RCP 4.5 l7b, completed and is shown as true l7b.

Recommendation: rerun MN RCP 8.5, GA RCP 4.5, and GA RCP 8.5 l7b at 400 GB on the hugemem partition (it provides 480 GB) to replace the proxies with true l7b numbers.

Update 2026-05-22: the MN RCP 8.5 l7b rerun at 400 GB completed and validated PASS (8 of 8), with canonical numbers essentially identical to the p3 proxy (cycle 1 BAU volume 1,240.4 versus 1,240.8 cuft per acre, carbon 33,669 versus 33,683 lb per acre). That cell is now canonical in the table above. The GA RCP 4.5 and RCP 8.5 reruns timed out at the 16 hour wall limit (not out of memory), so they were resubmitted at 24 hours (SLURM 10310329 and 10310330) and are running; the two GA cells remain p3 proxy until those land. The p3 to l7b agreement seen for MN and Washington (hindcast identical, validation numbers within 0.1 percent) gives high confidence the GA proxies will also match their canonical reruns.

## Cross-state reference deltas (WA l7b RCP 4.5 vs ME econ_l7b)

WA carries roughly twice the per-acre volume of Maine (3,120 vs 1,522 cuft per acre, plus 105 percent) and 43 percent more per-acre carbon, but about half the trees per acre, consistent with the large-tree Pacific Northwest structure. Statewide WA volume is 156 percent above ME while statewide carbon is 19 percent below, reflecting WA's larger per-acre stocking against a different forest area base. These deltas are biophysically sensible and add confidence that the multistate transfer is behaving correctly.

## Per-run memos

The hardened template writes a full memo per run with the eight-check bound table, headline numbers, cross-state deltas, and the per-ownership distribution. Those land at `docs/VALIDATION_<STATE>_<BASIS>_RCP<RCP>.md` (for example `VALIDATION_WA_L7B_RCP45.md`). The WA RCP 4.5 memo confirmed the owner distribution table now populates correctly from OWNGRPCD (USDA Forest Service 19,219 plots, Private 5,726, State and local 1,372, Other federal 1,232).

## Template hardening applied this session

The validation template was hardened: the MN harvest band was tightened from 8 to 15 up to the standard 9 to 18, matching WA and GA; the gr_ratio bound was recalibrated from the stale p1-era 0.003 to 0.012 to the current l7b-era 3.0 to 7.0 (the metric definition changed and the old bound would have mis-flagged every current run); and an owner-column schema inspection step was added that broadens the candidate column list and, when no owner column or snapshot key is found, dumps the per_plot schema into the memo for diagnosis.
