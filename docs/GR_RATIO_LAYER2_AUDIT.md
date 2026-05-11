# gr_ratio Layer 2 audit: R/03_harvest_choice.R line 409

*Audit date: 10 May 2026, session continuation from HANDOFF_20260510.md*

## Summary

The Layer 2 root cause of the gr_ratio collapse is a units mismatch at lines 409 and 414 of `R/03_harvest_choice.R`. The expression `volcfnet * tpa_live` double counts the per tree to per acre conversion that was already applied during data prep, producing `vol_removed_total` values that are roughly `tpa_live` times too large (about 400 to 600 times in Maine, lower in southern pine). Because gross harvest removals flow into the gross growth ratio (`gr_ratio = gross_growth / harvest_removals`), an inflated denominator drives gr_ratio toward zero.

## Evidence trail

### Where volcfnet comes from

`R/01_data_prep.R` line 149 builds the condition-level `volcfnet` column:

```r
volcfnet = sum(TPA_UNADJ * VOLCFNET, na.rm = TRUE),
```

This sums per tree volume (`VOLCFNET`, cuft per tree from the FIA TREE table) multiplied by the trees per acre adjustment factor (`TPA_UNADJ`), then groups by condition. The result is already in cuft per acre at the condition level. Other places in the same file confirm this convention: line 174 (`tree_vol = TPA_UNADJ * VOLCFNET`), line 194 (`var(log1p(VOLCFNET * TPA_UNADJ))`), and line 283 (`vol_change = T2_volcfnet - T1_volcfnet`, used as a per acre delta).

### Where the bug fires

`R/03_harvest_choice.R` lines 404 to 425, `estimate_removals()`:

```r
vol_removed_total = volcfnet * tpa_live * harvest_intensity,     # LINE 409
saw_fraction = coalesce(
  (vol_sawtimber_softwood + vol_sawtimber_hardwood) /
  pmax(volcfnet * tpa_live, 1), 0.3),                            # LINE 414
```

`volcfnet` is already cuft/acre. Multiplying by `tpa_live` (trees per acre) again gives cuft·trees per acre squared, which is a meaningless unit. The numerator scaling is wrong by a factor of `tpa_live`.

The same error appears in the `saw_fraction` denominator on line 414, where the inventory ratio should compare cuft/acre to cuft/acre but instead compares cuft/acre to cuft·trees per acre squared. This silently distorts the sawtimber pulpwood split as well.

### How this connects to gr_ratio

`R/06_projection_engine.R` line 808 (and the patched copy at line 935 in `cem_pipeline_patch/06_projection_engine.R`):

```r
gr_ratio = if (harvest_removals > 0) gross_growth / harvest_removals else Inf,
```

`harvest_removals` is downstream of `vol_removed_total`. When `vol_removed_total` is `tpa_live` times too large, `harvest_removals` is also inflated, and `gr_ratio` collapses toward zero. For Maine plots with median `tpa_live` around 740 trees per acre (per the ME r21 baseline cycle 1), this produces gr_ratio values around 0.001 instead of the expected magnitude of approximately 1.

Confirming evidence in the post Layer 1 smoke outputs pulled this session:

| State | smoke gr_ratio cycle 1 | smoke gr_ratio cycle 3 | smoke tpa_live cycle 1 | Layer 1 deployed in this output |
|---|---|---|---|---|
| MN | 0.005 (0.005, 0.006) | 0.006 (0.006, 0.007) | 538 | yes (re smoked 18:41) |
| WA | 0.001 (0.001, 0.001) | 0.001 (0.001, 0.001) | 326 | no (smoked 08:22, pre fix) |
| GA | 0.001 (0.001, 0.001) | 0.001 (0.001, 0.001) | 470 | no (smoked 08:32, pre fix) |
| ME r21 | 0.000 (0.000, 0.001) | 0.000 (0.000, 0.001) | 742 | no (pre Layer 1) |

The MN post Layer 1 value of 0.005 to 0.006 is consistent with the predicted `1/harvest_rate` factor (~0.10 fixed harvest, so 0.10 × bug_factor ≈ 0.006). The Layer 2 fix should push the MN gr_ratio further toward the expected magnitude of approximately 1.

## Proposed patch

```r
# R/03_harvest_choice.R lines 404 to 425, estimate_removals()

estimate_removals <- function(cond_data, prices = NULL) {

  cond_data |>
    mutate(
      # Total removal volume (cuft/acre): volcfnet is already per acre
      # via R/01_data_prep.R line 149 sum(TPA_UNADJ * VOLCFNET).
      vol_removed_total = volcfnet * harvest_intensity,         # was volcfnet * tpa_live * harvest_intensity

      # Split into sawtimber and pulpwood based on standing inventory composition
      saw_fraction = coalesce(
        (vol_sawtimber_softwood + vol_sawtimber_hardwood) /
        pmax(volcfnet, 1), 0.3),                                # was pmax(volcfnet * tpa_live, 1)

      vol_removed_sawtimber = vol_removed_total * saw_fraction,
      vol_removed_pulpwood  = vol_removed_total * (1 - saw_fraction),

      removal_revenue = coalesce(vol_removed_sawtimber, 0) *
                          coalesce(prices$sawtimber$softwood, 250) +
                        coalesce(vol_removed_pulpwood, 0) *
                          coalesce(prices$pulpwood$softwood, 12)
    )
}
```

## Caveat: code path coverage

The handoff notes that the v1 gr_ratio patch landed on a path that production runs do not take, so the v2 patch was moved to `06_projection_engine.R`. This implies `estimate_removals()` in `R/03` is reached only on the economic overlay path (the `--use_maine_econ` branch that calls into `R/11_economic_harvest.R`). The currently running MN, WA, and GA production runs all carry `--no_econ` and `--skip_supply`, so the Layer 2 fix at line 409 will not affect those outputs.

To confirm coverage, search for `estimate_removals` call sites:

```bash
grep -rn "estimate_removals" R/ scripts/ cem_pipeline_patch/
```

If `estimate_removals` is unreachable in the production flag set, the Layer 2 fix is still publication relevant because the Maine r21 RCP 4.5 and RCP 8.5 econ runs (and any future Maine economic scenarios) do hit this path, and gr_ratio is a manuscript headline metric for those.

If `estimate_removals` is reachable in the production flag set (for instance because the harvest rate branch in `R/06` reuses pieces of `vol_removed_total`), the fix is more urgent and the in flight RCP 4.5 production outputs will still carry the Layer 2 inflation.

## Verification plan after fix

1. Apply the patch in `R/03_harvest_choice.R` locally, commit.
2. Push to Cardinal: `scp -F ~/.ssh/config R/03_harvest_choice.R cardinal:~/fia_cem_projections/R/`. Back up the prior copy as `.preupdate.20260511_layer2`.
3. Run a 1 sim, 3 cycle smoke on Maine with `--use_maine_econ` enabled to exercise the econ path:

   ```bash
   ssh -F ~/.ssh/config cardinal "cd ~/fia_cem_projections && \
     sbatch --time=1:00:00 --mem=32G --cpus-per-task=8 \
     --wrap='module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0; \
     Rscript run_projection.R --state ME --n_sims 1 --cycles 3 --cores 8 \
     --scenario_set bau --tag layer2_smoke --use_maine_econ \
     --include_remeasured --use_brms_sdimax --use_decoupled_climate \
     --use_disturbance --use_potter_vcc'"
   ```

4. Read the resulting `table_gr_ratios.csv`. Expected outcome: gr_ratio in the 0.5 to 3.0 range for BAU at cycle 1, depending on the gross growth side of the equation.

5. If the value lands in that range, propagate the patch to the `cem_pipeline_patch/` copy if `R/03` is mirrored there, then rerun the full ME r21 econ scenarios.

## Open question for the user

Once `estimate_removals` coverage is confirmed, do you want this fix folded into the current p1 multistate run (kill and resubmit the three RCP 4.5 jobs and the three queued RCP 8.5 jobs) or held until the Maine econ path can be regression tested first? Recommendation: hold, since the running jobs are already at 6 to 16 hours of compute and the multistate runs all use `--no_econ`.
