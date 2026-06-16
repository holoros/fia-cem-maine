# PERSEUS Forest Intelligence: session handoff

**Repo:** github.com/holoros/perseus-forest-intelligence
**Live:** https://holoros.github.io/perseus-forest-intelligence
**As of:** 2026-06-04, db_version v0.64 plus docs (ADR 0003, 0004)
**Compute:** OSC Cardinal, `/users/PUOM0008/crsfaaron/yield_curves_conus`

## What this session did

Two arcs: unify the FIA yield-curve engine across all stock metrics, and make the managed
scenarios realistic and data-grounded. Both are deployed and durable.

### 1. FIA engine form unification (v0.56 to v0.58)

All five FIA stock metrics now run on one model form: hybrid Chapman-Richards with a
senescence decline tail, recalibrated to the FIA longitudinal increment and capped at the
95th percentile of observed standing stock. This replaced the peak-decline form, which
over-projected the century totals because it kept accumulating old-stand mass without an
observed ceiling.

CONUS reserve, peak-decline to hybrid+recal:
- carbon `agc_live_total`: +112% to +63%
- biomass `agb_dry`: +113% to +62%
- volume `vol_stem`: +112% to +72%
- merch volume `merch_vol_mcf`: +138% to +66%
- merch biomass `merch_bio_dry`: +146% to +70%

For carbon this also makes the FIA engine share a form with the TreeMap engine (+48%), so
the FIADB vs TreeMap spread reads as a true inventory range rather than a model artifact.
Recorded in ADR 0003 and `docs/results/fia_engine_form_unification.md`.

### 2. Managed scenario recalibration to FIADB working fractions (v0.59 to v0.64)

The managed scenarios were applying owner-rotation harvest to the entire land base, which
removed about 1.9 points of carbon per year and drove an implausible CONUS decline. The
FIA record shows real landscape harvest removal is about 0.02 %/yr (only ~0.8% of plots
cut per remeasurement) and net change is +1.1 %/yr. The whole-landscape rotation was about
100x too aggressive.

Fix: each managed scenario is a partial-landscape blend with reserve,
`managed = phi * full_rotation + (1 - phi) * reserve`, with FIADB per-state fractions:
- harvest and conservation: phi = harvested_share (observed FIA harvest treatment)
- intensive: phi = planted_share (STDORGCD plantations only)
- reserved forest (RESERVCD) excluded entirely

CONUS carbon: reserve +63%, conservation +62%, harvest +62%, intensive +60%. Differentiation
concentrates where management is real: GA intensive +84%, FL +73% (Southern pine), ME
harvest +27%. Declines remain only in the disturbance-exposed variants (ME managed harvest
disturbance-exposed -20%), correctly attributing downside to fire/insect/drought. Recorded
in ADR 0004.

## Durability: the bake-at-source design (important)

The repo is regenerated frequently by `perseus_db ingest ...` commits (CBM, GCBM, LCMS
engine ingests, authored by Aaron from a parallel session). Each FIA re-injection would
revert post-hoc JSON edits. So the managed recalibration is BAKED into the canonical FIA
fullseries CSVs on Cardinal:

    /users/PUOM0008/crsfaaron/yield_curves_conus/treemap/recal_cell/fia_hybrid_fullseries_*.csv

Any re-injection now produces correct managed buckets with no post step. The original
whole-landscape rotation is preserved beside each file as `*.full.csv`. Verified: the
managed scenarios stayed correct through the v0.65 ingest and the height-corrected v3
campaign.

### When the bake must be re-run

ONLY if the FIA projector itself is re-run (it regenerates the CSVs as whole-landscape
rotation). After any projector run:

    cd <fullseries dir>
    python3 ycx_bake_managed_csv.py docs/results/fia_mgmt_shares_bystate.csv fia_hybrid_fullseries_*.csv

Ordinary engine ingests that only re-inject the existing CSVs need nothing. See
`scripts/yield_curve_engine/MANAGED_RECAL_README.md`.

## Other fixes this session

- Stale data after deploy: the app fetched `api/*.json` without a cache key, so the Pages
  CDN served old data for minutes after each deploy (the main source of "the numbers look
  old"). Now every fetch is versioned by build id. If a raw API URL still looks stale,
  append a query string or hard refresh.
- Dashboard note: managed scenarios now carry an inline note explaining they are land-base
  sensitivity cases, not business as usual.

## Key scripts (in repo, scripts/yield_curve_engine/)

- `ycx_fia_hybrid_fullseries_vec.R` (carbon), `_agb.R` (biomass), `_resp.R` (vol/merch):
  vectorized 100-year projector, 12 scenario buckets, all states.
- `ycx_hybrid_fit2.R`: hybrid curve fitter, all five responses.
- `ycx_inject_hybrid.py`: injects fullseries CSVs into series JSON with per-state t0 rescale.
- `ycx_mgmt_shares.R`: FIADB reserved/planted/harvested shares per state.
- `ycx_bake_managed_csv.py`: bakes data-driven managed into the fullseries CSVs (durable).
- `ycx_blend_fia_datadriven.py`, `ycx_blend_managed_engines.py`: JSON-level fallbacks.

## Open items and future work

- Asynchronous rotation: phi uses the per-remeasurement harvested share as a static
  fraction. A fuller model would simulate asynchronous rotation so high-harvest regions
  reach a flat landscape equilibrium rather than a damped decline. This is the main
  remaining modeling refinement for the managed scenarios.
- Working-forest fractions are FIADB-derived now, but the harvested-share-as-fraction
  mapping is a modeling choice; revisit if a manuscript needs a defended calibration.
- Volume/merch mortality under stress arms is mapped from the carbon GRM grid; wire native
  `dVOL.MORT` into the volume stress arm if those buckets become decision-critical.
- The `state_harvest_rates.csv` on Cardinal (`fvs_stress/`) has annual harvest fractions
  with partial/clearcut/standreplace splits, a richer basis than the static share if a
  continuous-removal harvest model is ever built.

## Operational reminders

- The repo has active parallel commits (Aaron's engine ingests). Pull latest before
  branching; expect occasional merge races on the series JSON and meta.json.
- Cardinal SSH from this environment: the system ssh config is broken (bad owner on
  /etc/ssh), so use the paramiko helper (`ssh_card.py` pattern) rather than the ssh client.
- After any deploy, the live data may be CDN-cached briefly; cache-bust to verify.
