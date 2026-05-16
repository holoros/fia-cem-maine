# conus_hcs R/18_rpa_aggregation.R fix: regime-split fit handling

*Generated 16 May 2026. Cross project note from the fia-plot-matching workspace addressing an issue discovered in the related conus_hcs project on Cardinal.*

## Background

The `conus_hcs` project on Cardinal (`~/conus_hcs/`) is the Bayesian hierarchical harvest decision module that fits M1 (occurrence), M2 (intensity), M3 (tree level), and M4 (HCS class) models to the FIA panel pair dataset, then aggregates plot level predictions up to USFS RPA Assessment reporting geographies for comparison against Johnston, Guo, Prestemon 2021 baselines.

`R/18_rpa_aggregation.R` consumes the fitted brms models plus `plot_pair_complete.qs` and produces the four output tables (`by_region`, `by_subregion`, `by_fortyp`, `hcs_by_region`) plus a `rpa_comparison` table. The script supports two invocation modes: legacy with 4 single fit paths, and auto load that picks up the regime split fits at `models/m1_occurrence/operational_partial/` and `models/m1_occurrence/operational_clearcut/`.

## The bug

The earlier rerun on 14 May (log `logs/phase4_retry_173513/18_rpa_v2.log`) failed with:

```
Error in UseMethod("posterior_epred") :
  no applicable method for 'posterior_epred' applied to an object of class "list"
Calls: aggregate_to_rpa -> posterior_epred
```

The auto load convention (`load_regime_fits_18`) returns a named list with `$partial` and `$clearcut` brms fits. The body of `aggregate_to_rpa()` was written expecting a single brms fit and called `posterior_epred(fit_m1_op, ...)` directly. brms `posterior_epred` has no method for class `list`.

## The fix (applied 16 May 2026)

Added a `is_regime_list()` helper detector and regime aware computation of plot level posterior predictions. The patch lives at `~/conus_hcs/R/18_rpa_aggregation.R` with backup at `~/conus_hcs/R/18_rpa_aggregation.R.preupdate.20260516_issue19`.

For each model:

- **M1 occurrence:** when a regime list, compute `posterior_epred` for `$partial` and `$clearcut` separately, then combine as `pmin(P_partial + P_clearcut, 1)`. This is the union approximation under the partial/clearcut independence assumption documented in `HARVEST_DEFINITION_COMPARISON.md`. The two regimes are distinct harvest types that rarely co occur on the same plot in the same panel period, so independence is a reasonable approximation.

- **M2 intensity:** when a regime list, compute `posterior_epred` for each regime, then combine as a probability weighted average: `I_combined = (P_partial * I_partial + P_clearcut * I_clearcut) / (P_partial + P_clearcut)` with a safe divide fallback to the simple mean when `P_partial + P_clearcut < 1e-9`.

- **M4 HCS class:** use the `$partial` fit by default since the HCS classification is regime agnostic and partial dominates the data volume.

The expected_removal flowing into the aggregations is then `pred_p1 * pred_p2` using the combined values, exactly as the single fit code path does.

## What was rerun

The patched script was submitted as SLURM job 9704155 with 180 GB memory and 8 CPUs. The first attempt (9703391, 32 GB) was OOM killed by the posterior_epred matrices over 162k plot pairs across 4000 brms draws (M1 alone consumes about 5 GB; with M2 plus M4 the working set exceeds 32 GB). 180 GB provides comfortable headroom.

Expected outputs at `~/conus_hcs/output/phase4/`:
- `rpa_aggregation.qs` (full output list)
- `rpa_by_subregion.csv` (the headline RPA subregion comparison)
- `rpa_comparison.csv` (per subregion removal vs Johnston/Guo/Prestemon 2021)

Pull command for the next session:

```bash
scp -F ~/.ssh/config crsfaaron@cardinal.osc.edu:'~/conus_hcs/output/phase4/rpa_*.csv' .
```

## Open decision from HARVEST_DEFINITION_COMPARISON.md

The harvest definition comparison document at `~/conus_hcs/HARVEST_DEFINITION_COMPARISON.md` raised two decisions waiting on user input:

1. **Operational definition:** B union D (composite, recommended) versus B alone (simple binary). The current Layer 19 patch assumes B union D is the operational target by combining partial and clearcut M1 fits. If you prefer B alone, the M1 fit list would only include `$partial` and the clearcut term drops out of `pred_p1`. Easy to switch.

2. **Stratification flag:** model partial and clearcut in the same M1 fit (one categorical outcome) or split into two separate M1 fits (current implementation). The current implementation supports both via the regime aware aggregation; downstream is agnostic.

The patch makes the script run regardless of decision but flagging here so the manuscript narrative aligns with the chosen operational definition.

## Status

- conus_hcs R/18_rpa_aggregation.R patched and deployed
- SLURM 9704155 running (180 GB memory)
- Backup at R/18_rpa_aggregation.R.preupdate.20260516_issue19
- Output expected within 60 minutes
- Once results land, the RPA comparison tables can be reviewed and any further calibration issues addressed

## Cross project note

This patch was made to a different project (`conus_hcs`) than `fia_cem_projections` where the rest of this session's work has been. The two projects relate:

- `fia_cem_projections` produces multistate per acre and statewide AGC trajectories using a CEM matching framework with the Wear and Coulston 2025 harvest logit applied directly (no separate trained M1/M2/M4 layer).
- `conus_hcs` is the longer term Bayesian hierarchical harvest decision module that, when complete, will replace the Wear 2025 logit with a custom-trained M1 occurrence + M2 intensity model fitted on the actual FIA panel pair data with CONUS coverage.

The RPA aggregation outputs from `conus_hcs/R/18_rpa_aggregation.R` are the key validation deliverable for the `conus_hcs` project, comparing the trained model's harvest predictions against the published RPA Assessment baselines. They are not the same as the EVALIDator volume comparison done for `fia_cem_projections` (which validates projection per acre AGC against observed FIA totals).

For manuscript scoping, the two projects support different chapters:
- `fia_cem_projections` multistate p1: cross state carbon projection paper
- `conus_hcs` RPA comparison: harvest decision module methodology paper
