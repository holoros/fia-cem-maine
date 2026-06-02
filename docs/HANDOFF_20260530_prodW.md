# Handoff: WA productivity-weighted donor draw (R-prodW)

**Date:** 2026-05-30
**Author:** A. Weiskittel (Cowork autopilot session)
**Companion:** docs/CEM_REFINEMENT_EXTENSION_PLAN_20260530.md (Section 2.1)

## What this session did

Implemented and deployed the highest-leverage refinement from the plan: soft productivity-weighted donor matching for Washington, then launched a smoke test on Cardinal.

### Motivation (verified, not assumed)

The Washington underprediction is a donor growth rate composition problem. The prior productivity experiments on Cardinal confirm productivity-aware matching works but with a cost:

| WA config | hindcast bias | subject plots (cycle 1) |
|---|---|---|
| l7b baseline (no productivity) | -79.4 MMT (-25.0%) | 11,630 |
| prodS (`--use_productivity`, hard cem_prod key) | -39.2 MMT (-19.6%) | 7,288 |
| prodL7b (hard key, tuned) | -27.6 MMT (-13.8%) | 7,421 |

The hard productivity key roughly halves the bias but drops about 37% of subjects that cannot find a donor sharing their asymptotic-AGB bin. R-prodW captures the bias reduction without dropping those plots.

### The R-prodW patch

A new config-gated option weights the per-subject donor draw within each CEM cell by a Gaussian kernel on asymptotic-AGB closeness, rather than forcing a shared bin. High-productivity subjects are steered toward high-productivity donors, but every matched subject is retained.

Mechanism: Efraimidis-Spirakis weighted draw, `rv = u^(1/w)` with `w = exp(-0.5*((donor_asym - subject_asym)/bw)^2)`, taking `slice_max(rv)` per subject. NA-safe (w=1 when either asymptote is missing). Falls back to the original uniform draw when the flag is off, so ME and all prior runs are unchanged.

New flags in `run_projection.R`:
- `--use_prod_weighting` enable soft weighting
- `--prod_weight_bw <Mg/ha>` kernel bandwidth on asymptotic AGB (default 50)

Files patched on Cardinal (backups at `*.bak.prodW_20260530`):
- `R/02_cem_matching.R` broadened the productivity attach gate; carry `donor_asym` into matched pairs.
- `R/05_scenario_biasing.R` weighted draw in `apply_scenario_bias` (BAU) and `select_multi_event_matches` (harvest scenarios).
- `run_projection.R` CLI parsing and CONFIG wiring; sets `options(cem.prod_weighting, cem.prod_bw)`.

Deployed by `scripts/patch_prod_weighting.py` (idempotent, parses clean under R 4.4.0). A copy is committed in this repo at `cem_pipeline_patch/patch_prod_weighting.py`.

### Smoke launched

SLURM job 11105741, `osc/submit_wa_prodW_smoke.sh`, WA RCP 4.5, n_sims 20, cycles 15, tag `rcp45_wear_prodW_l7b`, bandwidth 50. The script runs the projection then the WA hindcast automatically.

Runtime confirmation from the live log:
- `Productivity-weighted donor draw enabled (bandwidth=50 Mg/ha asymptotic AGB)`
- productivity attached 100% on subjects and donors
- CEM matching summary: 14,367 subjects, **14,130 matched (98.4%)**

This is the key proof of concept: R-prodW retains the full subject pool (98.4%) where the hard key kept only ~7,300. The bias result requires the run plus hindcast to finish (about 4 hours).

## Next session (or scheduled check)

1. Read `docs/HINDCAST_WA_RCP45_WEAR_PRODW_L7B.md` (or the dated hindcast output from job 11105741).
2. Compare prodW bias to the -79.4 baseline, -39.2 prodS, -27.6 prodL7b, and check subject retention stayed near 98%.
3. If prodW bias is at or below the prodL7b -13.8% with full retention: it is the new WA matching default. Promote to full production (n_sims 100, both RCPs) using `submit_wa_prodW_smoke.sh` as the template with `--n_sims 100`.
4. Bandwidth sweep if needed: try `--prod_weight_bw 30` (tighter, stronger steering) and `75` (looser) to find the bias/variance sweet spot.
5. Apply the same weighting to the GA overprediction in the opposite direction (GA runs hot; weighting toward slower-growing matched donors plus the rotation-truncation fix in plan Section 2.2).

## Session update (afternoon): WA result confirmed, GA terminal-age fix

### WA prodW result (job 11105741, completed)
Hindcast `docs/HINDCAST_WA_RCP45_WEAR_PRODW_L7B.md`: bias **-15.4%** (-31.3 MMT), subject count 7,416 (same hindcast basis as prodS 7,288 and prodL7b 7,421). Versus baseline -25.0%. So prodW essentially matches the hard-key accuracy (-13.8% prodL7b) while the full statewide projection retains 98.4% of subjects instead of ~63%. A tighter-bandwidth sweep `--prod_weight_bw 30` is running (job 11110875, tag `rcp45_wear_prodW30_l7b`) to see if it closes the 1.6-point gap with prodL7b at full retention.

### GA latent bug found and fixed (R-stateTerm)
The age-class saturation in `R/06_projection_engine.R` read `cfg$terminal_age %||% 120`, but `cfg$terminal_age` is never assigned and the per-state `terminal_age` column in `config/state_constants.csv` (GA 80, WA 200, MN 110) was fetched into `state_const` yet never used for saturation. Every state silently used Maine's 120-year terminal age. Patched (`scripts/patch_state_terminal_age.py`, backup `*.bak.stateTerm_20260530`, committed to repo `cem_pipeline_patch/`) so the ramp uses `state_const$terminal_age`. Direction is correct for both known biases: GA (overpredicts) now attenuates by 80; WA (underpredicts) grows to 200; ME unchanged at 120.

GA smoke running: job 11110930 (tag `rcp45_wear_stateTerm_l7b`, RCP 4.5, n_sims 20), with a dependent auto-hindcast job 11110932 (`afterok`). Compare its bias to the +16% baseline.

### GA next step (not yet done)
The cohort decomposition (`output/ga_l7b_residual_20260524/`) shows plantation-indicative plots (STDORGCD=1, 42% of projected carbon) accumulating high AGC at ages 41 to 80, well past loblolly's real 25 to 35 year rotation. A uniform 80-year terminal age helps but likely will not fully fix it. The targeted refinement is a stand-origin-aware rotation age: planted Southern stands use ~35 (per-row terminal age in `sat_for_age`), gated by a flag. Implement if the stateTerm smoke leaves GA hot.

### Jobs in flight (this project)
| Job | What | Auto-hindcast |
|---|---|---|
| 11110875 | WA prodW bandwidth 30 sweep | yes (in script) |
| 11110930 | GA per-state terminal age smoke | via dep job 11110932 |

(`wa_stwide_v2` 11105683 is a pre-existing unrelated WA statewide run; leave alone.)

## Session update (2026-06-02): results in, next round launched

### WA bandwidth sweep result
| Config | bias | subject pool |
|---|---|---|
| baseline l7b | -25.0% | full |
| prodW bw=30 | -18.9% | full |
| **prodW bw=50** | **-15.4%** | **full (98.4% matched)** |
| prodW bw=75 | running (job 11207019) | full |
| prodS hard key | -19.6% | thinned ~63% |
| prodL7b hard key | -13.8% | thinned ~63% |

bw=30 was worse than bw=50 (too tight a kernel over-restricts donors toward the hard-key behavior). bw=50 is the soft-weighting optimum so far and beats the hard key prodS while keeping the full pool. bw=75 is running to test whether a looser kernel closes the remaining gap to prodL7b (-13.8%) at full retention. Recommendation pending bw=75: adopt the best-bias bw that retains the full pool as the WA matching default, then promote to full production (n_sims 100, both RCPs).

### GA per-state terminal age result (R-stateTerm)
GA moved only +20.4% -> +19.5% (bias +34.5 -> +30.8 MMT). As predicted, a uniform 80-year terminal age is insufficient because planted stands (STDORGCD=1, ~42% of GA projected carbon) over-accumulate well past loblolly's 25-35 year rotation.

### GA plantation rotation age launched (R-plantTerm)
New patch makes the saturation ramp stand-origin aware: planted stands use a configurable rotation age via `--plantation_terminal_age` / `--plantation_growth_start` (off by default, so ME/WA/MN unchanged). Two GA smokes launched:
- job 11207015 (+ dep hindcast 11207016): `--plantation_terminal_age 35 --plantation_growth_start 15`, tag `rcp45_wear_plantTerm_l7b`. The mechanistically indicated fix.
- job 11207017 (+ dep hindcast 11207018): GA with `--use_prod_weighting --prod_weight_bw 50`, tag `rcp45_wear_prodW_l7b`. Free parallel test of whether GA overprediction is also partly donor-growth composition (productivity weighting would steer toward appropriately matched donors).

Compare both to the +19.5% stateTerm and +20.4% baseline. If plantTerm 35 overshoots (GA goes cold), sweep `--plantation_terminal_age 40/45`.

### Patches now in repo cem_pipeline_patch/
`patch_prod_weighting.py` (R-prodW), `patch_state_terminal_age.py` (R-stateTerm), `patch_plantation_term.py` (R-plantTerm). All idempotent, backed up on Cardinal, parse clean under R 4.4.0.

### Note on broader landscape
A separate `cbm_states` project (`~/cbm_states/`, repo holoros/cbm_states) is running a GA statewide array (job 11169031) as part of the expanding PERSEUS multi-model effort (new repos: perseus-forest-intelligence, GCBM2hpc, lsog-ne, disturbance-ne, fvs-conus). That work is independent of fia_cem_projections and was left untouched.

## Open infrastructure note

Repo `R/06_projection_engine.R` is still the older r20 baseline; Cardinal `R/` is the live r21/v4 code that R-prodW patched. Before locking manuscript numbers, promote the Cardinal `R/` tree into the repo (plan Section 5.1) so committed code matches what produced the results. The R-prodW patch script is the model for capturing each delta.
