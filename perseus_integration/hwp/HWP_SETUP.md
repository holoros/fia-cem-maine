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
