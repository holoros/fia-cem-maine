# Comprehensive handoff: FIA CEM multistate carbon projection

*Generated 20 May 2026, late evening. This is the master handoff. It supersedes `HANDOFF_20260520.md` and `HANDOFF_20260520_evening.md` and consolidates the full project state, the scientific arc, every in-flight job, the reusable infrastructure, and the next session's playbook into one document.*

---

## 1. One paragraph orientation

This project quantifies cross-state bias in Coarsened Exact Matching (CEM) forest carbon projections built on FIA data, identifies the mechanism, and deploys the fix. The headline scientific result of this arc: ecoregion stratification added to the CEM matching keys is necessary but **not sufficient** to reduce cross-state bias, because the bias-driving subject cells (Washington west side Douglas fir and hemlock/Sitka spruce) have zero ecologically matched donors in their neighbor-state cohort and fall through the three-tier matching fallback to the unstratified iteration. The real fix is a CONUS-wide donor pool defined by ecoregion membership. That fix is now validated at the matching level (WA iteration 1 fine-resolution match rate rose from 62 percent to 81 percent once California coastal donors were added to the pool), and the final production bias number is in flight on Cardinal as of this writing.

---

## 2. The scientific arc, start to finish

The narrative is a clean four-step methodological contribution that is publishable as a complete arc:

1. **Cross-state CEM hindcast bias spans roughly minus 25 to plus 11 percent** across the four test states (ME, WA, MN, GA). The mechanism is donor pool composition: a subject state's projections inherit the growth trajectories of whichever donors the matcher selects, and neighbor-state donor cohorts can be ecologically wrong.

2. **Ecoregion as a matching key alone does NOT reduce bias.** The Layer 7b patch added `cem_ecoregion` (EPA L3 ecoregion, coarsened across the three CEM iterations) to the matching keys. Production hindcasts: WA RCP 4.5 l7b bias was minus 79.4 MMT versus the p1 baseline of minus 78.9 MMT, statistically identical. The ecoregion attribute joined at 99.9 percent, so this is not a coverage problem. The bias-driving cells simply have no same-ecoregion cross-state donor in the OR/ID/MT cohort, so the matcher drops ecoregion at iteration 3 and lands on the same interior-pine donors as the unpatched run. WA iteration 1 fine match rate was only 62 percent (versus 92 percent in the Maine-only smoke), which is the fingerprint of cells falling through.

3. **The fix is a CONUS-wide ecoregion-membership donor pool.** Draw donors from all available states; let the deployed `cem_ecoregion` key restrict actual matches to same-ecoregion donors. Demonstrated at the matching level: after downloading California from the FIA DataMart and enabling `--conus_donors`, WA iteration 1 fine match rate jumped from 62 percent to 81 percent. The west side Douglas fir and hemlock/Sitka spruce subjects that previously had no ecologically matched cross-state donor now match California coastal donors at the strictest ecoregion x FORTYPCD x OWNGRPCD tier instead of falling through to iteration 3.

4. **[In flight] The resulting hindcast bias reduction.** The full WA conus production run plus hindcast will produce the final number. Expectation: WA conservative bias drops from roughly minus 25 percent toward minus 10 percent or better, because the west side subjects now inherit genuinely high-productivity CA/OR coastal trajectories rather than interior-pine trajectories.

An independent corroboration arrived overnight from the p3 validation wave (`P3_VALIDATION_COMPLETE_20260520.md`): MN v3 cycle 4 bias moved from plus 6.8 percent to minus 0.5 percent, a clean win in exactly the case where donors share ecoregions; WA stayed at minus 25 percent, confirming that "v3 cleans up strata but cannot manufacture donors"; GA showed a plantation artifact. This is the same finding reached by a different route.

---

## 3. In-flight Cardinal jobs (status as of 20 May ~22:45)

Queue is down to 65 jobs total (was 143 earlier today, which had blocked submission).

| Job ID | Name | State | Elapsed | Node | What it produces |
|---|---|---|---|---|---|
| 10128559 | wa_conus_prod | RUNNING | ~6 min | c0249 | WA RCP 4.5, 100 sims, 15 cycles, `--conus_donors` 19-state pool with CA. The final WA bias number. |
| 10128560 | wa_conus_prod85 | PENDING (Resources) | 0 | queued | WA RCP 8.5 companion run. |
| 10124341 | fia_mn_hm | RUNNING | ~31 min | c0304 | MN RCP 4.5 Layer 7b hugemem rerun (480 GB, after 180 GB OOM). |
| 10124342 | fia_mn_hm_85 | RUNNING | ~28 min | c0236 | MN RCP 8.5 Layer 7b hugemem rerun. |
| 10124343 | fia_ga_hm | RUNNING | ~28 min | c0304 | GA RCP 4.5 Layer 7b hugemem rerun. |
| 10124344 | fia_ga_hm_85 | RUNNING | ~27 min | c0236 | GA RCP 8.5 Layer 7b hugemem rerun. |

None of these have landed `per_plot` RDS outputs yet. They are 100-sim, 15-cycle production runs and will take hours. The MN/GA reruns went to hugemem at 480 GB / 48 CPU (10 GB/CPU, within the hugemem 19.4 GB/CPU QOS cap) after the standard-partition 180 GB attempt OOM'd from the added ecoregion matching cells and per_plot RDS columns.

Also visible in the queue but belonging to other workloads (do not touch): the `gat2nd7_c0` job array (10128277), `conus_map_phase5_v2` (10125477), `mn_t2_drv` (10124727), `ga_t2_drv2` (10021254).

---

## 4. The data unblock (the thing that was actually blocking)

The CONUS donor experiment was blocked for most of the day because Cardinal's `~/FIA/ENTIRE_TREE.csv` is a **partial** download covering only 11 states (STATECDs 9, 13, 23, 25, 27, 33, 36, 41, 44, 50, 53 = CT, GA, ME, MA, MN, NH, NY, OR, RI, VT, WA). The `ENTIRE_COND.csv` and `ENTIRE_PLOT.csv` have full CONUS coverage, but TREE does not. California (STATECD 6), the critical ecological donor for WA west side, had COND and PLOT but no TREE anywhere on Cardinal. `scripts/extract_western_states.R` (which slices western states out of the ENTIRE_*.csv files) returned 0 TREE rows for all 7 western states as a result; the incomplete COND/PLOT files were quarantined to `~/fia_data/_incomplete_western_20260520/` so they would not break the read_fia_direct loader.

**Resolution:** Cardinal can reach the FIA DataMart directly (verified HTTP 200). California was downloaded fresh:

- `CA_COND.csv` (16 MB)
- `CA_PLOT.csv` (9.2 MB)
- `CA_TREE.csv` (261,369,114 bytes exact)

California is now a complete state in `~/fia_data` with COND + PLOT + TREE. `get_all_available_states()` picks it up, and `--conus_donors` includes it. The active donor pool is 19 states: AL, CA, CT, FL, GA, ID, MA, ME, MN, MS, MT, NH, NY, OR, RI, SC, TN, VT, WA.

**Remaining western data gap (optional, for completeness):** if a future run wants the full Pacific marine plus montane donor universe, download the remaining western TREE tables from the FIA DataMart (AZ, CO, NV, NM, UT, WY, plus WI/MI/IA/IL/ND/SD for the Lake States). Direct per-state CSV bundles live at `https://apps.fs.usda.gov/fia/datamart/CSV/<XX>_TREE.csv`. This download must happen on Cardinal (which has internet); the analysis sandbox cannot fetch fs.usda.gov. Also note `CA_TREE_GRM_COMPONENT` (about 72 MB) is not yet downloaded and would be needed only if a hindcast or validation requires growth components rather than the standard live-tree accounting.

---

## 5. Code state: what changed and where

All changes are committed and pushed. Local HEAD `7c9a9e2` equals `origin/main` `7c9a9e2` on `holoros/fia-cem-maine`. 186 commits total spanning 29 Apr to 20 May 2026.

**`R/02_cem_matching.R` (Layer 7b ecoregion patch).** Added a `coarsen_ecoregion(l3code, level, l3_to_section_lookup)` helper that returns a CHARACTER at all three levels (level 1 = the L3 code as character; level 2 = Bailey-equivalent section from the crosswalk; level 3 = "0", i.e. dropped). Added `cem_ecoregion` to the iter1/iter2/iter3 coarsening and to the `build_cem_key` key columns. The Layer 7b revision fixed a vctrs integer/character combine error by casting every level to character. Backup at `R/02_cem_matching.R.preupdate.20260517_ecoregion`. The exact patched matcher is archived as manuscript supplement `supplement_S4_cem_layer7b_patched.R`.

**`run_projection.R` (`--conus_donors` flag).** Added the CLI flag, a `get_all_available_states()` helper that returns every state with a `_COND.csv` in `FIA_DATA_DIR` (two-letter postal codes only), and a conditional that sets `CONFIG$donor_states <- get_all_available_states()` when the flag is present. Opt-in; default neighbor-cohort behavior is unchanged. Backup at `run_projection.R.preupdate.20260520_conus_donors`. The neighbor cohorts remain hardcoded in `get_donor_states()` (e.g. WA = c("WA","OR","ID","MT")) for the default path. The patch script that applied this is `apply_conus_donors_patch.py` in outputs.

**`config/l3_to_section.csv`** maps 85 EPA L3 ecoregions to 20 Bailey-equivalent sections (the level-2 coarsening crosswalk).

**`config/rpa_baselines.csv`** (Cardinal side) holds the 2020 RPA Assessment Chapter 6 removal baselines: 2016 CONUS 13 Bcuft/yr; regional shares N 19.2 percent, S 60.4 percent, PC 17.3 percent, RM 3.1 percent. Built by `scripts/build_rpa_baselines_from_chapter6.R`.

The repo carries 7 core `R/` modules (01_data_prep, 02_cem_matching, 03_harvest_choice, 05_scenario_biasing, 06_projection_engine, 10_state_expansion, 11_economic_harvest), 61 `scripts/`, 30 `config/` CSVs, and 81 `docs/` memos.

---

## 6. GitHub push mechanism via Cardinal (reusable, important)

The analysis sandbox has no GitHub credentials, so direct `git push` fails. The working mechanism, which should be reused every session:

1. On the sandbox, bundle the repo: `git bundle create fia_main.bundle main` (current bundle is in outputs at `fia_main.bundle`, 22.5 MB; an incremental `fia_inc.bundle` also exists).
2. `scp` the bundle to Cardinal using the Cardinal SSH key (`~/.ssh/id_ed25519_cardinal`, sourced from `uploads/`).
3. On Cardinal, clone or fetch from the bundle, then push to GitHub using Cardinal's GitHub deploy key (`id_ed25519_github`, the `holoros` identity).

Gotchas already solved: a fresh `git clone` of a bundle creates an empty repo because of a HEAD issue, so use `git init` then `git fetch bundle main:main` then checkout. After a Cardinal-side push, the sandbox's `origin/main` tracking ref goes stale (the push did not originate from the sandbox), so correct it with `git update-ref refs/remotes/origin/main <sha>`. For SSH itself, always pass `-F /dev/null` to dodge the "Bad owner or permissions on ssh_config.d" error, and remember each bash call is independent: copy the key into `~/.ssh` and do the SSH work in the **same** bash call, because filesystem changes do not persist between calls.

---

## 7. Manuscript skeleton inventory

The manuscript is a complete skeleton. Main draft is `manuscript/MULTISTATE_PAPER_DRAFT_V2_20260520.md`, assembled with INSERT pointers, the filled p1 baseline tables, and Layer 7b placeholders awaiting the production bias numbers.

Component drafts (all 20260520): `ABSTRACT_DRAFT`, `INTRODUCTION_DRAFT`, `SECTION_X1_DATA_AND_METHODS_DRAFT`, `SECTION_X2_BIAS_MECHANISM_DRAFT`, `RESULTS_OUTLINE_AND_SUPPL`, `DISCUSSION_DRAFT`.

Supplements: `S1_state_constants.csv`, `S2_donor_pool_composition.csv` (70 rows), `S3_l3_to_section.csv`, `S4_cem_layer7b_patched.R`, `S6_bias_mechanism_chronology.md`, `S7_l7b_smoke_validation.md`, `S8_rpa_comparison.md`. (Older formatted supplements S2-S5 as docx/pdf also exist from earlier Maine-only work.)

**The one section waiting on data: Section 3.5.** It currently holds a placeholder bias-reduction table. The reframed narrative for it is already written ("ecoregion key alone produces no change, then the conus-donor experiment delivers the reduction"). Populate the numeric table once the WA conus and MN/GA hindcasts land.

---

## 8. Next session playbook (in order)

1. **Pull the WA conus production results** (10128559 RCP 4.5, 10128560 RCP 8.5). Confirm the iteration 1 match rate landed near 81 percent at production scale and check the cycle trajectory shifts toward higher accumulation.

2. **Run the WA conus hindcast:** `hindcast_multistate.R --state WA --tag rcp45_wear_conus_l7b --date <date>`. Compare the resulting bias to the minus 25 percent baseline and the unchanged minus 79.4 MMT l7b-neighbor result. This is the final confirmation number for arc step 4.

3. **Pull the MN and GA hugemem reruns** (10124341-44) when they complete and run their hindcasts. Expected: the same unchanged-bias pattern as WA in the neighbor cohort, which completes the eight-state evidence base and shows the finding generalizes.

4. **Populate manuscript Section 3.5** with the real bias-reduction table from steps 2 and 3. Replace the placeholder.

5. **Build Supplement S5** (per-state hindcast tables) once production lands.

6. **Optional data extension:** download remaining western TREE tables from the FIA DataMart on Cardinal if a fuller donor universe is wanted (see Section 4).

7. **Push to GitHub** via the Cardinal bundle mechanism (Section 6) after committing.

---

## 9. Status checklist

- California downloaded from FIA DataMart (complete COND + PLOT + TREE); 19-state donor pool active.
- `--conus_donors` validated at the matching level: WA iteration 1 match 62 percent to 81 percent with CA in the pool.
- WA conus production RUNNING (RCP 4.5) and PENDING (RCP 8.5); the final bias number is in flight.
- MN + GA hugemem Layer 7b reruns RUNNING; they complete the eight-state evidence base.
- Layer 7b ecoregion patch fully deployed, tested at production scale, archived as S4.
- Critical finding documented across `L7B_HINDCAST_RESULTS`, `CONUS_DONOR_BLOCKER`, `CONUS_DONOR_VALIDATION`, and corroborated by `P3_VALIDATION_COMPLETE`.
- Manuscript skeleton complete; only Section 3.5's numeric bias table awaits the production hindcasts.
- Local repo synced with GitHub (`holoros/fia-cem-maine` main = `7c9a9e2`); 186 commits.
- Queue cleared to 65 jobs; submission limit no longer blocking.
