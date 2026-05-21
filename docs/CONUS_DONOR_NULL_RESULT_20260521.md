# CONUS Donor Pool: Verified Null Result and Root Cause

Date: 2026-05-21
Author: Aaron Weiskittel (Cowork autopilot session)
Status: Negative result, fully diagnosed, fixable. Central CONUS donor hypothesis remains UNTESTED.

## One paragraph summary

The Washington CONUS donor production runs completed cleanly overnight (SLURM 10128559 RCP 4.5, 10128560 RCP 8.5, both exit 0). They are byte for byte identical to the earlier non CONUS Layer 7b runs. The `--conus_donors` flag changed only the printed donor state list. It did not change the donor data the projection actually used, so the projected carbon, the growth ratios, and the hindcast bias are all unchanged. The CONUS donor hypothesis for Washington has therefore not yet been tested. The cause is understood and the fix is mechanical.

## The evidence chain

The WA RCP 4.5 conus per_plot_projections.rds is md5 identical to the non conus Layer 7b per_plot:

```
8fa566edaf5bb009a2adf9cff5182b62  WA_20260520_rcp45_wear_conus_l7b/per_plot_projections.rds
8fa566edaf5bb009a2adf9cff5182b62  WA_20260520_rcp45_wear_l7b/per_plot_projections.rds
```

table_inventory_summary.csv is also md5 identical, and the cycle 1 BAU growth ratios match to the digit (4.308 in both).

The two production logs report the same remeasured pair pipeline despite different state lists:

```
non conus l7b (10021620):  Donor states: WA, OR, ID, MT
conus       (10128559):    Donor states: AL, CA, CT, FL, GA, ID, MA, ME, MN, MS, MT, NH, NY, OR, RI, SC, TN, VT, WA
both:                      Untreated-donor filter: 21855 -> 16439 remeasured pairs
both:                      Subjects: 14367 | Donors: 14795
```

The hindcasts are unchanged across every Washington configuration:

```
config            RCP    obs_subj_agc   proj_subj_agc   residual_mmt
p1 (neighbor)     4.5    311.7          232.7           -78.9
p3 (neighbor)     4.5    317.0          237.6           -79.4
l7b (ecoregion)   4.5    317.0          237.6           -79.4
conus l7b         4.5    317.0          237.6           -79.4
l7b (ecoregion)   8.5    317.0          235.3           -81.6
conus l7b         8.5    317.0          235.3           -81.6
```

Washington bias sits at roughly minus 25 percent (residual near minus 79 to minus 82 MMT against an observed subject pool of 317 MMT) regardless of matching key or donor state list.

## Root cause

The production log contains the decisive line:

```
Auto-detected pre-downloaded FIA data: /users/PUOM0008/crsfaaron/fia_data/fia_db_WA.rds
```

The run auto detected and loaded the pre built per state database `fia_db_WA.rds`. Reading its contents:

```
PLOT STATECD: 16, 41, 53   (ID, OR, WA)
COND STATECD: 16, 41, 53
TREE STATECD: 16, 41, 53
```

That database physically contains only Idaho, Oregon, and Washington. It was built before the CONUS CSV bundles were downloaded. `read_fia_direct()` filters this database by `donor_states`, but filtering a three state database by a nineteen state list still returns three states. The CONUS CSVs that were downloaded into `~/fia_data` (CA, AL, GA, ME, MN, and the rest) were never incorporated into `fia_db_WA.rds`, and the pipeline reads the RDS, not the loose CSVs. The expanded donor pool existed only in the printed configuration, never in the data.

## Why the earlier smoke looked like it worked

The smoke that reported a Washington iteration 1 match rate moving from 62 to 81 percent measured donor membership, that is, whether at least one ecoregion matching donor plot exists for each subject condition. Membership counting can read the loose CSVs and so it saw the added CONUS plots. The projection, by contrast, needs donor growth pairs (a measured time 1 and time 2 trajectory), and those come exclusively from the pre built database. Adding plots that have no loaded remeasurement improves the membership statistic without contributing a single growth trajectory. The 62 to 81 figure was real but it does not imply any change to the projection, which is exactly what the identical md5 confirms.

## The fix is mechanical, and the data supports it

California is not single cycle. CA_COND.csv spans inventory years 1994 through 2021 (annual panel) and CA_PLOT.csv carries PREV_PLT_CN, so California can form remeasured pairs from COND time 1 and time 2 the same way the neighbor states do. The absence of CA_TREE_GRM_COMPONENT limits the removal and mortality decomposition but does not block remeasured growth pairs, which are built from COND, not GRM.

To actually test the CONUS donor hypothesis for Washington:

1. Rebuild the donor database so it includes the CONUS donor states already present in `~/fia_data`, or bypass the RDS auto detection and load the loose CSVs directly. The auto detect currently shadows the CSVs silently, which is the trap that produced this null result.
2. Verify before the expensive run: confirm the rebuilt database contains the western donor STATECDs and that a short matching smoke shows the remeasured pair count grow above 21855.
3. Rerun WA conus production (both RCPs) and the hindcast, then compare residual_mmt against the minus 79.4 and minus 81.6 baseline.

## Open scientific question

Even with CONUS donors correctly loaded, it is not yet known whether California and other western donors fall into Washington's EPA L3 ecoregion matching cells. Washington west side Douglas fir and hemlock sit in Pacific Northwest ecoregions; California's coastal and Klamath ecoregions are adjacent but distinct, so many CA donors may only enter at the section collapse iteration or the ecoregion drop iteration. The hypothesis that a CONUS donor pool reduces Washington bias is plausible but remains genuinely untested. This run does not support it and does not refute it.

## Implication for the manuscript

The abstract and Section 3.5 must not claim that a CONUS donor pool reduces Washington bias. As of this run the only defensible statements are that the ecoregion matching key alone does not reduce Washington bias (the l7b hindcast equals the p1 and p3 hindcasts) and that naive expansion of the donor state list has no effect unless the underlying donor database is rebuilt to contain those states. The bias reduction table in Section 3.5 should remain a placeholder until a corrected rerun lands.

## Update 2026-05-21: California donor experiment, build and smoke confirmed, production in flight

The donor database was rebuilt to actually contain California. The script `scripts/build_fia_db_WA_addCA.R` reads the validated baseline `fia_db_WA.rds` (Idaho, Oregon, Washington) and appends California's per state PLOT, COND, and TREE rows, writing `fia_db_WA_addCA.rds`. This preserves the baseline donors exactly and isolates the effect of adding the one western state with complete data that the 20 May run silently failed to load. The build added 43,814 California plots, 52,851 conditions, and 446,320 trees, giving a donor database spanning STATECD 6, 16, 41, 53.

A two simulation smoke against the rebuilt database confirms California is now genuinely in the pool. The remeasured pairs found grew from 21,855 to 27,000, the untreated donor pairs grew from 16,439 to 20,484, and the matching donor count grew from 14,795 to 18,436. This is the change that the 20 May run failed to produce.

The smoke also answers the direction question. Washington cycle 1 BAU growth ratio moved from 4.308 to 3.981 and cycle 1 carbon moved from 62,330 to 60,706. California donors are being matched into Washington cells, but they grow slower on average than the Pacific Northwest maritime donors that Washington's west side Douglas fir and hemlock subjects need, so the effect pushes the Washington projection down rather than up. The provisional read is that geographic expansion to California does not fix Washington underprediction and slightly deepens it. The mechanism is consistent with California forest growing more slowly than west side Washington and Oregon.

Full production reruns are queued to obtain the defensible hindcast number: SLURM 10168301 (RCP 4.5, tag rcp45_wear_conusCA_l7b) and 10168302 (RCP 8.5, tag rcp85_wear_conusCA_l7b), both reading the rebuilt database through the auto detected `fia_db_WA.rds` symlink. The baseline symlink target is recorded in `fia_data/.fia_db_WA_baseline_target.txt` and must be restored once these runs and their hindcasts complete. Expectation from the smoke is a Washington residual at or slightly below the minus 79.4 and minus 81.6 baseline, that is, no improvement.

The implication for the paper sharpens. The bias mechanism is donor growth rate composition, not donor geographic coverage. Expanding the donor pool to a slower growing neighbor cannot remedy an underprediction that arises because the existing donors already grow more slowly than the subject forest. The remedy direction is the opposite: up weight or restrict to the fast growing west side maritime donors, or correct the growth transfer rather than the donor geography. This is a cleaner and more defensible story than the original CONUS framing.
