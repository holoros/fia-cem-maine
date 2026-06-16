# HWP storage via WPsCS-Estimator: validated runnable setup

**Validated 2026-06-02 on OSC Cardinal.** Wei's WPsCS-Estimator runs in our
environment and reproduces its own bundled reference output, so CEM should
drive this validated model directly rather than re-implement it (no fidelity
risk, the original is citable).

## Decision: drive the Python model, do not re-port to R

The earlier plan offered "R port or call the Python." Validation settles it:
calling the original Python is robust and exact. An R re-port is not worth the
risk of subtle mismatch in the cohort-decay integrals.

## Environment (Cardinal)

```bash
module load python/3.12
python3 -m venv ~/wpsenv
~/wpsenv/bin/pip install numpy scipy pandas
# verified: numpy 2.4.6, scipy 1.17.1, pandas 3.0.3
```

Run with `PYTHONNOUSERSITE=1` to avoid a broken numpy/scipy in `~/.local`.

## Model fixes for Linux

WPsCS `HWPs_CFLUX.py` hardcodes Windows path separators (`chr(92)`). Patch:

```bash
git clone https://github.com/xinyuanwylb19/WPsCS-Estimator.git ~/WPsCS_src
cp -r ~/WPsCS_src/HWPs_Python_Program/HWPs_Model ~/WPsCS_run
sed -i 's/chr(92)/os.sep/g' ~/WPsCS_run/HWPs_CFLUX.py
```

## Validation

```bash
cd ~/WPsCS_run   # sc='Scenario_1'
PYTHONNOUSERSITE=1 ~/wpsenv/bin/python HWPs_CFLUX.py
```

Reproduces `Scenario_1/Results_CFlux.csv` to within max abs diff 1.0 (integer
rounding of the original `round()` outputs). Shapes match (119 yr x 25 cols).

## The HWP storage pool

From `Results_CFlux.csv`, the long-term storage pool is the in-use product
stocks plus landfill (plus charcoal):

```
HWP_inuse    = Paper_A + BC_A + EC_A + HA_A          # in-use products
HWP_landfill = Paper_L + BC_L + EC_L + HA_L          # landfill
HWP_total    = HWP_inuse + HWP_landfill (+ charcoal) # the pool to add to CEM
```

Decay parameters (Params2): paper service life 10 yr, building construction
80 yr, exterior 50 yr, home application 60 yr; landfill turnover times 10 to
40 yr; charcoal decay 0.1%/yr (near-permanent). Maine and US parameterizations
ship in `WPsCS-Estimator/WP_Data/{Maine,US}_WPs.csv`.

## Bridge built and proven (2026-06-02)

`cem_to_hwp.py` drives the validated WPsCS engine on any CEM harvested-carbon
series (`Year, Biomass, Pulpwood, Sawlog`), forward-filling the product
allocation parameters to the series length, and returns the HWP pool
(`HWP_inuse`, `HWP_landfill`, `HWP_charcoal`, `HWP_total`). Proven on the
bundled data: 119-year run, HWP_total reproduces the validated WPsCS result.
So the CEM-to-WPsCS plumbing is done; the only missing piece is the CEM input
series.

## How CEM must emit the input (settled by the per-plot probe)

The per-plot output (`per_plot_projections.rds`, 9.2M rows x 35 cols) carries
`scenario, sim, cycle, PLT_CN, proj_carbon, was_harvested, harvest_intensity,
is_clearcut`, the disturbance flags, etc., but it does NOT persist the removed
volume by product (`vol_removed_sawtimber/pulpwood/total` are intermediate in
the engine and dropped). So harvested carbon by product cannot be recovered
from existing outputs and must be emitted from the pipeline.

Planned emission patch (flag-gated `--emit_hwp_input`, off by default):

1. **Engine (`06_projection_engine.R`), harvest branch:** where `vol_removed_*`
   and `harvest_intensity` are in scope, add per-plot removed carbon by product
   to the saved columns:
   `harv_c_total = pre_carbon_ag * harvest_intensity`, then split by the volume
   shares `harv_c_saw = harv_c_total * vol_removed_sawtimber/vol_removed_total`,
   `harv_c_pulp` likewise, `harv_c_residue = harv_c_total - saw - pulp`. The
   not-harvested branch sets these to 0 so the `bind_rows` is consistent.
2. **Expansion (`10_state_expansion.R`):** EXPNS-weight `harv_c_{saw,pulp,residue}`
   by scenario x cycle and write `state_<tag>_harvest_by_product.csv` with
   columns `Year, Biomass(=residue), Pulpwood(=pulp), Sawlog(=saw)` in Tg C.
3. **Run with production.** Because the input is produced during the projection,
   this lands automatically with the gated WA/GA production promotion: one run
   yields both the refined trajectory and the HWP input. Then `cem_to_hwp.py`
   converts it and the pool is appended to the state-summary CI.

This unifies the HWP wiring with the production runs, so no extra projection is
needed solely for HWP.

## End-to-end run completed (2026-06-04): first CEM HWP pool

Full chain executed on the canonical WA prodW bw100 production run:
per_plot (harv_c_*) -> 10_state_expansion.R (R-hwpExp) -> state_<tag>_harvest_by_product.csv
-> cem_to_hwp.py -> HWP pool. Result in `results/wa_hwp_rcp45_bau.csv` (WA RCP45 BAU):

| Year | HWP_total (MMT C) |
|---|---|
| 2004 | 1.2 |
| 2023 | 13.1 |
| 2053 | 18.3 (peak) |
| 2073 | 16.0 |

The pool builds as products accumulate, then declines after ~2053 as in-use stock
turns over faster than new harvest adds, a sensible managed-forest product-carbon
curve. WA harvest is sawlog-dominated (~10.6 vs 2.6 MMT pulpwood per cycle; residue ~0).

### Two operational notes for the bridge

1. **Annualize the 5-yr cycle harvest.** The CEM harvest_by_product is per 5-yr
   cycle at 5-yr steps; WPsCS expects annual input. Divide each cycle by 5 and
   replicate across its 5 years before the bridge.
2. **Scale to avoid WPsCS round() underflow.** WPsCS rounds to integers at every
   step, so MMT-scale inputs (~2/yr) collapse to 0. Multiply the input by 1e6
   (MMT C -> tonnes C), run, then divide the HWP pool by 1e6 to report in MMT C.
   (Both handled in the WA run wrapper; fold into cem_to_hwp.py as a --scale arg.)

## Remaining steps to wire CEM in

1. **Emit CEM harvested carbon by product.** Add a per-scenario annual series
   `Year, Biomass, Pulpwood, Sawlog` (carbon) from `11_economic_harvest.R` /
   the state expansion, using the existing sawlog/pulpwood composition and the
   PERSEUS per-state product fractions for the residue/biomass split.
2. **Extend allocation params to projection years.** `Params1` (annual product
   allocation fractions) and `Params2` run to ~2020; carry the final-year
   fractions forward (or use the `US_WPs` curve) for 2024 to 2099.
3. **Bridge + run.** Write CEM's series into a Scenario-style `HWPs_Data.csv`,
   run `HWPs_CFLUX.py`, read back `HWP_total`.
4. **Add the pool.** Append `mmt_hwp_inuse/landfill/total` and a
   `total_system_c = total_ecosystem_c + hwp_total` to the state-summary CI so
   managed vs reserve is a fair comparison.
5. **Ingest.** Add `hwp_total` to the PERSEUS metric catalog and surface it via
   the `--state` adapter next to the YC HWP `net_stock`.
