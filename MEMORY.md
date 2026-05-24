# Project Memory

*Created May 9, 2026 — last updated 24 May 2026 12:25 PM ET*

## Current state (24 May 2026 12:25 ET)

**All loose ends closed.** GA RCP85 Layer 7b production landed
(10310330 COMPLETED 21h19, exit 0), and the closing hindcast
(10347584) ran in 14 minutes with cycle 4 bias of **+41.2%**. The
multistate hindcast table is now complete for ME, MN, WA, GA at
cycle 4 across both RCPs. No active SLURM jobs for fia_plot_matching.

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

## Active SLURM jobs (12:25 ET 24 May)

No active fia_plot_matching jobs. 10310330 (GA L7b RCP85 production)
completed in 21h19 with exit 0; 10347584 (GA RCP85 l7b hindcast)
completed in 14m with exit 0. Other queued items belong to a separate
array (10413144_*, akhi_24h).

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

1. Revise manuscript Sections 3.5 and Discussion using
   PRODUCTIVITY_MATCHING_RESULT_20260522.md as the closing donor analog
   gap finding. The figure is now final: 72 rows across ME/MN/WA/GA
   and ten vintages.
2. Write a brief addendum (or expand the GA section in
   docs/PRODUCTIVITY_MATCHING_RESULT_*) noting GA RCP85 l7b at +41
   percent. The interpretation is that adding L3 ecoregion matching
   to GA (where the p1 baseline is already +25 percent) widens the
   overshoot rather than closing it, because GA donors share regional
   ecology but differ in growth composition, and the ecoregion key
   binds to a faster growing donor subset.
3. Decide whether to fold GA RCP85 l7b into the manuscript Section 3.5
   table or leave it as a supplementary entry. The p1 + p3hindcast
   pair already characterizes GA; the l7b entry mainly reinforces that
   ecoregion matching helps ME but does not help GA.
4. Resolve the 75+ commit backlog on origin/main from workstation
   (HTTPS auth still unavailable from Cowork sandbox).

## Original relocation note

This project was moved from `~/Documents/Claude/` root into the
active-projects tree on May 9, 2026 to consolidate research output
tracking under a single index. Existing README, CHANGELOG, HANDOFF, and
other project documentation remain authoritative. For full project
context see `README.md` or `HANDOFF.md`.
