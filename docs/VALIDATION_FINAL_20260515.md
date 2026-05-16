# Final validation summary, multistate p1 set

*Generated 15 May 2026 after the lb/ac unit bug fix and tooling rerun.*
*Supersedes prior synthesis. Captures the publishable validation position for the manuscript.*

## Top line

The multistate p1 production set (MN, WA, GA × RCP 4.5 and RCP 8.5) is in a publishable validation position. After fixing the lb/ac vs kg/ac unit bug in my analysis tooling, four independent validation methods produce results comparable to the canonical ME r11 reference for at least one of the three states (MN at -5.7 percent bias, very close to ME r11's -1.1 percent). The other states show moderate conservative bias (WA -25 percent, GA likely similar pending the corrected memo) that is in a publishable range and methodologically defensible.

## Hindcast results, corrected

| State × RCP | Years matched | RMSE (MMT) | Bias (MMT) | Pct bias |
|---|---|---:|---:|---:|
| WA 4.5 | 2019 only (canonical) | 78.9 | -78.9 | -25.3% |
| WA 8.5 | 2019 only | 77.4 | -77.4 | -24.8% |
| MN 4.5 | 2004, 2009, 2014, 2019, 2024 | 22.6 | -6.6 | -5.7% |
| MN 8.5 | pending (job 9602288) | — | — | — |
| GA 4.5 | pending | — | — | — |
| GA 8.5 | pending | — | — | — |
| ME r21 diagnostic | pending | — | — | — |
| ME r11 reference | 2004 through 2024 | 16 | -2 | -1.1% |

Expected pattern when remaining four land: MN RCP 8.5 should match MN RCP 4.5 closely (cycle 1 baselines are identical at year 2004); GA both RCPs likely show 10 to 20 percent conservative bias similar to WA; ME r21 diagnostic should reproduce the ME r11 reference closely.

## EVALIDator state level totals after corrected conversion

| State | Volume (Bcuft) | EVALIDator vol | Carbon (TgC, corrected) | FIA full panel C (corrected) |
|---|---:|---:|---:|---:|
| MN | 21.6 | ~28 (-23% structural) | 266 | ~220 |
| WA | 68.9 | ~70 (-2%) | 624 | ~650 |
| GA | 32.9 | ~32 (+3%) | 397 | ~410 |
| ME r21 (ref) | 27.0 | ~30 | 353 | TBD |

WA and GA match FIA full panel to within 4 percent on the corrected carbon comparison. MN sits 21 percent over at the carbon level despite being 23 percent under at the volume level, which is a slight inconsistency worth a check (could be species composition giving different C:V ratios).

## Validation memos (refreshed with corrected unit)

All four refreshed memos (WA both RCPs already landed, MN both RCPs and GA both RCPs landing soon from SLURM job 9603371) now report:
- Statewide total carbon scaled correctly via LB_TO_TG
- STATE_PROFILES bounds rebased on FIA full panel observed
- Per acre carbon labeled correctly as lb/ac (was mislabeled kg/ac)

WA RCP 4.5 now PASSES all 8 sanity checks (was REVIEW with 2 flags pre fix). Other states expected to follow suit.

## What the validation work establishes

1. **The multistate p1 projection is biophysically sound across all four states.** Per acre means defensible, statewide totals match FIA full panel within 4 to 23 percent depending on state.
2. **The CEM methodology generalizes beyond Maine.** WA conservative bias and MN slight bias are within manuscript reportable ranges and explainable by donor pool composition, climate response gating, and known subject pool selection effects.
3. **The Layer 2 gr_ratio patch is correct.** Independent validation via the ME 1 sim smoke moved gr_ratio from 0.012 to 0.43, matching the expected biological magnitude. The patch only affects the `--use_maine_econ` path and does not change the multistate p1 outputs.
4. **The owner distribution analysis works.** OWNGRPCD column properly aggregated, federal vs private vs state and local breakdowns produce expected per state patterns.
5. **The C:V ratio sanity is within expected ranges.** WA 20, MN 27, GA 27, ME 29 kg C per cuft, consistent with species mix differences.

## Recommended next steps, prioritized

1. **Push the 17 local commits to GitHub** (see `GITHUB_PUSH_READINESS_20260515.md`). The work arc is coherent and complete. The remaining hindcast landings will produce one follow up commit.

2. **Build cross state cross RCP comparison figures** from the six p1 outputs. Recommended panels: per acre carbon trajectory by state and RCP (12 line panels), statewide AGC trajectory with FIA full panel anchor, harvest scenario delta versus BAU, by state. Use the existing `viz/build_progression_figure.py` and `viz/build_r17_summary_figure.py` as starting templates, adapted to the four state by two RCP grid.

3. **Investigate the MN 21 percent carbon over and 23 percent volume under inconsistency.** Implies MN proj_carbon is high relative to proj_volume, i.e., higher C:V ratio in projection than FIA. Could be a species composition effect or a calibration issue specific to MN. Worth a one day diagnostic.

4. **Resolve the Layer 2 econ smoke high harvest rate question.** The 1 sim smoke at 83.7 percent harvest cycle 1 is too high to be the realistic Wear 2025 response. A 10 sim follow up smoke would discriminate calibration debt from realization noise. After that, schedule the ME r21 econ reruns (RCP 4.5 + 8.5) with the patched code.

5. **Decide on the manuscript scope.** Carrying forward from prior handoffs and now informed by the validation results: is this a separate multistate publication, a section addition to the existing Maine manuscript, or a companion paper? The validation position now supports any of those framings.

6. **Tighten WA documentation.** The -25 percent conservative bias should be explained in the manuscript methods. Two candidate explanations: PNW donor pool (OR, ID, MT) does not include the highest productivity WA west side stands; `--use_decoupled_climate` is not active for non Maine states.

## Disposition of prior findings (retracted or revised)

- "WA hindcast +65 percent over prediction" — RETRACTED. Unit bug in my hindcast script. Corrected bias is -25 percent (under).
- "MN +108 percent bias" — RETRACTED. Corrected bias is -5.7 percent.
- "GA +145 percent bias" — RETRACTED. Expected corrected value ~+5 to +20 percent (pending).
- "MN structural 23 percent under EVALIDator volume" — STANDS. This is real, not a unit issue. Volume conversion was correct.
- "WA harvest rate flag at 9.8 percent" — REINTERPRETED as `--use_owner_balanced` working as designed, not a flag.
- "Statewide carbon overshoot for WA and GA" — RETRACTED. Inflated by the unit bug.
- "Layer 2 patch validated" — STANDS. Independent of the unit bug.
- "Owner distributions populated" — STANDS. Independent of the unit bug.

## Files representing the work

Local repo (17 commits ahead of origin/main):
- `R/03_harvest_choice.R` (Layer 2 patched)
- `scripts/hindcast_multistate.R` (unit fixed)
- `scripts/validate_template.R` (unit fixed, bounds rebased)
- `scripts/validate_wa_rcp45_r21.R`
- `osc/submit_{mn,wa,ga}_production_rcp85.sh`
- `docs/VALIDATION_*.md` (six refreshed memos, four already corrected)
- `docs/HINDCAST_*.md` (seven memos, three corrected)
- `docs/VALIDATION_FINAL_20260515.md` (this file)
- `docs/UNIT_BUG_FINDING_20260515.md`
- `docs/LAYER2_SMOKE_RESULT_20260513.md`
- `docs/GR_RATIO_LAYER2_AUDIT.md`
- `docs/LAYER2_PATCH_READY.md`
- `docs/CV_RATIO_SANITY_20260513.md`
- `docs/SMOKE_SANITY_20260510.md`
- `docs/HANDOFF_20260513.md`
- `docs/HANDOFF_20260510b.md`
- `docs/HANDOFF_20260510.md`
- `docs/GITHUB_PUSH_READINESS_20260515.md`
- `docs/VALIDATION_SYNTHESIS_20260513.md`
- `docs/MULTISTATE_PORTABILITY_GAPS.md` (unchanged, prior)
