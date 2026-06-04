# FIA CEM refinement, PERSEUS integration, and HWP: comprehensive handoff

**Date:** 2026-06-04
**Author:** A. Weiskittel (Cowork autopilot, multi-session)
**Branch / PR:** `cem-wa-ga-refinements-20260602` → holoros/fia-cem-maine PR #3
**Supersedes:** docs/HANDOFF_20260530_prodW.md (kept for the detailed result tables)

## One-paragraph orientation

This effort refined the multistate FIA CEM carbon pipeline (WA underprediction, GA overprediction), built and validated the path for publishing CEM outputs into the PERSEUS Forest Intelligence explorer across CONUS, and added harvested wood products (HWP) long-term storage by wiring the CEM harvest stream into Xinyuan Wei's WPsCS-Estimator. The headline scientific correction is that the n_sims=20 smoke hindcasts systematically overstated the bias fixes; at full n_sims=100 the WA productivity-weighting gain is modest and the WA asymptote-anchor lever is a confirmed dead end, while GA's plantation-rotation fix awaits its full-sample number. The HWP integration is now demonstrated end to end on real production output. All code is flag-gated, backed up, parse-clean, and committed.

## State refinement results (full n_sims=100, the trustworthy numbers)

### Washington (underprediction)
| config | hindcast bias | note |
|---|---|---|
| baseline l7b | -25.0% | |
| prodW bw100 (productivity-weighted donor draw) | **-22.9% / -21.2%** (RCP45/85) | **canonical WA** |
| prodW bw100 + asymptote anchor str1.0 | -23.6% / -21.3% | NEGATIVE, abandoned |

The n_sims=20 smokes had shown prodW at -11% to -15%, but those under-sampled the subject pool (~7,400 of ~11,630 subjects); the under-sampled subset was better predicted. At full sample the gain is ~2 points. The asymptote anchor went the wrong way because the matched PNW donors have carrying capacity >= the subjects; WA underprediction is growth-rate composition, not carrying capacity. Two donor-side levers are now exhausted. **Recommendation: accept prodW bw100 as canonical WA; further gains need a different instrument (west/east Cascades matching-key split, or a process/empirical PNW growth model), which is a strategic build, not more donor tuning.**

### Georgia (overprediction)
| config | hindcast bias | n_sims |
|---|---|---|
| baseline l7b (RCP45) | +20.4% | 100 |
| per-state terminal age (stateTerm 80yr) | +19.5% | 100 |
| plantation rotation 35yr (smoke) | +6.5% | 20 (optimistic) |
| **plantation rotation 35yr (production)** | **pending job 11262118** | 100 |

The plantation-rotation lever (planted stands STDORGCD=1 → 35yr) is mechanistically right (GA decomposition: plantations over-accumulate past loblolly's real rotation). Its true full-sample number is the last open result; expect it less favorable than +6.5% per the WA lesson, but directionally a large improvement over +20%.

## What was built (all on the patched Cardinal engine, committed as patch scripts)

- **R-prodW** (`patch_prod_weighting.py`): soft productivity-weighted donor draw (`--use_prod_weighting --prod_weight_bw`), Efraimidis-Spirakis key on a Gaussian kernel of asymptote closeness. Keeps the full subject pool (vs the hard key dropping ~37%).
- **R-stateTerm** (`patch_state_terminal_age.py`): wires the per-state terminal ages in state_constants.csv (GA 80, WA 200, MN 110) into the growth saturation; they were defined but never read (every state silently used Maine 120).
- **R-plantTerm** (`patch_plantation_term.py`): stand-origin-aware rotation age (`--plantation_terminal_age`), planted stands use a shorter terminal age.
- **R-asymAnchor** (`patch_asym_anchor.py`): per-plot FIA asymptote anchor (`--use_asym_anchor`). Built, tested, NEGATIVE for WA; retained as a documented lever.
- **R-hwpEmit** (`patch_hwp_emission.py`): engine emits per-plot harvested carbon by product (harv_c_saw/pulp/residue) using vol_removed shares; run_projection keeps them in per_plot.
- **R-hwpExp** (`patch_hwp_expansion.py`): expansion EXPNS-weights harv_c_* to state totals and writes `state_<tag>_harvest_by_product.csv`.

All flags default OFF, so ME and prior runs are unchanged. Engine patches live on Cardinal `R/` (the live r21 tree); the repo `R/` remains the r20 baseline and the patch scripts in `cem_pipeline_patch/` reconstruct the deltas. Promoting the patched engine into the repo canonical tree is the standing reproducibility item (do before locking manuscript numbers).

## PERSEUS integration (CONUS pathway)

- The explorer is a static read layer over `~/perseus_db` on Cardinal: CEM `state_<tag>_ci.csv` → `adapters/ingest_cem_*.R` → SQLite → `48_export_api.py` → `api/series/<STATE>.json`. CEM is already a first-class engine class but ingested for Maine only (the adapters hardcode ME).
- **Built and dry-run-validated:** `perseus_integration/ingest_cem_state.R`, a state-general adapter (`--state/--csv/--model/--climate`). A scratch-DB dry run produced 2,700 valid rows for the WA slot with the correct `[year, value]` series contract; production untouched.
- The CONUS generalization already in the explorer is the `YC` hybrid engine (FIA empirical Chapman-Richards by forest-type × EPA L3 × ownership, all 48 states), which also publishes HWP net stock. CEM and YC share the same backbone; the pathway doc (`docs/PERSEUS_CONUS_INTEGRATION_PATHWAY_20260602.md`) lays out feeding CEM refinements into the YC hybrid plus ingesting focal-state CEM.
- **Next:** ingest the WA prodW CI (now produced: `state_rcp45/85_wear_prodW100prod_l7b_ci.csv`) via the validated adapter, then `48_export_api.py`, then publish (respecting the gh-pages/main desync rules in the perseus repo README).

## HWP long-term storage (now wired end to end)

- WPsCS-Estimator (Wei) validated on Cardinal (reproduces its bundled output); decision: drive the validated Python directly, no R re-port.
- `perseus_integration/hwp/cem_to_hwp.py` bridges a CEM harvest series to the HWP pool (in-use + landfill + charcoal).
- **First CEM HWP pool produced** (WA RCP45 BAU, `perseus_integration/hwp/results/wa_hwp_rcp45_bau.csv`): 1.2 MMT C (2004) → 18.3 peak (2053) → 16.0 (2073).
- Two bridge gotchas, documented in `perseus_integration/hwp/HWP_SETUP.md`: annualize the 5-yr cycle harvest, and scale ×1e6 (MMT→tonnes) to avoid WPsCS integer-round underflow. Fold both into `cem_to_hwp.py` as a `--scale`/annualize option.
- **Next:** add `total_system_c = ecosystem_c + hwp_total` to the state-summary CI; run the bridge for GA once its expansion lands; expose `hwp_total` in PERSEUS alongside the YC HWP.

## Jobs in flight / completed this session

| Job | What | State |
|---|---|---|
| 11212496/97 | WA prodW bw100 production (RCP45/85) | COMPLETED (canonical WA) |
| 11222564/65 | WA prodW + asym anchor (RCP45/85) | COMPLETED (negative result) |
| 11229000/01 | GA plantTerm rot35 production, hugemem (RCP45/85) | COMPLETED |
| 11229126 | WA state expansion + harvest_by_product | COMPLETED |
| 11262118 | GA hindcast + expansion (both RCPs) | RUNNING (the open result) |

Operational lessons logged: validate tuning at full n_sims (smokes mislead on magnitude); GA n_sims=100 needs hugemem-exclusive (OOMs at 200G with the new columns); watch the midnight date-rollover in inline hindcasts (use the run's start-date for `--date`).

## Immediate next steps (in order)

1. Read GA hindcast (job 11262118): the true GA plantation-rotation number. If GA is now within ~±10–15%, GA is done; if hot, sweep rotation 30/40 at full n_sims.
2. Run `cem_to_hwp.py` on the GA harvest_by_product (job 11262118 output) for the GA HWP pool.
3. Add `total_system_c` to the state-summary CI (ecosystem + HWP) so managed-vs-reserve is a fair comparison.
4. PERSEUS ingest: run `ingest_cem_state.R` for WA (and GA) production CIs → `48_export_api.py` → publish; this lights up CEM lines for WA/GA in the explorer.
5. Decide WA strategy: accept -22.9% or commit to the Cascades-split / process-growth build.
6. Reproducibility: promote the patched Cardinal `R/` engine into the repo canonical tree and tag a release.

## Key paths

Cardinal project `~/fia_cem_projections`; perseus_db `~/perseus_db`; WPsCS `~/WPsCS_run` + venv `~/wpsenv` (PYTHONNOUSERSITE=1); canonical WA CI `output/state_summary_progression/state_rcp45/85_wear_prodW100prod_l7b_ci.csv`; HWP bridge `perseus_integration/hwp/`. Account PUOM0008.
