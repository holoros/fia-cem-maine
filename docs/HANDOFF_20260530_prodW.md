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

## Session update (2026-06-02, later): both outliers solved

### WA productivity-weight bandwidth (full pool throughout)
| bw | bias |
|---|---|
| baseline (none) | -25.0% |
| 30 | -18.9% |
| 50 | -15.4% |
| 75 | **-11.6%** |
| 100 | running (job 11211043) |

Bias improves monotonically as bandwidth widens from 30 to 75 (-11.6% at bw=75 now beats the hard key prodL7b -13.8%, and keeps the full pool). Since bw -> infinity returns to uniform (-25%), the optimum is past 75; bw=100 is running to bracket it. Adopt the best-bias bandwidth as the WA default, then promote to production.

### GA solved by plantation rotation, not productivity
| GA config | bias |
|---|---|
| baseline l7b | +20.4% |
| per-state terminal age (stateTerm, 80yr) | +19.5% |
| productivity weighting (prodW) | +19.5% (no change) |
| **plantation rotation 35yr (plantTerm)** | **+6.5%** |
| plantation rotation 40yr | running (job 11211044) |

The plantation rotation lever (planted stands STDORGCD=1 -> 35yr rotation) brought GA from +20% to +6.5%, inside the gate. Productivity weighting left GA unchanged, a clean confirmation that GA overprediction is plantation accumulation, not donor-growth composition (the opposite of WA). rotation=40 is running to bracket the GA optimum (35 may be near-ideal; 40 should sit slightly higher).

Note: the first GA hindcasts (jobs 11207016/11207018) failed on a hardcoded `--date 20260530` in the dependent scripts while outputs were dated 20260602; re-run with the correct date produced the numbers above. The date is now fixed in `osc/submit_ga_*_hindcast.sh`.

### Status: both levers validated on the full pool
- WA: productivity-weighted donor draw, bw ~75-100, -25% -> -11.6% (or better, pending bw=100).
- GA: plantation rotation ~35yr, +20% -> +6.5%.

### Next steps (queued)
1. Read bw=100 (WA) and rotation=40 (GA) brackets; lock both optima.
2. Promote to production: WA (best bw) and GA (best rotation) at n_sims 100, both RCP 4.5 and 8.5; refresh MN and ME canonical for consistency.
3. PERSEUS integration Track A (see `PERSEUS_CONUS_INTEGRATION_PATHWAY_20260602.md`): generalize `~/perseus_db/adapters/ingest_cem_rcp_scenarios.R` to a `--state` argument, ingest the production CI CSVs (ME/WA/GA/MN) as `cls:"CEM"` engines, run `48_export_api.py`, publish to the explorer. This lights up CEM lines for WA/GA/MN, which currently show none.
4. Track B: port the validated refinements (plantation 35yr rotation, productivity anchoring) into the CONUS YC hybrid owner regimes and re-export.

## CRITICAL correction (2026-06-02 evening): smoke hindcasts were optimistic

The WA production runs (n_sims 100) revealed that the n_sims=20 smoke hindcasts systematically under-sampled the subject pool and overstated the bias improvement. The production projection is byte-consistent with the smoke (cycle-1 BAU carbon 63,342 vs 63,189; weighting activated; 14,130 matched), but the hindcast differs because of subject coverage:

| WA config | n_sims | hindcast subjects | bias |
|---|---|---|---|
| baseline l7b | 100 | 11,630 | -25.0% |
| prodS (hard key) | 20 | 7,288 | -19.6% |
| prodL7b (hard key) | 20 | 7,421 | -13.8% |
| prodW bw50/75/100 (smoke) | 20 | ~7,418 | -15.4 / -11.6 / -11.1% |
| **prodW bw100 (production)** | **100** | **11,614** | **RCP45 -22.9%, RCP85 -21.2%** |

The n_sims=20 hindcasts only cover ~7,400 of the ~11,630 subjects, and that subset is better-predicted, so every smoke (hard key and soft weighting alike) looked far better than it is. At full sample, productivity weighting improves WA by about 2 points (-25.0% to -22.9%), not the ~13 points the smokes implied.

Implications:
1. The production runs are the canonical, trustworthy numbers; the smoke magnitudes are not. Tuning (bandwidth, rotation) must be validated at full n_sims, not n_sims=20.
2. WA prodW is a real but modest improvement. Closing the WA gap further needs another lever (the asymptote-anchoring mechanism from plan Section 2.1, or combining levers), evaluated at full n_sims.
3. GA plantTerm's +6.5% smoke is likewise unconfirmed; the GA production hindcast (running, job 11212498/99) is the real test. Expect it to be less favorable than the smoke.
4. The production runs are still valid outputs and carry the HWP emission (harv_c_* in per_plot, 45.6M rows), so the expansion + HWP + PERSEUS-ingest pipeline can proceed; the correction is to the expected magnitude and narrative, not the run validity.

This was caught by validating at production scale before publishing. The methodology lesson: smokes show direction, production shows magnitude.

## WA asymptote-anchor experiment: NEGATIVE result (2026-06-03)

Full-sample (n_sims 100) WA with prodW bw100 + per-plot asymptote anchor (str 1.0):
RCP45 bias -23.6% (11,614 subjects), slightly WORSE than prodW alone (-22.9%).

The anchor scales growth by (subject_asym/donor_asym)^(strength/n_cycles), assuming
donors have lower carrying capacity. For WA that assumption is wrong: the matched
PNW donor pool (incl. slow-growing high-asymptote old stands) has asymptotes >=
the subjects', so the ratio < 1 and the anchor slightly suppressed growth. WA's
underprediction is growth-rate composition, not carrying capacity, so an asymptote
lever is the wrong instrument. Strength tuning won't fix a direction error.

WA full-sample ladder (the trustworthy numbers):
| config | bias |
|---|---|
| baseline l7b | -25.0% |
| prodW bw100 | -22.9% (RCP45) / -21.2% (RCP85) |
| prodW bw100 + asym anchor str1.0 | -23.6% (RCP45) |

**Conclusion: prodW bw100 is WA's best (-22.9%), a modest ~2-point gain. Two
donor-side levers (soft weighting, asymptote anchor) have now been exhausted with
small effect.** Closing WA further needs a different instrument (the west/east
Cascades matching-key split from plan Section 2.1 mechanism 2, or importing a
process/empirical growth model for PNW), which is a strategic build, not more
donor-pool tuning. Recommend pausing WA donor tuning and treating prodW bw100 as
the canonical WA run (it carries the HWP emission).

Operational notes this round: WA anchor hindcasts initially failed on the
midnight date-rollover (run started 6/2, finished 6/3; output dir dated 6/2,
inline hindcast looked for 6/3) and were re-run with --date 20260602. GA n_sims
100 OOM'd at 200G once the harv_c_*/donor_asym columns inflated memory; resubmitted
on hugemem exclusive nodes (jobs 11229000/01, 2TB, both RCPs).

## Open infrastructure note

Repo `R/06_projection_engine.R` is still the older r20 baseline; Cardinal `R/` is the live r21/v4 code that R-prodW patched. Before locking manuscript numbers, promote the Cardinal `R/` tree into the repo (plan Section 5.1) so committed code matches what produced the results. The R-prodW patch script is the model for capturing each delta.
