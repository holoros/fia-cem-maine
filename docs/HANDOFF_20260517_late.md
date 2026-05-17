# Session handoff 17 May 2026 late: mechanisms resolved across the full multistate p1 set

*Supersedes `HANDOFF_20260517_evening.md` after the late-afternoon autopilot push that landed M2 unit resolution and the 4-state donor pool figure.*

## TLDR

The bias mechanism story is now complete across all four multistate p1 states. Donor pool composition mismatch is universal — ME's Northeast donor cohort has a 30 pp spruce/fir gap and 32 pp oak/hickory gap, the same direction and magnitude as MN, WA, and GA. ME shows -1.1 percent canonical bias not because its donor pool is well-matched but because compensating mechanisms (ClimateNA decoupled climate, within-Maine state_constants refinement, owner balanced rescaling) absorb the mismatch. The CEM 3-way stratification (ecoregion × FORTYPCD × OWNGRPCD) is the methodologically clean direction that would address all four states uniformly. RPA baselines transcribed from the 2020 RPA Assessment WO-GTR-102 Chapter 6; M2 fit response variable identified as a Beta-distributed intensity fraction (not volume); pct_diff of -84 to -93 percent against RPA reduced to 2.5x to 3.7x after unit reconciliation, consistent with re-measured panel pair training bias and resolvable with a ~0.35 correction factor. Local repo at 48 commits ahead of origin/main.

## What's now resolved

| Question | Answer | Memo |
|---|---|---|
| WA bias mechanism | Donor pool composition (Doug-fir -9 pp, hemlock -11 pp) | WA_DONOR_POOL_DIAGNOSTIC_20260517.md |
| MN bias mechanism | Lake States donor pool composition (aspen +23, spruce/fir +12 pp gaps) | MN_DONOR_POOL_DIAGNOSTIC_20260517.md |
| GA bias mechanism | Stand age saturation × forest-type-agnostic harvest selection | GA_BIAS_CANDIDATES_20260517.md |
| ME bias source | NOT a well-matched donor pool; compensating mechanisms absorb the mismatch | MULTISTATE_DONOR_POOL_4PANEL_20260517.md |
| CEM stratification feasibility | Yes; 3-way ecoregion × FORTYPCD × OWNGRPCD better than 2-way | CEM_3WAY_STRATIFICATION_20260517.md |
| Production-ready owner classification | OWNGRPCD (4 FIA classes); HCB needs multi-day geospatial fill | CEM_3WAY_STRATIFICATION_20260517.md |
| RPA baseline source | 2020 RPA Assessment WO-GTR-102 Ch6 Figure 6-4 + chapter text | RPA_COMPARISON_RESULTS_20260517.md |
| M2 response variable units | intensity_y = Beta-distributed fraction [0,1] of stand removed | M2_UNIT_RESOLUTION_20260517.md |
| RPA pct_diff interpretation | -84 to -93 percent was a unit-comparison artifact; actual over-prediction 2.5-3.7x | M2_UNIT_RESOLUTION_20260517.md |
| conus_hcs RPA cascade | Layer 22 complete (5 patches); aggregation produces all 4 subregions | RPA_AGGREGATION_RESULTS_20260516.md + Layer 22 |
| SDImax cap proj_tpa bug | Audited; one-line Layer 6 patch staged but not deployed | SDIMAX_TPA_AUDIT_20260517.md |

## Manuscript-ready deliverables

- `figures/wa_donor_pool_diagnostic.png` — WA donor pool gap
- `figures/mn_donor_pool_diagnostic.png` — MN donor pool gap
- `figures/ga_donor_pool_diagnostic.png` — GA donor pool gap (STDORGCD comparison limited by Cardinal data)
- `figures/ga_bias_candidate_diagnostic.png` — GA stand age distribution with sat_age zones
- `figures/multistate_donor_pool_4panel.png` — 4-state unified comparison (proposed manuscript Figure X.Y)
- `figures/multistate_sat_age_share.png` — cross-state sat_age=1.0 share (GA at 85% vs MN/ME/WA at 44-60%)
- `figures/multistate_rel_growth_trajectory.png` — cycle 1 to 5 rel growth rate by state
- `figures/rpa_subregion_panel.png` — RPA aggregation p_harvest + removal per ha
- `figures/cem_strat_cell_sizes_overall.csv` and `cem_3way_strat_cell_sizes_overall.csv` — empirical feasibility tables

## Refined manuscript narrative

The bias documentation now reads as a coherent story:

> "Donor pool composition mismatch is the universal mechanism across the four multistate p1 states. All four show systematic underrepresentation of subject-dominant forest types in their donor pools and overrepresentation of climax-forest or mid-successional types from neighboring states. The compensating mechanisms in the canonical Maine reference — explicit ClimateNA decoupled climate coupling, within-Maine refinement of state_constants.csv, and owner balanced rescaling — work together to produce the -1.1 percent reference bias. The other three states lack one or more of these compensations, allowing the same donor pool mismatch to translate into -5.7 percent (MN), -25 percent (WA), or +10 percent (GA, in combination with stand-age saturation under-application on young plantations). A future iteration adding ecoregion (us_l3code or Bailey section) and FORTYPCD to the CEM matching strata, alongside the existing OWNGRPCD stratification, would directly address the donor pool mechanism for all four states uniformly; the empirical cell-size diagnostic confirms this is feasible with the existing FIADB coverage (CEM_3WAY_STRATIFICATION_20260517.md)."

## What remains open for the next session

In order of value:

### 1. Deploy CEM ecoregion patch + smoke test (highest value)

Approval pending. Patch design in `CEM_PATCH_PROPOSAL_ECOREGION_20260517.md`:
- Add `cem_ecoregion` to iter1 keys
- Coarsen ecoregion to Bailey section in iter2 (use `config/l3_to_section.csv`)
- Drop ecoregion in iter3
- 13 hr total: 3 hr code, 4 hr fallback, 2 hr smoke validation, then 12 hr SLURM rerun of all 6 multistate p1 outputs

Projected bias reductions: WA -25 → -5 to -10%, MN -23 → -5 to -10%, GA +10 → +3 to +5%, ME unchanged.

### 2. Apply re-measurement bias correction to conus_hcs RPA aggregation

Add `--remeasurement_correction = 0.35` parameter that scales the conus_hcs removal_per_ha output. Documented in `M2_UNIT_RESOLUTION_20260517.md`. ~30 min.

### 3. Push 48 commits to GitHub from workstation

`git push origin main`. Workstation credentials required.

### 4. Manuscript horizon decision (still gates two downstream choices)

- Cycle 5 (2024 RPA-comparable): no further production work needed
- Cycle 10 (2049): Layer 6 SDImax patch must deploy
- Cycle 15 (2074): Layer 6 patch + full p1 rerun required

### 5. Build out HCB owner classification across full CONUS

Multi-day geospatial task. Would enable HCB-based 3-way CEM stratification (10 owner classes vs OWNGRPCD's 4). Documented in `CEM_3WAY_STRATIFICATION_20260517.md`.

## Commits in this leg (this push, latest first)

```
1555549 Multistate 4-panel donor pool figure: reveals ME is NOT canonical in donor pool sense
e05ae43 M2 unit resolution: intensity_y is Beta-distributed fraction [0,1]
132947f RPA comparison v2 with populated baselines
97e61ce RPA baselines from RPA Assessment Ch6 Figure 6-4
5c54ad5 CEM patch proposal: ecoregion is the gap
8ee146f L3-to-section crosswalk
5913381 CEM 3-way stratification: ecoregion x TYPGRPCD x OWNGRPCD
aa90a22 CEM ecoregion x FORTYPCD feasibility test
a146b2e Multistate sat_age comparison: GA median age 25, 84.7% sat_age=1.0
9d175ad GA bias mechanism resolved
38061fd Manuscript methods GA mechanism resolved
c2ecdb6 BIAS_DOCUMENTATION GA mechanism resolved
9d175ad GA bias mechanism resolved: Candidate 4 CONFIRMED
955a464 multistate growth rate cross-section
b198809 GA bias candidate diagnostic (SLURM 9815022)
ef0434c 17 May evening handoff
e300ad2 WA westside donor prototype REFUTED
c762b01 manuscript methods WA confirmed + GA refuted
6473278 GA donor pool diagnostic REFUTES original hypothesis
f63df04 SDImax cap audit
0fff0e6 WA donor pool diagnostic confirms mechanism
77c9999 RPA p_harvest saturation confirmed across 2 M1 frameworks
4e421db RPA subregion panel figures
9dc141a RPA p_harvest saturation root cause
ffe3b45 handoff: Layer 22 RPA aggregation success
c2093cb RPA aggregation full STATECD breakdown
ad912f0 RPA aggregation Layer 22 success
36cbdca conus_hcs RPA Layer 22 fix
```

## Cardinal state at handoff

- conus_hcs RPA aggregation Layer 22 deployed; SLURM 9857780 (with baselines) completed in 17:22
- Phase 4 outputs at `~/conus_hcs/output/phase4/` with populated pct_diff
- `~/conus_hcs/config/rpa_baselines.csv` populated from 2020 RPA Assessment
- fia_cem_projections diagnostic outputs at:
  - `output/wa_donor_diagnostic_20260516/`
  - `output/ga_donor_diagnostic_20260517/`
  - `output/wa_westside_donor_20260517/`
  - `output/cem_strat_20260517/`
  - `output/cem_3way_strat_20260517/`
  - `output/mn_donor_diagnostic_20260517/`
  - `output/multistate_growth_rate_20260517/`
  - `output/multistate_sat_age_20260517/`
  - `output/ga_bias_candidate_20260517/`
  - `output/multistate_donor_pool_20260517/`
- ME r21 econ production preserved
- All 6 multistate p1 production runs preserved
- Queue clean
