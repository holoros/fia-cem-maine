# FIA CEM Multistate Carbon Projection: Comprehensive Handoff

Date: 2026-05-21 (early morning, about 03:50 EDT)
Supersedes: docs/HANDOFF_COMPREHENSIVE_20260520.md
Author: Aaron Weiskittel (Cowork autopilot session)

## Orientation in one paragraph

The multistate paper extends the Maine CEM carbon projection to Minnesota, Washington, and Georgia and reports subject matched hindcasts against the FIA EXPALL EVALIDs. The headline event of this session is a correction. The Washington CONUS donor experiment that the 20 May runs appeared to set up was a null: the production runs never actually loaded the expanded donor pool, so they reproduced the neighbor pool result exactly. The cause is understood, the fix has been built and verified, and a corrected California donor experiment is now running on Cardinal. The early signal from a smoke is that adding California does not fix Washington underprediction and slightly deepens it, because California forest grows more slowly than west side Washington and Oregon. The defensible production numbers are due in a few hours. The manuscript abstract and Section 3.5 remain placeholders, so no unsupported claim has propagated.

## The correction: CONUS donor null result

The 20 May Washington CONUS production runs (SLURM 10128559 RCP 4.5, 10128560 RCP 8.5) completed with exit 0 but are byte for byte identical to the earlier non CONUS Layer 7b runs. The per_plot RDS files share an md5 (8fa566edaf5bb009a2adf9cff5182b62), the growth ratios match to the digit, and the hindcasts are unchanged. The `--conus_donors` flag changed only the printed donor state list. The run auto loaded the pre built `fia_db_WA.rds`, which physically contained only Idaho, Oregon, and Washington (STATECD 16, 41, 53), so filtering it by a nineteen state list still returned three states. The downloaded CONUS CSVs in `~/fia_data` were never built into that database, and the pipeline reads the database, not the loose CSVs. The earlier smoke that reported a Washington match rate moving from 62 to 81 percent measured donor membership, not donor growth pairs, which is why it looked promising and changed nothing. Full evidence chain is in `docs/CONUS_DONOR_NULL_RESULT_20260521.md`.

## The California donor experiment, built and verified

The donor database was rebuilt to actually contain California. `scripts/build_fia_db_WA_addCA.R` reads the validated baseline `fia_db_WA.rds` and appends California's per state PLOT, COND, and TREE rows, writing `fia_db_WA_addCA.rds` (states 6, 16, 41, 53). California is a full annual panel from 1994 to 2021 with PREV_PLT_CN, so it forms remeasured pairs from COND time 1 and time 2 even though it lacks the GRM component tables. The build added 43,814 plots, 52,851 conditions, and 446,320 trees.

A two simulation smoke confirmed the pool genuinely grew: remeasured pairs found rose from 21,855 to 27,000, untreated donor pairs from 16,439 to 20,484, and matching donors from 14,795 to 18,436. The smoke also gave the direction. Washington cycle 1 BAU growth ratio moved from 4.308 to 3.981 and cycle 1 carbon from 62,330 to 60,706. California donors are being matched into Washington cells, but they grow slower, so the projection moves down rather than up. The provisional read is no improvement and a slight worsening of the minus 25 percent underprediction.

The full production reruns are queued through the auto detected symlink: SLURM 10168301 (RCP 4.5, tag rcp45_wear_conusCA_l7b) and 10168302 (RCP 8.5, tag rcp85_wear_conusCA_l7b). Their hindcasts will give the defensible number.

## In flight Cardinal jobs (fia_cem project only)

| JobID | Name | What it is | Started | Runtime ref | Expected completion |
|---|---|---|---|---|---|
| 10168301 | wa_conusCA_prod | WA RCP 4.5, California donor pool, 100 sims, 15 cycles | 2026-05-21 03:45 | ~4.5 h (prior WA conus) | about 08:15 EDT |
| 10168302 | wa_conusCA_prod85 | WA RCP 8.5, California donor pool | 2026-05-21 03:45 | ~4.5 h | about 08:15 EDT |
| 10124341 | fia_mn_hm | MN RCP 4.5 L7b, hugemem, completes per_plot | 2026-05-20 22:18 | unknown, larger tree table | within a few hours, limit 20 h |
| 10124342 | fia_mn_hm_85 | MN RCP 8.5 L7b, hugemem | 2026-05-20 22:21 | unknown | within a few hours, limit 20 h |
| 10124343 | fia_ga_hm | GA RCP 4.5 L7b, hugemem | 2026-05-20 22:21 | unknown | within a few hours, limit 16 h |
| 10124344 | fia_ga_hm_85 | GA RCP 8.5 L7b, hugemem | 2026-05-20 22:21 | unknown | within a few hours, limit 16 h |

The WA conusCA pair should finish first, around 08:15 EDT. The MN and GA hugemem runs have been going about 5.5 hours and will likely land in the same window or a little later. Note that the queue also holds many unrelated jobs (mort, survival, htdbh, cr_sf, hcb_sf, dg_v8, cspi, conus_map, the large mnt2 array, and the wi/mi/mn t2 driver runs). Those belong to other model fitting work under the same account and should not be touched.

## Verified hindcast numbers so far

Washington bias sits near minus 25 percent and does not move with the matching key or a state list change. All values are the 2019 EVALID 531900 cycle 4 comparison, observed subject pool near 312 to 317 MMT.

| Config | RCP | proj MMT | residual MMT |
|---|---|---|---|
| p1 neighbor | 4.5 | 232.7 | -78.9 |
| p3 neighbor | 4.5 | 237.6 | -79.4 |
| l7b ecoregion key | 4.5 | 237.6 | -79.4 |
| conus (null, never loaded CONUS) | 4.5 | 237.6 | -79.4 |
| l7b ecoregion key | 8.5 | 235.3 | -81.6 |
| conus (null) | 8.5 | 235.3 | -81.6 |
| conusCA (real CA donors) | 4.5 | pending 10168301 | pending |
| conusCA (real CA donors) | 8.5 | pending 10168302 | pending |

Maine canonical hindcasts are complete (HINDCAST_ME_rcp45/85_hadgem2_wear_econ_l7b.csv). Minnesota and Georgia L7b hindcasts await the hugemem per_plot outputs, then run with `scripts/hindcast_multistate.R --state MN --tag rcp45_wear_l7b --date 20260520` and the GA and RCP 8.5 equivalents.

## Cardinal file and disk state

`~/fia_cem_projections` is 79 GB, almost entirely the `output` tree at 78 GB. There are 80 run directories and 31 per_plot_projections.rds checkpoints totaling 83 GB at 2 to 3 GB each. These are the disk hogs and the obvious target for a future cull, but nothing has been deleted without confirmation. `~/fia_data` is 11 GB and now holds the full per state CSV bundles for 19 states plus the rebuilt `fia_db_WA_addCA.rds`. The Washington baseline database lives on scratch at `/fs/scratch/PUOM0008/crsfaaron/FIA/fia_db_WA.rds`, and scratch is at 71 percent. There are 540 files in `logs` at 202 MB.

## Critical operational reminder: restore the Washington symlink

To make the auto detection use the California database, `~/fia_data/fia_db_WA.rds` was repointed from the baseline to `fia_db_WA_addCA.rds`. The baseline target is recorded in `~/fia_data/.fia_db_WA_baseline_target.txt` as `/fs/scratch/PUOM0008/crsfaaron/FIA/fia_db_WA.rds`. After the conusCA production runs and their hindcasts complete, restore it so future Washington runs use the neighbor baseline by default:

```
rm ~/fia_data/fia_db_WA.rds
ln -s $(cat ~/fia_data/.fia_db_WA_baseline_target.txt) ~/fia_data/fia_db_WA.rds
```

Until then the symlink must stay on addCA, because the running jobs read the database at launch and any reruns would need it too.

## Manuscript state

The v2 main draft is `manuscript/MULTISTATE_PAPER_DRAFT_V2_20260520.md` with INSERT pointers to the section drafts and filled page one tables. The abstract and Section 3.5 bias reduction table are deliberately still placeholders. Do not write a CONUS fixes Washington claim. The defensible narrative as of now is that the ecoregion matching key alone does not reduce Washington bias, that naive donor state list expansion is a no op unless the database is rebuilt, and that the binding constraint is donor growth rate composition rather than donor geographic coverage. Adding a slower growing neighbor cannot remedy an underprediction that arises because the existing donors already grow more slowly than the subject forest. This is a cleaner story than the original CONUS framing. Supplements S1 through S8 exist; S5 (per state hindcast tables) still awaits the MN and GA production hindcasts.

## Next session playbook

1. Establish SSH (key in the session uploads, copy into ~/.ssh and run the ssh command in the same shell call; the sandbox does not persist ~/.ssh between calls).
2. Poll the six jobs. WA conusCA first: `squeue -j 10168301,10168302`. Then MN and GA hugemem 10124341 to 10124344.
3. When the WA conusCA per_plot files land, run the hindcast for both RCPs: `Rscript scripts/hindcast_multistate.R --state WA --tag rcp45_wear_conusCA_l7b --date 20260521` and the RCP 8.5 equivalent. A ready wrapper pattern is `osc/submit_wa_conus_hindcast.sh`; adapt the tag to conusCA and date 20260521.
4. Compare the conusCA residual to the minus 79.4 and minus 81.6 baseline. Expectation from the smoke is no improvement or slightly worse.
5. Restore the Washington baseline symlink (see above).
6. When MN and GA hugemem land, run their hindcasts with the rcp45_wear_l7b and rcp85_wear_l7b tags and date 20260520, then assemble the four state hindcast comparison.
7. Populate manuscript Section 3.5 and the abstract with the corrected narrative and the verified numbers, and build Supplement S5.
8. Optionally cull stale per_plot RDS checkpoints to reclaim disk, with confirmation.

## Key paths

Project on Cardinal: `~/fia_cem_projections`. Data: `~/fia_data`. Baseline WA db: `/fs/scratch/PUOM0008/crsfaaron/FIA/fia_db_WA.rds`. Local repo and workspace: the fia-plot-matching active project folder. Account PUOM0008. Hindcast script: `scripts/hindcast_multistate.R`. DB rebuild: `scripts/build_fia_db_WA_addCA.R`.
