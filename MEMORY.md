# Project Memory

*Created May 9, 2026 — last updated 26 May 2026 PM ET*

## Current state (26 May 2026)

**Project closed.** Hindcast table complete, donor analog gap (WA) and
GA cohort attribution memos in place, origin/main fully synced through
commit `9cd014f`. The manuscript revision (Sections 3.5, Discussion,
Abstract) is the only remaining work and is a writing session task,
not a Cardinal compute task. No active fia_plot_matching SLURM jobs.

GA RCP85 Layer 7b production landed (10310330 COMPLETED 21h19, exit 0),
the closing hindcast (10347584) ran in 14 minutes with cycle 4 bias of
**+41.2%**, and the cohort decomposition (10428127) localized that
overshoot to the 21-40 yr plantation cohort (1.61x mean projected AGC
vs same-age other forest types, 22.5 pct share of total cycle 4
projected AGC).

## Cardinal status snapshot (26 May 2026)

| Project | Active jobs | Status |
|---|---|---|
| fia_plot_matching | none | All loose ends closed |
| fvs-conus | cspi_v3_30mF (20h+), hg_unified_100k (14h, 85 pct sampling) | Healthy, productive |
| Disturbance | fig3regen2 (FAILED, exit 1) | Needs separate session |

The Disturbance `fig3regen2` job (10460245) failed in
`predict_vintage_lookup_v5 -> extract_treemap_attrs` with
`topht_range` evaluating to NaN, suggesting the STANDHT lookup join
returned all NA. That belongs to the Disturbance project memory, not
this one.

Quota: 334 G / 500 G (67 pct), 268k / 1M inodes. Healthy.

**Washington bias story closed.** Three independent remediation paths
(CONUS donor expansion, California donor addition, productivity matching)
all converge on the same finding: WA west side maritime Douglas fir has
no donor analog in the available FIA universe. The remedy is a model
based growth rate correction, not donor substitution. See
`docs/PRODUCTIVITY_MATCHING_RESULT_20260522.md` for the decisive memo.

### Cycle 4 (RPA reference year 2019) bias table

| State | p1 RCP45 | p1 RCP85 | p3 RCP45 | p3hindcast RCP85 | l7b RCP45 | l7b RCP85 | conusCA RCP85 | prod weak RCP45 | prod strong RCP45 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ME | n/a | n/a | n/a | n/a | +11.7% | +11.4% | n/a | n/a | n/a |
| MN | +6.8% | +6.6% | **-0.5%** | +9.1% | n/a | n/a | n/a | n/a | n/a |
| WA | -25.3% | -24.8% | -25.0% | n/a | -25.0% | -25.8% | -24.6% | -13.8% (~17% drop) | -19.6% (~48% drop) |
| GA | +24.9% | +25.1% | +68.8%* | +78.7%* | n/a | **+41.2%** | n/a | n/a | n/a |

`*` GA p3hindcast keeps only 45 percent of late cycle subjects; +69 and
+79 percent are on the selected plantation heavy subset, not the full
subject pool. GA RCP85 l7b at +41 percent retains the full subject pool
and shows the cost of adding ecoregion matching where it does not align
with the GA donor structure: bigger overshoot than the p1 baseline.

### Closing manuscript story

The multistate CEM framework transfers well to states whose forests have
donor analogs (ME, MN, GA). It fails for WA in a specific, diagnosable
way: the west side maritime forest is a high productivity outlier with
no donor analog, so no matching strategy (neighbor, CONUS, ecoregion,
productivity) can supply an appropriate donor. The paper presents
productivity matching as the diagnostic that localizes the failure to a
donor analog gap, and recommends a hybrid model correction for outlier
forests as the path forward.

## Active SLURM jobs (26 May 2026)

No active fia_plot_matching jobs. Three jobs in queue belong to other
projects: 10460201 hg_unified_100k (fvs-conus, Stan MCMC 85 pct
through 2000 iter), 10442822 cspi_v3_30mF (fvs-conus 30m raster
prediction loop, 20 h+), and 10442824 cspi_v3_ pending dependency.

Session timeline:
- 10310330 fia_ga_hm_85: COMPLETED 21h19 exit 0 (GA L7b RCP85 production)
- 10347584 hc_ga_l7b85: COMPLETED 14m exit 0 (GA RCP85 l7b hindcast)
- 10420898 ga_l7b_resid: failed module load (gdal/3.7.3 needed gcc first)
- 10420899 ga_l7b_resid: OUT_OF_MEMORY 13m at 32 G (RDS expanded past 32 G)
- 10421015 ga_l7b_resid: completed 13:46 but R script silently errored on obs_col=NA
- 10428127 ga_l7b_cohort: COMPLETED 13:39 exit 0, produced cohort decomposition outputs

## Live state of Cardinal storage

- `fia_db_WA.rds` symlink restored to baseline (STATECDs 16, 41, 53 only;
  91,169 plots; no California). The conusCA experiment used a temporary
  rebuilt `fia_db_WA_addCA.rds`; baseline was restored before May 22.
- Cardinal cleanup 21 May freed ~51 GB; output/ went from 78 GB to 31 GB.
  21 superseded directories removed, keepers and 6 in-flight jobs preserved.

## Key documents (most recent first)

- `docs/GA_L7B_DRIVERS_20260525.md` — GA +41 pct overshoot localizes to 21-40 yr plantation cohort
- `docs/HINDCAST_GA_RCP85_WEAR_L7B.md` — GA RCP85 l7b cycle 4 +41.2 pct closing memo
- `docs/SESSION_HANDOFF_20260523.md` — prior session full handoff
- `docs/PRODUCTIVITY_MATCHING_RESULT_20260522.md` — closing WA donor analog gap memo
- `docs/HINDCAST_WA_RCP{45,85}_WEAR_PRODL7B.md` and `_PRODS_L7B.md` — productivity hindcast results
- `docs/HINDCAST_WA_RCP{45,85}_WEAR_CONUSCA_L7B.md` — conusCA hindcast results
- `docs/CONUS_DONOR_NULL_RESULT_20260521.md` — diagnoses why naive --conus_donors did nothing
- `docs/HINDCAST_MN_RCP85_WEAR_P3HINDCAST.md` — the cycle 4 +9.1% MN RCP85 entry that closes the four state table
- `docs/HANDOFF_COMPREHENSIVE_20260521.md` — pre conusCA state and corrected narrative
- `docs/VALIDATION_*_L7B*.md` and `VALIDATION_*_P3PROXY_*.md` — per state systematic validation memos (May 21-22)

## Manuscript inventory

Main draft assembled (commit c1db4c6): Abstract, 1 Intro, 2 Methods, 3
Results (3.1 to 3.6), 4 Discussion, 5 Conclusion, 6 Suppl index, 7 data
and code, 8 References, 9 Acknowledgments. Supplements S1-S4, S7, S8
drafted (commit 4f5cdda). S5 (per state hindcasts) and S6 (bias
mechanism chronology) drafted (commit 9661054).

**Required revisions** before submission: Sections 3.5, Discussion, and
Abstract need updates to lead with the donor analog gap finding from the
productivity memo. The original "v3 clean win" framing has been
superseded.

## Repository state

- Local main fully synced to origin/main at commit `9cd014f`. The
  "75+ commit backlog" referenced in earlier memos had already been
  resolved on a prior workstation push.
- Recent session commits pushed via gh CLI (holoros PAT):
  - `933b085` session handoff for the May 23 multistate work
  - `9a24790` GA RCP85 l7b cycle 4 +41.2 pct hindcast closure
  - `9cd014f` GA driver investigation: 21-40 yr plantation cohort
    accounts for 22.5 pct of total projected cycle 4 AGC at 1.61x
    the mean of same-age other forest types

## Next session pickup checklist

1. Revise manuscript Sections 3.5 and Discussion to integrate the GA
   cohort attribution from `docs/GA_L7B_DRIVERS_20260525.md` together
   with the WA donor analog gap from
   `docs/PRODUCTIVITY_MATCHING_RESULT_20260522.md`. The closing
   framework is: the CEM matching engine amplifies whatever growth
   rate asymmetry exists in the regional donor pool. ME diverse pool
   plus L3 = +12 pct (key selects right growth match). GA homogeneous
   pool plus L3 = +41 pct (key concentrates plantation cohort). WA
   absent analog = -25 pct floor (key cannot find a match).
2. Fold the cohort cross-tab figure (or table) from
   `output/ga_l7b_residual_20260524/` into the manuscript supplement.
3. Optional follow-up analyses, not in scope for current manuscript:
   stratify GA matching by STDAGE class, apply plantation-specific
   sat_age cap below 1.0 for ages under 40, or remove plantation
   indicative donors from the GA pool.
4. gh CLI authentication is now configured via the github-manager
   skill. The GA RCP85 l7b commit (9a24790) and the GA driver memo
   commits push cleanly to origin/main with `git push origin main`.

## Original relocation note

This project was moved from `~/Documents/Claude/` root into the
active-projects tree on May 9, 2026 to consolidate research output
tracking under a single index. Existing README, CHANGELOG, HANDOFF, and
other project documentation remain authoritative. For full project
context see `README.md` or `HANDOFF.md`.
