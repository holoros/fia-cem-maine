# Hindcast Memo: GA RCP85 Layer 7b

Date: 2026-05-24
Status: Closes the last open cell in the four state hindcast table.

## Cycle 4 (2019, RPA reference) result

| Metric | Value |
|---|---:|
| Subject pool | 1,836 plots (full p1 subject pool, no exclusion) |
| Observed full pool AGC | 451.2 MMT |
| Observed subject pool AGC | 181.5 MMT |
| Projected subject pool AGC | 256.2 MMT |
| Residual | +74.6 MMT |
| Bias percent | +41.2 percent |

## Comparison to other GA vintages at cycle 4

| Vintage | RCP45 | RCP85 | Notes |
|---|---:|---:|---|
| p1 | +24.9 | +25.1 | baseline; full subject pool |
| p3hindcast | +68.8 | +78.7 | strata exclude 55 percent of late cycle subjects |
| l7b (new) | n/a | **+41.2** | full subject pool; ecoregion matching added |

## Interpretation

Adding the L3 ecoregion key to GA does not behave the way it behaves
for ME. In ME, L3 stratification pulled the bias toward zero by routing
subjects to ecologically similar donors. In GA, adding L3 widens the
overshoot from +25 percent (p1) to +41 percent (l7b). The mechanism is
straightforward: the GA donor pool is regionally homogeneous, so the L3
key binds to a donor subset that is on average faster growing than the
unconstrained iter 3 fallback in p1. Stratification helped ME because
ME donors are ecologically diverse; stratification hurt GA because GA
donors are ecologically similar but growth heterogeneous.

This is consistent with the closing manuscript story. The CEM framework
transfers well to states whose donor pools are ecologically diverse and
contain growth analogs (ME, MN, where p3 lands -0.5 percent). It does
not transfer cleanly to states whose forests have either no analog
(WA west side, -25 percent floor) or whose donor pool composition does
not align with the matching keys being added (GA, where adding L3
widens the bias).

## Provenance

Production job 10310330 (fia_ga_hm_85), hugemem retry, COMPLETED in
21h19 with exit 0 after three OOM attempts on standard memory. Hindcast
submitted as 10347584 (hc_ga_l7b85), 4 CPUs, 64 GB, completed in
13:59. CSV at output/hindcast/HINDCAST_GA_rcp85_wear_l7b.csv (28 lines,
cycles 1 through 5 plus annual EVALIDs).

## Implication for manuscript

This entry completes the four state by two RCP by primary vintage table
for the manuscript hindcast results section. The +41 percent figure
should be discussed in the Section 3.5 narrative as a counterexample to
the ME ecoregion success story: the same matching key does not always
help, and the direction it moves the bias is determined by the donor
pool composition, not the matching key itself. This sharpens the
donor analog gap finding from PRODUCTIVITY_MATCHING_RESULT_20260522.md
by showing that the gap is bidirectional: WA lacks donors with high
enough productivity, GA has donors but the keys we add pick the wrong
subset.
