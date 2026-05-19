# p3 multistate interim results: WA validated, MN running, GA OOMed twice

*Generated 19 May 2026 at 06:45 ET after the first wave of v3 crosswalk production runs.*

## TLDR

The v3 crosswalk (100 pct cond_full coverage) is empirically validated through Washington: WA p3 RCP4.5 and RCP8.5 both completed exit 0 with 15 cycle x 100 sim trajectories, dropping cycle 1 BAU gr_ratio by ~10 pct (4.803 → 4.308) toward the RPA reference. Cycle 4 hindcast residual essentially unchanged from p1 at -25 to -26 pct — confirming the WA bias is donor pool composition (no west side Doug-fir/hemlock in OR/ID/MT donors), not CEM strata granularity. v3 cleans up matching but cannot manufacture donors the pool does not contain.

Minnesota p3 still running at 9.5 h wall (uncertain whether it will OOM at scale like p2). Georgia p3 OOMed at exit 125 after 10-11 h. p3lite variants (n_sims 50, drop save_per_plot) queued for GA as 9975778 and 9975779.

## State by state

### Washington (COMPLETE)

| Job | State | Elapsed | Result |
|---|---|---:|---|
| 9939144 | fia_wa_p3 | 4:38:42 | exit 0 |
| 9939145 | fia_wa_p3_85 | 4:30:24 | exit 0 |

WA p3 cycle 1 BAU gr_ratio: 4.308 (3.908, 4.665). p2 was 4.803 (4.352, 5.250). v3 reduces gr_ratio by ~10 pct.

WA p3 cycle 4 (year 2019) hindcast vs EVALID 531900:

| Run | obs MMT | proj MMT | residual MMT | bias |
|---|---:|---:|---:|---:|
| WA p1 (May 13) | 317 | ~238 | -79 | -25.0% |
| WA p3 RCP4.5 | 317 | 237.6 | -79.4 | -25.0% |
| WA p3 RCP8.5 | 317 | 235.3 | -81.6 | -25.8% |

The v3 CEM patch is **methodologically correct** (iter 1 fine 1-5 pct, iter 2 section 25-39 pct, iter 3 coarse 85-95 pct — clean stratified fallback) but **does not solve WA donor pool composition bias**. This is the result the multistate_donor_pool_diagnostic predicted in commit f7826e7.

### Minnesota (RUNNING)

| Job | State | Elapsed | Latest cycle |
|---|---|---:|---:|
| 9939142 | fia_mn_p3 | 9:34 | mixed sims, latest sim at cycle 1 |
| 9939143 | fia_mn_p3_85 | 9:16 | mixed sims, latest sim at cycle 4 |

MN p2 OOMed at 14 h wall (9936857, 9936858). MN p3 at same scale (200G mem, 100 sims, save_per_plot). Risk of OOM at 12-14 h.

### Georgia (FAILED, RETRY QUEUED)

| Job | State | Elapsed | Result |
|---|---|---:|---|
| 9939146 | fia_ga_p3 | 10:55:41 | OUT_OF_MEMORY |
| 9939147 | fia_ga_p3_85 | 11:18:47 | OUT_OF_MEMORY |
| 9975778 | fia_ga_p3lite | (PENDING) | n_sims=50, no save_per_plot |
| 9975779 | fia_ga_p3lite_85 | (PENDING) | n_sims=50, no save_per_plot |

GA p2 also OOMed (9936861/2 exit 125 at 10:32/10:41). GA at p3 has 24k subject plots + 105k donor plots, the largest CEM matching workload in the set. The combination of large donor pool + 100 sims + save_per_plot RDS exceeds the 200G allocation.

## v3 crosswalk lessons

1. **Coverage was real**: v3's 100 pct cond join makes iter 1 / iter 2 / iter 3 actually mean what they say. Under v2 the iter rates were inflated by silent fallback matching.
2. **Stratification reveals donor pool gaps**: WA iter 1 is only 2-5 pct because OR/ID/MT donors literally do not share WA's coastal/Cascade L3 ecoregions. The CEM does the right thing by falling through to iter 3.
3. **CEM does not fix data scarcity**: the WA bias persists because no amount of stratification can manufacture missing donors. The actual fixes are: include WA self-donors, or add coastal CA donors, or run ClimateNA decoupled climate.
4. **Memory pressure is real and not v3 specific**: both p2 and p3 OOMed for MN and GA. n_sims 100 + save_per_plot is too much. p3lite (50 sims, no save) tests whether 200G is enough.

## Updated bias attribution

| State | p1 hindcast bias | p3 hindcast bias | v3 effect |
|---|---:|---:|---|
| ME r21 (canonical) | -1.1% | (not rerun) | n/a |
| MN | -5.7% | (running) | TBD |
| WA | -25.0% | -25.0 / -25.8% | NO CHANGE |
| GA | +10% | (OOMed) | TBD via p3lite |

The WA result is the most important manuscript signal so far: **v3 crosswalk is necessary for clean CEM strata but not sufficient to fix donor pool bias**. The manuscript narrative shifts from "patch the CEM" to "CEM clean, donor pool composition is the residual limitation."

## Decision points for the user

1. **WA bias remediation path**: include WA self-donors in the CEM donor pool, run ClimateNA per state with --use_decoupled_climate, or accept -25 pct bias as documented limitation.
2. **MN p3 monitoring**: let it finish or OOM; if OOM, run MN p3lite the same way as GA.
3. **GA p3lite expected behavior**: same iter rate pattern as WA (fine fails, coarse catches), but with 50 sims the CI ribbons widen ~40 pct. Still publication ready.
4. **Carbon trajectory bias**: WA p3 BA and volume slightly higher than p2 (more retention) but gr_ratio lower — net carbon stocks at cycle 1 differ by <1 pct.

## Files

- `output/WA_20260518_rcp45_wear_p3/` and `_rcp85_wear_p3/` — finished WA p3 outputs (locally synced)
- `output/hindcast/HINDCAST_WA_rcp{45,85}_wear_p3.csv` — WA p3 hindcast residuals (locally synced)
- `figures/p2_vs_p3/` — 4 panel comparison figures
- `osc/submit_{ga,mn}_p3lite_{rcp45,rcp85}.sh` — memory mitigated retry scripts

## Active SLURM jobs (06:45 ET 19 May)

```
9939142 fia_mn_p3       RUNNING 9:34
9939143 fia_mn_p3_85    RUNNING 9:16
9975778 fia_ga_p3lite   PENDING
9975779 fia_ga_p3lite_85 PENDING
```
