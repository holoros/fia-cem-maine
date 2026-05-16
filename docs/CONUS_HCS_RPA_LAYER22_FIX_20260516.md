# conus_hcs R/18_rpa_aggregation.R Layer 22 fix: rpa_subregion column collision

*Generated 16 May 2026 evening as the fifth iterative patch in the conus_hcs RPA aggregation arc.*
*Cross project note from the fia-plot-matching workspace.*

## TLDR

SLURM 9715817 (Layer 21 STATECD coercion patch) progressed past the join step into M1 occurrence and M2 intensity computation, gracefully skipped M4 HCS classification, then failed at the geographic crosswalk aggregation with `object 'rpa_subregion' not found`. Direct inspection of `data/checkpoints/plot_pair_complete.qs` showed that file already carries an `rpa_subregion` column (alongside `state`, `region`, and `STATECD`) at 114 columns and 162,139 rows. When the `left_join(states_cfg, by = "STATECD")` was executed at line 165, dplyr suffixed the colliding `rpa_subregion` to `rpa_subregion.x` and `rpa_subregion.y`, so the bare name `rpa_subregion` no longer existed for `derive_rpa_region(rpa_subregion)` to consume. Layer 22 patch drops the preexisting geographic crosswalk columns from `plot_pair_complete` before the join so the cfg side is the single source of truth. SLURM 9717200 (Layer 22) submitted 16 May 18:09 and is running.

## The error

```
ℹ Joining geographic crosswalks...
Error in `dplyr::group_by()`:
ℹ In argument: `rpa_region = derive_rpa_region(rpa_subregion)`.
Caused by error in `dplyr::case_when()`:
! Failed to evaluate the left-hand side of formula 1.
Caused by error:
! object 'rpa_subregion' not found
```

## Direct inspection (16 May 18:08)

```
> .libPaths(c("/users/PUOM0008/crsfaaron/R/library_4.4", ...))
> ppc <- qs2::qs_read("/users/PUOM0008/crsfaaron/conus_hcs/data/checkpoints/plot_pair_complete.qs")
> ncol(ppc); nrow(ppc)
[1] 114
[1] 162139
> "rpa_subregion" %in% names(ppc)
[1] TRUE
> "fia_region" %in% names(ppc)
[1] FALSE
> class(ppc$STATECD); length(unique(ppc$STATECD))
[1] "integer"
[1] 12
> grep("region|subregion|fia|fips|state", names(ppc), value = TRUE, ignore.case = TRUE)
[1] "STATECD"       "rpa_subregion" "state"         "region"
```

Confirmed: `plot_pair_complete` already carries `rpa_subregion` from upstream prep (likely `R/06b_cond_attach.R` or similar). The cfg side also provides `rpa_subregion` via the `select(state_fips, fia_region, rpa_subregion)` chain, so the join produces a name collision and the bare reference disappears.

## The fix (applied 16 May 18:09)

```r
# Layer 22 fix (16 May 2026): plot_pair_complete already carries an
# rpa_subregion column from upstream prep (06b/etc.); the left_join below
# would suffix the collision to rpa_subregion.x/.y and the bare name would
# disappear, breaking derive_rpa_region() downstream. Drop the preexisting
# geographic-crosswalk columns first so the cfg side is the single source
# of truth.
plot_pair_complete <- plot_pair_complete |>
  dplyr::select(-dplyr::any_of(c("rpa_subregion", "fia_region"))) |>
  dplyr::mutate(STATECD = as.integer(STATECD)) |>
  dplyr::left_join(states_cfg, by = "STATECD")
```

Backup at `~/conus_hcs/R/18_rpa_aggregation.R.preupdate.20260516_layer22`.

Patched file pulled to workspace at `docs/conus_hcs_18_rpa_aggregation_patched_20260516_layer22.R`.

## Cascading patch history

| Layer | Issue | Site | Status |
|---|---|---|---|
| 19 | `posterior_epred` on class `list` (regime-split fit) | `aggregate_to_rpa` body | Fixed (commit `c7c3d1f`) |
| 19b | NaN in quantile() from posterior_epred matrices | summary computation | Fixed (commit `c9688c4`) |
| 20 | M4 HCS fit not always loadable; should skip not fail | M4 branch | Fixed (commit `97043cb`) |
| 21 | STATECD type mismatch in left_join (char vs int) | states_cfg join | Fixed (commit `a45b408`) |
| 22 | rpa_subregion column collision in left_join | states_cfg join | **Fixed locally; awaiting SLURM 9717200** |

Each layer surfaces the next error as the script progresses further. The script now reaches:
- M1 regime split combination (Layer 19) — DONE in 9715817
- M2 weighted intensity (Layer 19) — DONE in 9715817
- M4 HCS skip (Layer 20) — DONE in 9715817, graceful
- Geographic join (Layer 21 + 22) — Layer 21 succeeded the type fix; Layer 22 needed for column collision
- Aggregations (by_region, by_subregion, by_fortyp, hcs_by_region) — pending Layer 22 verification
- RPA baseline comparison — pending output

## Concurrent finding to investigate (not a blocker)

Log of SLURM 9715817 reports:

> ! 76893 of 162139 plots have NA p_harvest_mean after regime combination.

About 47% of plots have NA p_harvest_mean after the partial + clearcut posterior_epred combination. Possible causes:
- Posterior_epred returned NA for plots out of training support (missing covariates)
- One regime returned all NA for some plots and the union approximation `pmin(P_partial + P_clearcut, 1)` propagated NA
- Some plots in plot_pair_complete are not in any of the 12 STATECD values that produced fits

This is not blocking the aggregation but is worth investigating once the run completes. The weighted means downstream use `na.rm = TRUE` so the aggregation will produce a result regardless; the half NA rate inflates the variance of subregional estimates.

## Next steps

1. Wait for SLURM 9717200 (Layer 22) to complete (expected 60 minutes from 18:09).
2. If successful, retrieve `~/conus_hcs/output/phase4/rpa_*.csv` and compare against Johnston/Guo/Prestemon 2021 baselines.
3. Diagnose the 47 percent NA p_harvest_mean rate. Likely starting point: tabulate NA rate by STATECD to see if it is concentrated in particular states.
4. If Layer 22 fails at a new layer, apply Layer 23.

## Status

- conus_hcs R/18_rpa_aggregation.R Layer 22 patched and deployed
- Backup at `R/18_rpa_aggregation.R.preupdate.20260516_layer22`
- SLURM 9717200 running (180 GB memory, 8 CPUs, 1 hour wall)
- Layer 21 had reached the geographic crosswalk in roughly 16 minutes before failing; Layer 22 should complete the aggregation within the 1-hour window
