# Manuscript revision guidance

**Date:** 2026-06-06
**Author:** A. Weiskittel (Cowork)
**Scope:** Sections 3.5, Discussion, Abstract; plus a forward-series gating caveat.
**Basis:** full n_sims=100 results (`docs/HANDOFF_COMPREHENSIVE_20260604.md`), GA
plantation-rotation hindcast (`docs/HINDCAST_GA_RCP45_WEAR_PLANTTERM_PROD_L7B.md`),
WA productivity result (`docs/PRODUCTIVITY_MATCHING_RESULT_20260522.md`), and the
forward-trajectory diagnosis (`docs/AREAFIX_VERIFY_AND_INGROWTH_DIAGNOSIS_20260606.md`).

## The closing framework (use this as the spine of 3.5, Discussion, Abstract)

The CEM matching engine amplifies whatever growth-rate asymmetry exists in the
regional donor pool. Three outcomes, one mechanism:

- **ME** (diverse donor pool + within-state compensations): the matching key finds
  the right growth analog. Reference bias -1.1%.
- **GA** (homogeneous, plantation-heavy pool): the key concentrates the plantation
  cohort and over-accumulates past loblolly's real rotation. Baseline overshoot,
  **remediated** by a stand-origin-aware rotation (STDORGCD=1 -> 35 yr): bias moves
  from +20.4% to **+0.3%**. The mechanism was both diagnosed and fixed.
- **WA** (absent analog): west-side maritime Douglas-fir has no FIA donor analog, so
  no matching strategy (neighbor, CONUS, +California, ecoregion, productivity) can
  supply an appropriate donor. Floor at ~-25%; productivity matching only narrows it
  to -14% by dropping ~half the high-productivity subjects. A model-based growth
  correction, not a better donor search, is the path.

The contrast is the paper's strongest result: GA shows the bias mechanism is real
and remediable when a donor analog exists; WA shows the limit when it does not.

## Abstract: specific edits

1. **GA sentence (current line 17).** The draft attributes GA's overshoot to the
   stand-age saturation leaving plantations at full growth plus forest-type-agnostic
   harvest. Keep the diagnosis, then add the remediation: a stand-origin-aware
   rotation age (planted stands terminated at 35 yr) reduces GA hindcast bias from
   +20% to within 1% of observed at full n_sims. This makes GA a diagnosis +
   remediation success, parallel to WA's diagnosis + fundamental limit.
2. **Reconcile the GA baseline number.** The abstract currently cites GA at about
   +10 to +11% (an earlier L7B smoke). The canonical full-sample baseline is +20.4%
   (RCP45, n_sims=100). Use the full-sample number and note that n_sims=20 smokes
   understated bias magnitude (a documented methodological caution worth one line).
3. **WA numbers are current** (-25% baseline floor; productivity matching to -14% at
   the cost of ~50% subject coverage). No change needed beyond confirming -22.9% /
   -21.2% as the canonical prodW figures if the paper reports the remediated WA run.

## Section 3.5 (WA transferability): framing

The existing `SECTION_3.5_WA_TRANSFERABILITY_DRAFT_20260522.md` leads correctly with
the donor-analog gap. Confirm it states the three convergent remediation paths
(CONUS donor expansion, California addition, productivity matching) all reach the
same floor, and that productivity matching's apparent improvement is a coverage
artifact (it drops the unmatched high-productivity half). Add a forward pointer to
the GA result as the contrasting "remediable" case.

## Discussion: closing

Lead with the amplification framework above. Then the transferability taxonomy:
(a) donor analog present + compensations -> low bias (ME); (b) donor analog present,
mechanism diagnosable and fixable -> remediated (GA); (c) donor analog absent ->
fundamental limit, model correction required (WA). Close on the practical claim: the
framework needs no data beyond published FIA and produces RPA-comparable state-level
projections, with a clear, testable rule for when donor substitution will and will
not work.

## Forward-series gating caveat (important, do not skip)

The manuscript's quantitative results are HINDCAST validations (2004 to 2024,
5 cycles, subject-matched). Those are sound and unaffected by the issue below.

Do NOT present CEM forward projections (2024 to 2074) as results in this submission
until the ingrowth fix is applied and re-verified. As of 6 June a forward-engine bug
inflates projected tree count without bound (gr_tpa lacks age saturation), which
decouples TPA from BA and carbon beyond ~cycle 9. See the diagnosis memo. If forward
trajectories are in scope for the paper, gate the revision on the fix; if not, keep
the results section to hindcast validation and note forward projection as ongoing
work. Either way, do not lock manuscript numbers against the current forward engine.

## Checklist

- [ ] Abstract: add GA remediation result; reconcile GA baseline to +20.4%.
- [ ] 3.5: confirm coverage-artifact framing; add GA contrast pointer.
- [ ] Discussion: insert the three-case amplification taxonomy as the spine.
- [ ] Confirm canonical WA figures (-22.9% / -21.2%) used consistently.
- [ ] Add the n_sims=20-understates-bias methodological caution (one line).
- [ ] Decide forward-projection scope; gate on the ingrowth fix if included.
- [ ] Fold the GA cohort cross-tab (output/ga_l7b_residual_20260524/) into a supplement.
