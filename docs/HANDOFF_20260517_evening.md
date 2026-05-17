# Session handoff 17 May 2026 evening: cascade complete, mechanisms tested

*Supersedes `HANDOFF_20260516_evening.md` after the 17 May autopilot push.*

## TLDR

Three full diagnostic mechanisms tested against the multistate bias documentation in a single session. WA -25 percent bias mechanism is **confirmed** as donor pool composition (hemlock/Sitka spruce -11.1 pp gap, Doug-fir -9.0 pp gap, interior pine over-representation). GA +10 percent bias hypothesis is **refuted**; the simple plantation/natural donor mixing pathway does not explain the over (GA has more plantation types than its donor pool, not less). A simple geographic Remediation Path 1 for WA (OR west-of-Cascade) is **also refuted** as it over-corrects toward Douglas-fir dominance, recommending Bailey ecological section or forest type as CEM matching covariate instead. The SDImax cap proj_tpa audit produced a one-line Layer 6 patch that is staged but not deployed pending manuscript horizon decision. The conus_hcs RPA aggregation pipeline cascaded through 5 patch layers and now produces all 4 RPA subregion outputs; p_harvest saturation 0.86-0.91 attributable to re-measured panel pair training-frame bias, confirmed across 2 independent M1 prediction frameworks. Local repo at 29 commits ahead of origin/main.

## What was tested and learned

| Question | Method | Answer |
|---|---|---|
| Does the simple plantation/natural donor mixing explain GA +10 percent? | FORTYPCD diagnostic, GA vs FL/SC/AL/TN | **No.** GA 43 percent plantation indicative vs donor 30 percent. Wrong direction. |
| Does PNW donor pool composition explain WA -25 percent? | FORTYPCD diagnostic, WA vs OR/ID/MT | **Yes.** Hemlock -11.1 pp, Doug-fir -9.0 pp, interior pine over by 13 to 15 pp combined. |
| Does the M1 saturation come from a Layer 19 union approximation bug? | Compare brms regime-split vs unified TM2016 fit | **No.** Both prediction sources return median 0.85-0.90; saturation is a model property. |
| Does the apply_sdimax_cap actually clip TPA? | Codebase audit at R/06_projection_engine.R L742-765 | **No.** Bug confirmed; one-line Layer 6 fix proposed; cycle 15 TPA would drop 41k to 2k. |
| Would a simple OR west-of-Cascade donor restriction fix the WA bias? | Prototype with LON < -122 cutoff | **No.** Total absolute gap rises 0.401 to 0.457 by overshooting Douglas-fir. |
| Does WA-as-own-donor improve the match? | Prototype OR west + WA west | **Partially.** Hemlock gap drops 11.1 to 2.8 pp; Doug-fir still 14.5 pp over. |
| Where does conus_hcs RPA aggregation NA p_harvest come from? | Direct inspection vs unified TM2016 | brms posterior_epred returns NA for plots out of training scope; 47 percent of 162,139 plots affected; not blocking aggregation. |
| Do the conus_hcs predictions match the regional pattern? | Layer 22 patch + aggregation completion | Aggregation produces 4 subregions (NC, SE, SC, PNW); removal magnitudes plausible; p_harvest values inflated by training frame bias. |

## What changed in the manuscript and bias documentation

- `BIAS_DOCUMENTATION_20260515.md`: WA section updated with confirmed donor pool mechanism + remediation paths; GA section updated to remove refuted hypothesis and document 4 alternative candidates; MN section already updated with refuted DESIGNCD hypothesis.
- `MULTISTATE_METHODS_DRAFT_20260515.md` Section X.2 and limitations both reflect: confirmed WA mechanism, refuted GA hypothesis with alternatives, refuted MN DESIGNCD with alternatives.
- 5 new diagnostic memos at `docs/`: WA_DONOR_POOL_DIAGNOSTIC, GA_DONOR_POOL_DIAGNOSTIC, WA_WESTSIDE_DONOR_PROTOTYPE, SDIMAX_TPA_AUDIT, RPA_AGGREGATION_RESULTS.
- 6 new figures at `figures/`: wa_donor_pool_diagnostic.png, ga_donor_pool_diagnostic.png, wa_westside_donor_prototype.png, rpa_subregion_panel.png, rpa_p_harvest_by_subregion.png, rpa_removal_per_ha_by_subregion.png plus all underlying CSVs.

## What remains for the user

In order of decision urgency:

### 1. Manuscript horizon decision (blocks two other decisions)

- **Cycle 5 (2024) horizon, RPA comparable:** No production rerun needed. Layer 6 SDImax patch documented as known limitation only. Manuscript ships with existing p1 outputs.
- **Cycle 10 (2049) horizon:** Layer 6 patch should land; modest changes expected to cycle 10 values.
- **Cycle 15 (2074) horizon:** Layer 6 patch must land; substantial changes to cycle 15 TPA and downstream metrics. Rerun the multistate p1 set required.

### 2. WA bias remediation path selection

If the manuscript will report the WA result with bias correction, the prototype refutes the simple OR westside cut. Three remaining paths in order of effort:

- **Path 2 (WA-as-own-donor leave-one-out):** 3 hr; reduces hemlock gap from 11.1 to 2.8 pp but leaves Doug-fir over-represented.
- **Path 3 (Bailey section as CEM covariate):** 4 to 8 hr; methodologically cleanest.
- **Path 4 (FORTYPCD as CEM covariate):** 2 hr; risk of empty cells.

If the manuscript will report the WA result with bias **documented as a known limitation only**, no remediation work required and the existing -25 percent is the published number.

### 3. GA bias mechanism investigation

The refuted plantation/natural hypothesis needs replacement. Four candidates (in order of plausibility):
- Growth ratio multiplicative effect on high-productivity baseline
- C:V ratio over-estimation in plantation types
- Disturbance schedule mis-specification
- Stand age saturation under-application

Each can be tested with a focused diagnostic at roughly 2 to 4 hours of work.

### 4. Blocking external steps

- **Push 29 commits to GitHub** from workstation: `cd ~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching && git push origin main`
- **Transcribe Johnston Guo Prestemon 2021 RPA baselines** into `~/conus_hcs/config/rpa_baselines.csv` (web fetch blocked in sandbox); after transcription rerun the aggregation to populate `pct_diff` column.
- **Pull FIA Lake States COND data** for WI, MI, IA, IL, ND, SD into `~/fia_data/` so the MN donor pool diagnostic can run. Also pull FIA southern COND with STDORGCD and CONDPROP_UNADJ for FL, SC, NC, AL, TN if the GA STDORGCD diagnostic is to be repeated.

## Commits

Latest 14 commits on this leg (29 total ahead of origin/main):

```
e300ad2 WA westside donor prototype: simple LON cut REFUTES Remediation Path 1
c762b01 docs: manuscript methods updated with confirmed WA mechanism + refuted GA hypothesis
6473278 GA donor pool diagnostic REFUTES original hypothesis
f63df04 audit: SDImax cap leaves proj_tpa unscaled
0fff0e6 WA donor pool diagnostic confirms mechanism
77c9999 docs: RPA p_harvest saturation confirmed across 2 independent M1 frameworks
4e421db figs: RPA subregion panel visualization
9dc141a docs: RPA p_harvest saturation root cause identified
ffe3b45 docs: handoff captures Layer 22 RPA aggregation success
c2093cb docs: RPA aggregation results expanded with full 12-state STATECD breakdown
ad912f0 RPA aggregation Layer 22 success
36cbdca fix: conus_hcs RPA Layer 22 column collision drop
882c369 docs: fix supplementary materials filename pattern
202ed11 docs: superseded banner on MN_VOLUME_GAP_ROOT_CAUSE
```

## Cardinal state at handoff

- conus_hcs RPA aggregation Layer 22 deployed; SLURM 9717200 completed 16:38 with exit 0
- Backup of pre-Layer-22 script at `~/conus_hcs/R/18_rpa_aggregation.R.preupdate.20260516_layer22`
- Phase 4 outputs at `~/conus_hcs/output/phase4/` and pulled to local `figures/`
- fia_cem_projections wa_donor_diagnostic_20260516, ga_donor_diagnostic_20260517, wa_westside_donor_20260517 output directories all populated and pulled
- ME r21 econ production preserved at `~/fia_cem_projections/output/`
- All 6 multistate p1 production runs preserved
- Queue clean (no in-flight jobs at end of session)
