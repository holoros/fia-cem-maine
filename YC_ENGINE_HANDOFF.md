# YC Engine — Handoff

The **YC engine** (`cls "YC"`, model `yc_fia_empirical_v1`) is an empirical,
FIA-grounded forest-carbon projection engine added to the PERSEUS Forest
Intelligence explorer for all 48 CONUS states. This document is the operating
handoff: what it is, how it is built, where everything lives, what was learned
in calibration, and what to do next.

Live: <https://holoros.github.io/perseus-forest-intelligence/>
Repo: <https://github.com/holoros/perseus-forest-intelligence>

---

## 1. What the engine produces

Per state, per metric, per management scenario, a calendar-year (2025–2075,
5-yr step) trajectory with an uncertainty band (`pts = [year, mean, lo, hi]`):

**Metrics**
| key | meaning | unit |
|---|---|---|
| `agc_live_total` | above-ground live carbon | Tg C |
| `agb_dry` | above-ground dry biomass | Tg |
| `merch_bio_dry` | merchantable bole dry biomass | Tg |
| `vol_stem` | total stem gross volume (VOLTSGRS) | Mm³ |
| `merch_vol_mcf` | net merchantable stem volume (VOLCFNET) | Mcf |
| `harvest_c_yr` | annual harvest carbon flux (managed only) | Tg C/yr |

**Scenarios (management buckets)**
- `reserve (no harvest)` — passive succession along the untreated yield curve.
- `managed (harvest)` — owner-specific harvest: Industrial = even-aged
  clearcut (45-yr rotation); NIPF/State/Public = uneven-aged partial removals
  (20/25/30-yr cycles, 30/25/15% removal). Removals surface as `harvest_c_yr`.

The **central** line is current-climate, FIA-anchored. The **band** is a
state-specific climate sensitivity (see §4).

---

## 2. Method (how a number is produced)

1. **Stratify** each FIA plot: forest-type group (`FORTYPCD` group code) ×
   EPA Level III ecoregion (`NA_L3CODE`, spatial join) × ownership (USFS
   forest-ownership raster RDS-2025-0045: Family→NIPF, Corporate→Industrial,
   State, Federal/Local/Tribal→Public-Other; `OWNGRPCD` fallback).
2. **Fit** bounded Chapman-Richards yield curves per (stratum × treatment ×
   response) over the FIA chronosequence (untreated & harvested), with a
   cell → ft×owner → ft → state fallback hierarchy. Harvested asymptotes are
   anchored to the untreated carrying capacity (Maine v4 logic, generalized).
3. **Project** the current ground inventory (each plot once, latest visit)
   forward; managed applies the owner-specific harvest regime.
4. **Total + anchor**: per-ha densities → state totals via the uniform-grid
   area model `total = mean_density × n_plots × A0`, where `A0` (ha/plot) is
   calibrated so AG-carbon totals reproduce `fia.json` `tg_agc`. Volume metrics
   are scaled onto the existing engines' axis (Maine CEM pins the unit factor).

---

## 3. Where everything lives

**Cardinal (OSC), user `crsfaaron`**
- `~/yield_curves_conus/` — pipeline home (scripts, fits, per-state series).
  - `ycx_00_strata.R` — stratification + plot membership.
  - `ycx_01_curves.R` — Chapman-Richards fits (7 responses).
  - `ycx_02_perseus.R` — projection (harvest regimes + climate band).
  - `ycx_merge_perseus.py` — build/inject Perseus series JSON (local step).
  - `ycx_split_states.sh` — split national FIADB into per-state slim files.
  - `ycx_array.sh` / `ycx_step2.sh` — SLURM arrays (full / projection-only).
  - `ycx_csi_sample.R`, `ycx_calibrate.R`, `ycx_grm_beta.R`,
    `ycx_index_test.R` — climate sampling + β calibration + index comparison.
  - `config/` — strata, membership, `csi_states_ext.csv`, `ycx_beta.txt`,
    `index_growth_calib.csv`.
- `/fs/scratch/PUOM0008/crsfaaron/FIA/ENTIRE_*.csv` — national FIADB.
- `/fs/scratch/PUOM0008/crsfaaron/fia_by_state/` — per-state slim TREE/COND/PLOT.
- `~/raster_layers/csi`, `~/raster_layers/cspi_rs`, `~/raster_layers/bgi`,
  `~/landowner/US_forest_ownership.tif`, `~/SiteIndex/NA_Eco_L3_WGS84.shp`.

**Repo** (`holoros/perseus-forest-intelligence`)
- `scripts/yield_curve_engine/` — mirrored pipeline scripts.
- `docs/yc_engine_provenance.md` — full method + calibration notes.
- `public/api/series/<ST>.json`, `states.json`, `meta.json` — the data.

**Deploy is from the `gh-pages` branch, NOT `main`.** The `deploy-pages.yml`
is only a `.template` (never activated), and Pages publishes the built site on
`gh-pages`. To deploy a data change: copy `public/api/{series/*,states,meta}`
onto `gh-pages` and push (the front-end JS is unchanged and already maps
`cls "YC"`). See the deploy block in §6.

---

## 4. Climate band — what it is and the calibration story

The band is a **state-specific climate sensitivity**, not a flat ±%:
`pm(year) = 1 + β·(CSI(year)/CSI_2030 − 1)`; lo/hi bracket current vs
CSI-projected climate. Direction comes from the Climate Site Index projections
(`CSI_2030/2060/2090`, the only forward-looking productivity layer). Eastern
states use observed CSI; the 18 western/plains states (outside the CSI domain)
use a climate-transfer model (eastern CSI ratio ~ national climate-embedding
PCs + latitude, transfer R²≈0.35), flagged `domain=modeled`.

**β was calibrated against the FIA remeasurement growth record** — net annual
AGC growth `(AGC_t2 − AGC_t1)/REMPER` from ~145k paired plots, regressed on
`log(index)` with forest-type FE + stocking + age controls. Head-to-head of the
three productivity indices:

| index | β (growth elasticity) | SE | R² | n | coverage |
|---|---|---|---|---|---|
| **CSPI** (composite SPI) | **+0.59** | 0.03 | **0.20** | 145,229 | national |
| **BGI** (bioclimatic growth) | +0.31 | 0.07 | 0.11 | 8,973 | Maine |
| **CSI** (height site index) | −0.05 | 0.02 | 0.10 | 140,407 | eastern |

**Key finding:** the growth-oriented indices (CSPI, BGI) couple positively to
observed carbon growth; the height-based **CSI is uncoupled** (β≈0). So CSI’s
*direction* of climate change is used (it is the only forward projection), but
its *magnitude* is tempered to the empirical elasticity. β is set to **0.45**,
central between BGI (0.31) and CSPI (0.59). Bands are consequently modest
(≈3–6% for most states, larger where the modeled western ratio is large).

---

## 5. Honest caveats

- **"Managed" is a clearcut/partial-rotation scenario** with owner-class
  default rotations, not per-stand prescriptions.
- **Volume units** (`vol_stem`, `merch_vol_mcf`) are pinned to Maine’s CEM
  series via a single factor; absolute levels elsewhere inherit that unit.
- **Western climate band is modeled** (transfer R²≈0.35), not observed CSI;
  western forests are moisture-limited so the eastern response is approximate.
- **Climate β mixes indices**: direction from CSI projections, magnitude from
  the CSPI/BGI growth elasticities. The cleanest fix is a *future CSPI*
  projection (CSPI is the best predictor but currently present-day only).
- Measurement-year offsets are collapsed to a common 2025 baseline.

---

## 6. Runbooks

**Re-run the full pipeline (after a data/strata change)**
```bash
ssh cardinal
cd ~/yield_curves_conus
sbatch ycx_split_states.sh            # only if FIADB columns changed
sbatch ycx_array.sh                   # strata+curves+projection, all 48
```

**Re-run projection only (after a scenario/β/climate change)**
```bash
echo "0.4500" > config/ycx_beta.txt   # e.g. change β
sbatch ycx_step2.sh
```

**Merge + deploy (from a machine with the repo + gh auth)**
```bash
# pull ycx_*_state_series.csv + ycx_*_harvest_flux.csv from Cardinal first
cd perseus-forest-intelligence
git checkout origin/main -- public/api
python3 scripts/yield_curve_engine/ycx_merge_perseus.py . <series_csv_dir>
git add -A && git commit -m "..." && git push origin main
# deploy to the publishing branch:
git worktree add /tmp/ghp origin/gh-pages && cd /tmp/ghp
cp ../perseus-forest-intelligence/public/api/series/*.json api/series/
cp ../perseus-forest-intelligence/public/api/{states,meta}.json api/
git add -A && git commit -m "deploy" && git push -f origin HEAD:gh-pages
```

---

## 7. Recommended next steps (priority order)

1. **Build a future CSPI projection.** CSPI is the best growth predictor
   (β=0.59, R²=0.20, national) but only exists present-day. A CSPI_2030/60/90
   would let the band use the right index for both direction *and* magnitude,
   nationally, replacing the CSI-direction / tempered-β compromise.
2. **Activate CI deploy.** Rename `deploy-pages.yml.template` →
   `.github/workflows/deploy-pages.yml` and set Pages source to "GitHub
   Actions" so `main` merges auto-deploy (removes the manual gh-pages step).
3. **Validate against independent inventory change** (EVALIDator state carbon
   trends) to check the managed-decline magnitudes.
4. **Add sawtimber products** (`VOLBFNET` board-feet, `DRYBIO_SAWLOG`) to feed
   the stumpage/mill economics already in the repo.
5. **Per-stratum volume calibration** rather than the single Maine-pinned unit
   factor, once more states carry a native volume engine.

---

## FINALIZED MODEL (update)

### Curve form & parameterization
- **Form:** peak-and-decline `y = b1·Age^b2·b3^Age` (Weiskittel ME.AGB), fit by
  OLS in log space. Peaks at `Age* = b2/(−ln b3)` then declines.
- **Parameters vary by forest type, ecoregion, and owner** via a hierarchical
  (lme4) mixed model per state/response:
  `log(y) ~ 0 + ft + ft:log(age) + ft:age + (1+log(age)|eco) + (1|own) + (1|eco:own)`
  — shape (b2) & decline (b3) by forest type; scale (b1) & shape (b2) by
  ecoregion; scale by owner and ecoregion×owner. Partial pooling gives every
  cell a robust parameter set (sparse cells borrow strength; b3 capped ≤ 1).

### What the stress test showed
- Model forms predict comparably in the observed age range; the difference is
  long-horizon extrapolation, where peak-decline is required (asymptotic forms
  over-accumulate). 5-fold CV, 249k plots.
- Parameter variance: ecoregion drives scale & shape, forest type drives all
  three, owner contributes scale. (matches the user's design intent.)
- CSPI is a strong scale covariate (log-CSPI +0.64, ΔAIC −1079), corroborating
  the growth elasticity (+0.59); forest type already captures most of it.

### CONUS capstone: 100-yr no-harvest growth (TreeMap 2020)
`ycx_treemap_project.R` joins the TreeMap 2020 VAT (TM_ID → PLT_CN → area) to
the plot membership and grows each imputed plot's TreeMap area along its
finalized carbon curve, no harvest, 0–100 yr. (TreeMap 2022 CONUS (USFS RDS-2025-0032, downloaded to Cardinal scratch) is
the basis; PLT_CN match rate 91.6%, 216.6 Mha forest. Cross-checked against
TM2020 — results within 0.1%.)
- CONUS AG live carbon: **10,002 Tg C (2022) → 14,813 Tg C (2122), +48.1%**,
  decelerating to a plateau (~15,000 Tg) — the peak-decline saturation.
- Outputs: `yc_engine_outputs/conus_noharvest_100yr.csv` (state × decade),
  `conus_state_change.csv` (per-state gain), `treemap_conus_100yr.png`.
- Top gainers: OR, AL, WA, PA, TN, NY, CA, WI; highest % in young/fast
  southern & northeastern forests (TN +97%, AL +81%, NY +75%).

### Updated next steps
1. **Future CSPI projection** to drive the climate band by the best index.
2. **Per-pixel CONUS maps**: extend the TreeMap projection from imputed-plot
   aggregation to true 30 m per-pixel (sampling ecoregion/owner per pixel) for
   spatial carbon-change maps; reuse the asym_agb tiling infrastructure.
3. **All-metric CONUS projection** (biomass, merch volume) — same join, other
   responses — for a products/scenario layer.
4. Activate CI deploy (`deploy-pages.yml.template`).


---

## Dashboard integration: 100-yr horizon + scenarios + uncertainty (update)
- **Horizon extended to 2125** (100 yr). The reserve trajectory now shows the
  peak-decline saturation on the live chart (e.g., Maine reserve peaks ~2080
  then declines as stands senesce).
- **Four selectable management scenarios** (the `mgmt` dropdown buckets), all
  FIA-anchored at 2025 and fanning out:
  `reserve (no harvest)`, `managed (conservation)` (longer rotations / lighter
  removals), `managed (harvest)` (owner-default BAU), `managed (intensive)`
  (shorter rotations / heavier removals).
- **Uncertainty**: each scenario carries the CSI climate band (lo/hi). The
  scenario spread itself is the structural/management uncertainty.
- ycx_02 `SCEN` defines the regimes; `ycx_merge_perseus.py` injects all
  buckets. Front-end needs no change (bucket dropdown is data-driven).
