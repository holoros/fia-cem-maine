# HCB x L3 crosswalk v3: 1 row per PLT_CN, 100% cond coverage

*Generated 18 May 2026 after SLURM 9938372 finished exit 0 in ~2 minutes.*

## TLDR

v3 replaces the v2 strategy of one row per (STATECD, UNITCD, COUNTYCD, PLOT) at slice_max(INVYR) with one row per PLT_CN across every measurement year. Coverage of cond_full's PLT_CN column rose from 38.8 percent (v2) to 100.0 percent (v3) across the 21-state subject + donor pool. This was the documented root cause of the Layer 8b iter 2 section-coarsening 0 percent match anomaly: subjects had real us_l3code while donors not in the slice_max set defaulted to NA on the R/01 left join, so the CEM key never aligned.

## Diagnosis recap

Pre-v3 evidence chain:

1. **Layer 8b smoke (SLURM 9914786)** matched 99.7 percent of subjects but the iter-by-iter breakdown showed iter 1 (fine) at 91.8 percent and iter 3 (coarse) at 90.6 percent — yet iter 2 (medium, section coarsening) caught only 64.8 percent of the iter 1 remainder.
2. **r01 left join probe** confirmed only ~38 percent of cond_full PLT_CNs found a crosswalk row.
3. **Cell-size diagnostic** in CEM_3WAY_STRATIFICATION_20260517.md showed sub-cells were healthy when both sides had real us_l3code — the bottleneck was the join, not the strata.
4. **Final probe** (v3 validation):
   - cond rows in 21 states: 1,065,363
   - In v2 crosswalk: 413,398 (38.8 percent)
   - In v3 crosswalk: 1,064,959 (100.0 percent)

## Patch summary

`scripts/build_hcb_l3_crosswalk_v3.R`:

1. **Removed** `slice_max(INVYR)` in the per-state worker.
2. **Added** a unique plot identity table `(STATECD, UNITCD, COUNTYCD, PLOT)` with median(LAT) and median(LON) per identity (robust to occasional FIA coordinate jitter).
3. **HCB raster extract and L3 polygon st_join run once per identity**, not once per measurement. LAT/LON do not move across remeasurements so this is safe.
4. **Broadcast** the spatial attributes (hcb_class, us_l3code, us_l3name) to every PLT_CN sharing the identity via left_join on the plot identity columns.
5. **OWNCD/FORTYPCD** remain per-PLT_CN via the majority-condition join (these are measurement-specific).
6. **Backup**: rename existing v2 crosswalk to `fia_plots_hcb_l3.v2_backup.csv` before writing v3.
7. **Staging directory**: output goes to `config/v3_staging/` to avoid disturbing the running p2 jobs.

## Output (SLURM 9938372)

```
Combined output: 904215 rows across 21 states

Per state, n_pltcn and pct_l3_assigned:
 STATECD n_pltcn pct_l3_assigned
       1   42475           99.1   AL
       9    2964           99.7   CT
      12   70384           94.6   FL
      13   73796           99.5   GA
      16   26876          100.0   ID
      19   41333          100.0   IA
      23   21638           98.4   ME
      25    4678           99.1   MA
      26   83558           99.1   MI
      27  172786          100.0   MN
      30   34810          100.0   MT
      33   12090           99.4   NH
      36   25372           99.4   NY
      37   55083           95.8   NC
      41   71421          100.0   OR
      44    1368           99.7   RI
      45   45090           98.6   SC
      47   31679          100.0   TN
      50    9376           99.7   VT
      53   71041           99.8   WA
      55   50967          100.0   WI
```

Total 904,215 rows vs v2's 359,471 (2.5x).

Coverage of cond_full (1,065,363 rows across 21 states):

| Crosswalk | Matched rows | Coverage |
|---|---:|---:|
| v2 | 413,398 | 38.8% |
| v3 | 1,064,959 | 100.0% |

The 404 remaining unmatched rows in v3 reflect cond rows whose PLT_CN has no row in ENTIRE_PLOT.csv (likely retired or corrupted records) — not a coverage gap in v3's logic.

## Deployment plan

The current p2 production jobs (9936857-9936862, RUNNING with v2) finished CEM matching before v3 landed, so they complete on the v2 strata. v3 takes effect on the next round (p3):

1. Wait for p2 to complete (~10 hours remaining as of 18 May 11:20 AM).
2. Swap `config/v3_staging/fia_plots_hcb_l3.csv` into `config/fia_plots_hcb_l3.csv` (with rename of v2 to `.v2_backup.csv`).
3. Submit p3 production set with v3 active. Expected: iter 1 fine match should rise above 91.8 percent because more donors now carry real us_l3code; iter 2 medium should rise from 64.8 percent because donor section codes are populated.
4. Compare p2 (v2 strata) vs p3 (v3 strata) for the bias trio: WA, MN, GA.

If p3 shows the projected bias tightening (WA -25 → -10, MN -23 → -5, GA +10 → +3-5), Layer 8c lands as the manuscript-ready CEM stratification.

## Cardinal files

- `~/fia_cem_projections/scripts/build_hcb_l3_crosswalk_v3.R` — v3 builder
- `~/fia_cem_projections/scripts/submit_crosswalk_v3.sh` — SLURM submitter
- `~/fia_cem_projections/config/v3_staging/fia_plots_hcb_l3.csv` — staged output
- `~/fia_cem_projections/config/v3_staging/fia_plots_hcb_l3_summary.csv` — per-state summary
- `~/slurm_logs/hcb_l3_v3_9938372.out` — build log

## Local files

- `scripts/build_hcb_l3_crosswalk_v3.R` — committed in ac858ab
- `scripts/submit_crosswalk_v3.sh` — committed in ac858ab
- `docs/CROSSWALK_V3_VALIDATION_20260518.md` — this memo
