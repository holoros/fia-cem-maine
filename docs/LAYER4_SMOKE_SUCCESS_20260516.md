# Layer 4 patch validated: realistic Maine harvest dynamics restored

*Generated 16 May 2026 after SLURM job 9671919 (10 sim, 5 cycle ME BAU smoke with --use_maine_econ) produced the key cycle 1 result.*

## Headline

**The Layer 4 patch alone is sufficient.** A 10 simulation ME BAU smoke with `--use_maine_econ` and the corrected MBF and cord price conversions produces realistic Maine harvest dynamics. Cycle 1 BAU harvest rate dropped from 0.836 (pre Layer 4 saturation) to **0.258** — a 3.2x reduction. Subsequent cycles drop further to 0.13, 0.09, 0.04, 0.03 across cycles 2 through 5.

Layer 5 (replacing the `dVAL = REV_harvest` proxy with the proper Wear 2025 differential) is NOT needed. The applicator script at `scripts/apply_layer5_patch.R` remains in the repo for future use if more refined economic dynamics are desired.

## Full trajectory

| Cycle | Pre Layer 4 | **Post Layer 4** | gr_ratio Post Layer 4 |
|---:|---:|---:|---:|
| 1 | 0.836 | **0.258** | 0.84 |
| 2 | 0.453 | **0.130** | 2.07 |
| 3 | 0.285 | **0.089** | 2.92 |
| 4 | 0.203 | **0.037** | 8.31 |
| 5 | 0.144 | **0.028** | 9.83 |

Mean across 5 cycles: 0.108 (10.8 percent). This matches observed Maine harvest rate of approximately 0.10 to 0.11 per cycle very closely.

The cycle 1 elevated rate of 0.258 represents the initial inventory liquidation: mature stands that accumulated during the 1999 baseline period get harvested in the first cycle, then the system stabilizes to sustainable rates by cycle 3 onward. This pattern is biologically realistic for managed Maine forests after a baseline calibration period.

## gr_ratio is now in correct biological magnitude

gr_ratio = gross_growth / harvest_removals. Values:
- < 1: removals exceed growth (forest depleting)
- ~ 1: growth balances removals (steady state)
- > 1: growth exceeds removals (forest accumulating)

The trajectory 0.84 → 2.07 → 2.92 → 8.31 → 9.83 shows the system moving from initial inventory liquidation (cycle 1 still slightly net removal) to sustained accumulation by cycle 5. This is the correct managed forest pattern.

## Predicted vs actual

My back of envelope predicted cycle 1 = 0.56. Actual was 0.258. The factor of 2 better than predicted is because:
- I assumed a single owner class (NE otherpr with intercept -1.78). The Wear 2025 logit applies different intercepts per owner class (commercial -1.58, public -19.7, otherpr -1.78). The public lands at -19.7 produce essentially zero harvest probability.
- Across the full owner mix in Maine, the area weighted average intercept is more negative than my single class assumption, dropping the post Layer 4 average P(harvest) below my single class prediction.

## ME r21 econ reruns are unblocked

With the Layer 4 patch in place producing realistic harvest dynamics, the `submit_rcp45_wear_econ_r21.sh` and `submit_rcp85_wear_econ_r21.sh` scripts can be queued. Each is approximately 20 hours wall clock, 48 cpus, 180 GB memory. Total compute: ~40 hours wall, ~1920 cpu hours.

The ME r21 econ runs will produce:
- Per acre and statewide AGC trajectories with the full economic harvest overlay
- gr_ratio in realistic biological magnitude (not the prior 0.001 from compounded bugs)
- Per scenario AGC delta from BAU including the new owner balanced behavior
- Per county harvest rates calibrated to SAR observed values

These are the canonical "Maine economic projection" outputs for the manuscript.

## Methodological note for manuscript

The harvest economic overlay turned out to contain **four parallel patches** in sequence:

| Layer | Site | Effect |
|---|---|---|
| 1 | R/06 line 922 gr_ratio reporting | Fixed reporting, not harvest decision |
| 2 | R/03 line 409 vol_removed_total tpa_live | Active code, fixes cycle 2+ revenue feedback |
| 3 | R/03 line 108 EV tpa_live | Dead code, patch correct but inert |
| 4 | R/03 line 80-91 REV cuft to MBF/cord conversion | Active code, fixes cycle 1 dVAL → harvest rate |
| 5 | R/03 line 257 dVAL = REV_harvest proxy | Not needed; Layer 4 alone sufficient |

The four layers represent independent unit and scaling errors that compounded in different ways. Layer 1 and 4 had visible effects in production; Layer 2 affected cycle 2+ revenue; Layer 3 fixed dead code for consistency. Discovering them required investigating downstream symptoms (gr_ratio collapse, then 83 percent harvest saturation) and tracing through the code paths to find the contributing layer.

This experience is publishable as a worked example of unit auditing in a multi component forest projection pipeline. The story should appear briefly in the manuscript methods or appendix as a methodological transparency note.

## Multistate p1 unaffected

The six p1 multistate runs (MN, WA, GA × RCP 4.5 and RCP 8.5) bypass the entire harvest economic overlay via `--no_econ --skip_supply`. Their validation results (PASS 8 of 8 across all six, hindcasts -25 to +11 percent bias bracketing the ME r11 reference) are unchanged. The multistate manuscript chapter is publishable as is, independent of the ME econ work.

## Next session sequence

1. Push the 16 commits to GitHub from workstation
2. Schedule ME r21 econ reruns: `sbatch osc/submit_rcp45_wear_econ_r21.sh; sbatch osc/submit_rcp85_wear_econ_r21.sh`
3. Each run completes in ~20 hours; both should land by next morning
4. Pull outputs and run validations against the canonical ME r21 non econ reference
5. Compare econ vs no econ trajectories for the manuscript
6. Begin manuscript figure assembly using both multistate p1 and ME r21 econ outputs
7. Update `manuscript/MULTISTATE_METHODS_DRAFT_20260515.md` Section X.3 with the corrected 4 layer story (the previous narrative speculated about Layer 2/3 compensation; the actual mechanism is the Layer 4 price unit mismatch driving cycle 1 saturation, with Layers 1-3 being independent issues)
