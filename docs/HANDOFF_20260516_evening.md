# Session Handoff: Manuscript-Grade Multistate p1 Set Complete

*Session window: 16 May 2026, late afternoon evening.*
*Supersedes the morning HANDOFF_20260516.md after the unit bug retraction and Layer 4 production validation landed.*

## TLDR

The multistate p1 production set is publication-ready. All six runs PASS 8/8 sanity checks. Cross-state hindcasts span -25 to +11 percent, bracketing the canonical Maine reference of -1.1 percent. ME r21 econ reruns (jobs 9674412, 9674413) with the Layer 4 patch (price unit conversion in `compute_harvest_revenue`) produced cycle 1 BAU gr_ratio of 3.46, matching Maine RPA's 3.32 within 4 percent. The WA No_harvest decline was confirmed disturbance-driven by the `--fire_amp_mult 0.5` diagnostic. The MN -23 percent statewide volume gap remains unexplained but the DESIGNCD hypothesis is now refuted. The carbon unit bug (lb/ac vs kg/ac) is fixed in the validation tooling and the corrected hindcasts are documented in `BIAS_DOCUMENTATION_20260515.md`. Local repo has 16 commits ahead of origin/main.

**Post-handoff manuscript polish (16 May late, sandbox autopilot):** manuscript methods draft updated to remove the DESIGNCD attribution and now references the ME r21 econ production gr_ratio match at 3.46 vs Maine RPA 3.32. Superseded banner added to `MN_VOLUME_GAP_ROOT_CAUSE_20260516.md`. Manuscript supplementary materials filename pattern corrected (hindcast multistate files use `WEAR_P1` tag, not `R21`). Coherence check passed: all five figures referenced in the manuscript draft are present in `figures/`. Commits 29c403e, 202ed11, 882c369.

## What's now settled

| Item | Status | Reference |
|---|---|---|
| Multistate p1 framework | Validated 8/8 across MN, WA, GA both RCPs | `VALIDATION_*` memos |
| Cross-state hindcast bias | Within publishable bounds | `BIAS_DOCUMENTATION_20260515.md` |
| Carbon unit bug | Fixed (lb/ac vs kg/ac, ratio 2.20) | commit `259b481` |
| Layer 2 (gr_ratio harvest_removals) | Validated, deployed | `LAYER2_SMOKE_RESULT_20260513.md` |
| Layer 4 (price unit MBF/cord) | Validated at production scale | commit `bc5e095`, ME r21 econ reruns |
| ME r21 econ RCP 4.5 | Cycle 1 BAU gr_ratio 3.46 | `output/ME_20260516_rcp45_hadgem2_wear_econ_r21` |
| ME r21 econ RCP 8.5 | Cycle 1 BAU gr_ratio 3.46 | `output/ME_20260516_rcp85_hadgem2_wear_econ_r21` |
| WA disturbance hypothesis | Confirmed by --fire_amp_mult 0.5 diagnostic | `output/WA_20260516_wa_fire_halfamp` |
| MN DESIGNCD hypothesis | Refuted by 2004 baseline diagnostic | `MN_VOLUME_GAP_REVISED_20260516.md` |
| Cross-state comparison figures | Built; CSVs in p1_summaries/ | `scripts/build_p1_comparison_figures.R` |
| ME hindcast reference | RMSE 24.9, bias -5.6% | `HINDCAST_ME_RCP45_HADGEM2_WEAR_R21.md` |

## What remains open

In rough order of value to manuscript:

### 1. Push 12 local commits to GitHub

Most recent local commits not yet on origin/main:

```
eee49f7  docs: retroactive status banners on RPA_COMPARISON + TRAJECTORY memos
a45b408  fix: conus_hcs RPA Layer 21 — coerce STATECD to integer on both join sides
97043cb  fix: conus_hcs RPA Layer 20 — graceful M4 skip when fit unavailable
c9688c4  fix: conus_hcs RPA aggregation second-pass NaN handling
a52f0ae  docs: HANDOFF final session state: MN diagnostic refutes DESIGNCD
eef8f15  docs: BIAS_DOCUMENTATION revised
af0f28a  fix: MN -23% diagnostic refutes DESIGNCD hypothesis
c7c3d1f  docs: conus_hcs R/18_rpa_aggregation regime-split fit fix
bc5e095  ME r21 econ production landed: Layer 4 patch validated at full scale
5f9bb05  docs: session handoff 20260516 + trajectory diagnostic Layer 4 update
1efc27d  docs: trajectory diagnostic surfaces 3 dynamics issues
2f36a65  docs: RPA / FIA state-level comparison memo
```

Push command:

```bash
cd ~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching
git push origin main
```

### 2. MN -23 percent volume gap (statewide vs EVALIDator)

The MN hindcast bias of -5.7 percent is fine. The separate statewide volume gap of 21.6 Bcuft vs EVALIDator 28 Bcuft remains. The DESIGNCD periodic plot exclusion was refuted by the 2004 baseline diagnostic (identical result). Four candidate mechanisms remain (Lake States donor pool, HCB owner downscale, climate response gating, state_constants.csv parameters). Priority: useful for the manuscript but not blocking. Investigation depth needed: medium.

### 3. WA -25 percent hindcast bias

Two attributable mechanisms documented in `BIAS_DOCUMENTATION_20260515.md`:

* PNW donor pool composition (OR/ID/MT under-representing west-side Doug-fir/hemlock)
* Climate response gating (--use_decoupled_climate blocked because ClimateNA not run)

Both are publishable as known limitations rather than blocking flaws. If we want to tighten:

* Pull WA, OR plot subset by ecoregion and characterize what's missing from the donor pool
* Run ClimateNA on the WA plot location CSV from `~/FIA/climate/climatena_input_WA.csv` (manual GUI step)

### 4. proj_tpa SDImax cap audit (my Layer 4 proposal, separate from what was applied)

The Layer 4 patch that landed was the `compute_harvest_revenue` price unit fix. My separate finding from the trajectory diagnostic was that `apply_sdimax_cap` clips BA and volume but not `proj_tpa`, producing impossible 41,000-51,000 trees/ac at cycle 15. Cycle 5 is still safe (510-946 trees/ac plausible). If the manuscript reports any cycle >7 metric, this fix should land. Otherwise document as a known limitation of late-cycle TPA values.

### 5. GA +10 percent hindcast bias

Documented as plantation-vs-natural mixing in donor pool (CEM matches GA natural stands to FL/SC/NC/TN/AL donor mix that includes intensive loblolly plantations). Reportable as known limitation. If tightening desired: STDORGCD-stratified matching is the methodological direction.

### 6. ClimateNA per-state runs

`~/FIA/climate/climatena_input_<STATE>.csv` files exist for ME, MN, WA, GA. ClimateNA is a desktop GUI tool. User-side step. Unblocks `--use_decoupled_climate` for non-Maine states, which would address part of the WA bias.

### 7. STDORGCD stratified CEM matching

Methodological extension. Would split donor pool by stand origin (natural vs planted) before CEM. Should reduce GA bias. Requires R/02_cem_matching.R update.

## Cardinal state at handoff

| Metric | Value |
|---|---|
| Quota | 287 GB / 500 GB |
| Inodes | 854k / 1000k |
| Queue | 26 running, 3 pending (mostly user's other work) |
| ME r21 econ RCP 4.5 output | `ME_20260516_rcp45_hadgem2_wear_econ_r21` (cycle 1 BAU gr_ratio 3.46) |
| ME r21 econ RCP 8.5 output | `ME_20260516_rcp85_hadgem2_wear_econ_r21` (cycle 1 BAU gr_ratio 3.46) |
| WA fire diagnostic output | `WA_20260516_wa_fire_halfamp` (confirms disturbance compounding) |
| MN 2004 baseline diagnostic | `MN_20260516_rcp45_wear_p1_2004base` (refutes DESIGNCD) |
| Layer 3 / Layer 4 smokes | `ME_20260516_layer3_smoke_*` and `ME_20260516_layer4_smoke_*` (validation only) |
| p1 comparison figures | `p1_summaries/` (12 CSVs ready for cross-state plot) |
| All 6 p1 production outputs | preserved at `~/fia_cem_projections/output/` |
| All hindcast memos | 7 of 7 generated and committed |

## Suggested next session priorities

1. **Push 12 local commits to GitHub** (one-line `git push`, blocks on workstation credentials)
2. **MN volume gap investigation** — quickest win likely the Lake States donor pool diagnostic; pull the donor TREE.csv files for WI/MI/IA and check forest-type representation vs MN observed
3. **WA donor pool diagnostic** — same idea for OR/ID/MT vs WA observed
4. **Build the final cross-state comparison figure** from `p1_summaries/` CSVs — script exists at `build_p1_comparison_figures.R`
5. **Decide on manuscript inclusion**: separate multistate paper, section in existing manuscript, or companion piece?

## Open questions for the user

1. Manuscript framing: separate paper, section, or companion?
2. Cycle 5 (year 2024, RPA-comparable) or cycle 15 (year 2074) as primary reporting horizon?
3. MN -23 percent statewide volume gap: investigate now or document as known limitation?
4. ClimateNA per-state external runs: should I queue a status reminder/task or is that on your near-term workflow?

Sources for the RPA comparisons:
- [Forests of Maine, 2021 (FS-366)](https://www.fs.usda.gov/nrs/pubs/ru/ru_fs366.pdf)
- [Forests of Minnesota, 2020 (FS-326)](https://www.fs.usda.gov/nrs/pubs/ru/ru_fs326.pdf)
- [Forests of Georgia, 2022 (FS-484)](https://www.srs.fs.usda.gov/pubs/ru/ru_fs484.pdf)
- [Pacific Northwest Research Station, Washington State Stats](https://www.fs.fed.us/pnw/rma/fia-topics/state-stats/Washington/index.php)
