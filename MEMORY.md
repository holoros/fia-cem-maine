# Project Memory

*Created May 9, 2026 — last updated May 18, 2026*

## Current state (20 May 2026 6:30 AM)

**p3 multistate validation COMPLETE.** All four states have v3 production +
hindcast residuals. Three distinct outcomes:

- **MN**: clean v3 win at RPA cycle 4 (bias +6.8 -> -0.5pct).
- **WA**: v3 unchanged at -25pct (donor pool composition limit, expected).
- **GA**: v3 strata exclude 55pct of late-cycle subjects, isolating the young
  plantation cohort. Apparent bias rises (+25 -> +69pct) but reflects subject
  composition change, not projection drift.

Only loose end: MN p3hindcast RCP85 (job 10021111 RUNNING) for the symmetric
RCP8.5 hindcast comparison.

## Older context (19 May 6:50 AM)

WA p3 validated and committed (cycle 1 BAU gr_ratio 4.308 down from 4.803;
hindcast bias -25 to -26 pct ≈ unchanged from p1).
MN p3 still running at 9:40 wall (cycle 14/15 sim 84 RCP45, cycle 8/15
sim 92 RCP85 — runs CEM per scenario x sim x cycle = 7500 matchings).
GA p3 OOMed at 11h wall both runs. GA p3lite running (50 sims, no
save_per_plot) as 9975778 / 9975779; CEM matching already at iter 3 98pct.

## Older context (18 May 11:30 AM)

p2 production set RUNNING (6 jobs, v2 crosswalk, 38 pct cond_full coverage).
p3 production set QUEUED (6 jobs, v3 crosswalk, 100 pct cond_full coverage)
with --dependency=afterany on p2.

### Today's deliverables

- Diagnosed iter 2 section coarsening 0 pct match anomaly. Root cause: v2 crosswalk used `slice_max(INVYR)` per plot identity, so only 38.8 pct of cond_full's measurement specific PLT_CNs joined; donors not in v2 defaulted to NA us_l3code and the iter 2 section key never aligned.
- Built `scripts/build_hcb_l3_crosswalk_v3.R`: emits one row per PLT_CN across all measurement years. SLURM 9938372 produced 904,215 rows in ~2 min.
- Validated v3: 100.0 pct cond_full coverage vs v2's 38.8 pct.
- Swapped v3 into `config/fia_plots_hcb_l3.csv` (v2 preserved as `.v2_backup.csv`).
- Queued p3 production (6 jobs) with dependency on p2.
- Built `scripts/build_p2_vs_p3_comparison.R` for the moment p3 outputs land.

### Live jobs on Cardinal

| Job ID | Name | State | Crosswalk |
|---|---|---|---|
| 9936857 | fia_mn_p2 | RUNNING | v2 |
| 9936858 | fia_mn_p2_85 | RUNNING | v2 |
| 9936859 | fia_wa_p2 | RUNNING | v2 |
| 9936860 | fia_wa_p2_85 | RUNNING | v2 |
| 9936861 | fia_ga_p2 | RUNNING | v2 |
| 9936862 | fia_ga_p2_85 | RUNNING | v2 |
| 9939142 | fia_mn_p3 | PENDING | v3 |
| 9939143 | fia_mn_p3_85 | PENDING | v3 |
| 9939144 | fia_wa_p3 | PENDING | v3 |
| 9939145 | fia_wa_p3_85 | PENDING | v3 |
| 9939146 | fia_ga_p3 | PENDING | v3 |
| 9939147 | fia_ga_p3_85 | PENDING | v3 |

### Next session pickup checklist

1. SSH cardinal, `squeue -u crsfaaron -t COMPLETED -h` and `sacct` to confirm p2 and p3 statuses.
2. Sync output dirs locally: `MN_20260518_rcp45_wear_p2`, `MN_20260518_rcp85_wear_p2`, `WA_20260518_*_p2`, `GA_20260518_*_p2`, plus the same set with `_p3`.
3. Run `Rscript scripts/build_p2_vs_p3_comparison.R` to render 4 panel figures and the gr_ratio table.
4. Run `Rscript scripts/hindcast_multistate.R --state {MN,WA,GA} --tag rcp45_wear_p3 --date 20260518` (and rcp85) for the residual table.
5. Write `docs/P3_VALIDATION_20260518.md` synthesizing iter rates, gr_ratio cycle 1 and cycle 5, and hindcast residuals.
6. If p3 bias holds the projection (WA -10, MN -5, GA +3 to +5), the manuscript can use p3 as the primary production set.

### Key documents

- `docs/CROSSWALK_V3_VALIDATION_20260518.md` — v3 build and coverage validation
- `docs/AUTOPILOT_STATUS_20260518.md` — full session state at 11:25 AM
- `docs/CURRENT_STATE_SYNTHESIS_20260517.md` — manuscript readiness synthesis
- `docs/CEM_LAYER7_DEPLOYMENT_20260517.md` — Layer 7b deployment record
- `docs/HANDOFF_20260517_late.md` — pre v3 session handoff

### Open questions for the user

1. Manuscript framing — Option A framework validation vs Option B bias attribution methodology
2. STDORGCD plantation vs natural CEM matching for GA bias
3. ClimateNA per state run timing (manual GUI step on user side)
4. Reporting horizon for the manuscript (cycle 5 vs cycle 15)

### Repository state

- Local main: 60+ commits ahead of origin/main
- Push pending (HTTPS auth not available from this session — push from workstation with `git push origin main`)
- Latest commits: ed86a0c (p2 vs p3 comparison script), f97d165 (autopilot memo), 47ca4d4 (p3 submitters), ba8d831 (v3 validation), ac858ab (v3 build), cb7b390 (Layer 8b)

### Original relocation note

This project was moved from `~/Documents/Claude/` root into the active-projects tree on May 9, 2026 to consolidate research output tracking under a single index. Existing README, CHANGELOG, HANDOFF, and other project documentation remain authoritative.

For full project context see `README.md` or `HANDOFF.md`.
