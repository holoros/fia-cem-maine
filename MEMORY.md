# Project Memory

*Created May 9, 2026 — last updated 23 May 2026 06:25 AM ET*

## Current state (23 May 2026 06:25 ET)

**Washington bias story closed.** Three independent remediation paths
(CONUS donor expansion, California donor addition, productivity matching)
all converge on the same finding: WA west side maritime Douglas fir has
no donor analog in the available FIA universe. The remedy is a model
based growth rate correction, not donor substitution. See
`docs/PRODUCTIVITY_MATCHING_RESULT_20260522.md` for the decisive memo.

**Multistate hindcast table closed for ME, MN, WA, GA at cycle 4.** Only
loose end is GA RCP85 Layer 7b production, which has OOMed three times
on 200-480 G and the latest hugemem retry (10310330) is approaching its
24 hour wall.

### Cycle 4 (RPA reference year 2019) bias table

| State | p1 RCP45 | p3 RCP45 | l7b RCP45 | conusCA RCP45 | prod weak RCP45 |
|---|---:|---:|---:|---:|---:|
| ME | n/a | n/a | +11.7% | n/a | n/a |
| MN | +6.8% | **-0.5%** | n/a | n/a | n/a |
| WA | -25.3% | -25.0% | -25.0% | -24.5% | -13.8% (~17% drop) |
| GA | +24.9% | +68.8%* | n/a | n/a | n/a |

`*` GA p3hindcast keeps only 45% of late cycle subjects; +69% is on the
selected plantation heavy subset, not the full subject pool.

### Closing manuscript story

The multistate CEM framework transfers well to states whose forests have
donor analogs (ME, MN, GA). It fails for WA in a specific, diagnosable
way: the west side maritime forest is a high productivity outlier with
no donor analog, so no matching strategy (neighbor, CONUS, ecoregion,
productivity) can supply an appropriate donor. The paper presents
productivity matching as the diagnostic that localizes the failure to a
donor analog gap, and recommends a hybrid model correction for outlier
forests as the path forward.

## Active SLURM jobs (06:25 ET 23 May)

| Job | Name | Status |
|---|---|---|
| 10310330 | fia_ga_hm_85 | RUNNING 21h14 of 24h. GA L7b RCP85 hugemem retry; expect TIMEOUT in ~2.5h unless it finishes. |

## Live state of Cardinal storage

- `fia_db_WA.rds` symlink restored to baseline (STATECDs 16, 41, 53 only;
  91,169 plots; no California). The conusCA experiment used a temporary
  rebuilt `fia_db_WA_addCA.rds`; baseline was restored before May 22.
- Cardinal cleanup 21 May freed ~51 GB; output/ went from 78 GB to 31 GB.
  21 superseded directories removed, keepers and 6 in-flight jobs preserved.

## Key documents (most recent first)

- `docs/SESSION_HANDOFF_20260523.md` — this session's full handoff
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

- Local main 75+ commits ahead of origin (HTTPS auth not available from
  this Cowork sandbox; push from workstation or via Cardinal's GitHub
  SSH).
- This session committed: MN p3hindcast RCP85 hindcast CSV, updated
  build_hindcast_bias_figure.R parser, validation memo syncs, the
  SESSION_HANDOFF_20260523.md, and this updated MEMORY.md.

## Next session pickup checklist

1. `squeue -u crsfaaron` to check 10310330 outcome (COMPLETED, TIMEOUT,
   or OUT_OF_MEMORY).
2. If 10310330 succeeded: pull `output/GA_*_rcp85_wear_l7b/` and submit
   GA RCP85 l7b hindcast.
3. If 10310330 failed: decide whether to retry with further memory
   mitigation (lower n_sims) or accept p3hindcast as the GA RCP85 row in
   the manuscript table.
4. Revise manuscript Sections 3.5 and Discussion using
   PRODUCTIVITY_MATCHING_RESULT_20260522.md as the closing donor analog
   gap finding.
5. Resolve the 75+ commit backlog on origin/main from workstation.

## Original relocation note

This project was moved from `~/Documents/Claude/` root into the
active-projects tree on May 9, 2026 to consolidate research output
tracking under a single index. Existing README, CHANGELOG, HANDOFF, and
other project documentation remain authoritative. For full project
context see `README.md` or `HANDOFF.md`.
