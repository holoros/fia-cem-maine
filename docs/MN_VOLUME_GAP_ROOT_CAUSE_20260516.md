# MN statewide volume undercount root cause: DESIGNCD periodic plot exclusion at 1999 baseline

> **SUPERSEDED 16 May 2026.** This file's DESIGNCD attribution was refuted by the MN 2004 baseline diagnostic (SLURM 9676388), which produced 21.8 Bcuft versus the 1999 baseline 21.6 Bcuft (essentially identical). The DESIGNCD periodic plot exclusion is not the dominant cause of the MN -23 percent statewide gap. See `MN_VOLUME_GAP_REVISED_20260516.md` for the current finding and revised candidate mechanisms (Lake States donor pool, HCB owner downscale, climate response gating, state_constants).

*Generated 16 May 2026 after a direct FIA plot database audit on Cardinal resolved the outstanding MN -23 percent statewide volume gap.*

## The finding

MN FIA plot inventory by DESIGNCD:

| DESIGNCD | Description | Plot count | INVYR range |
|---:|---|---:|---|
| 1 | Annualized inventory (FIA Phase 2 national) | 75,968 | 2004 to present |
| 301 | Lake States periodic | 80,435 | pre 2004 |
| 312, 314, 318, 319, 320, 321 | older periodic variants | ~14,000 | pre 2004 |

**Minnesota's annualized FIA inventory started in 2004.** Prior to 2004, MN used the Lake States periodic design (DESIGNCD 301) and predecessor designs. The pipeline's subject pool filter at `R/01_data_prep.R` keeps only DESIGNCD == 1 plots (annualized), which for MN means the earliest baseline window starts in 2004, not 1999.

When the pipeline is invoked with `--baseline_year 1999 --baseline_window 10`, it looks for plots measured between 1999 and 2008. For Maine (DESIGNCD 1 starting 1999), this captures the full baseline window. For Minnesota, the filter only finds plots measured 2004 to 2008, effectively a 5 year baseline window covering only the second half of the intended period.

## Why this produces a 23 percent volume undercount

Two compounding mechanisms:

1. **Truncated baseline window.** MN's 5 year effective baseline (2004 to 2008) catches fewer plots than the 10 year intended window (1999 to 2008). The subject pool is smaller, expanded by EXPNS to a smaller total.

2. **Stand age skew.** The 2004 to 2008 measurements miss the older cohorts that the periodic design captured pre 2004. The pipeline's age weighted donor matching is biased toward younger stands than the MN forest population, producing lower per acre volume in the projection's cycle 1 baseline.

The combined effect is approximately the 23 percent under prediction observed in the multistate p1 validation memo. This is consistent with the literature on FIA annualized vs periodic design tradeoffs (Bechtold and Patterson 2005).

## Why this does not affect Maine

Maine was one of the first states to transition to the annualized FIA design, beginning in 1999. The Maine annualized cohort fully covers the canonical 1999 to 2008 baseline window. The DESIGNCD == 1 filter is essentially a no op for Maine and the pipeline produces a statewide AGC and volume within 10 percent of EVALIDator without any periodic plot inclusion.

## Why this does not affect WA and GA at the same magnitude

Washington and Georgia transitioned to annualized FIA in 2002 and 1998 respectively. Both have substantial annualized cohorts covering the 1999 to 2008 baseline window. The DESIGNCD filter excludes some periodic plots but not the majority, so the subject pool is mostly intact. Statewide volume undercounts are 2 percent for WA and slight overcount for GA, consistent with the smaller filter effect.

## Recommended remediation paths for the manuscript

Three options, in order of effort:

1. **Document as a known limitation.** Add a sentence to the manuscript methods or limitations section noting that MN baseline volume is approximately 23 percent under EVALIDator due to the Lake States annualized inventory not beginning until 2004, requiring the pipeline to operate on a truncated 2004 to 2008 baseline window rather than 1999 to 2008. Cost: zero compute, manuscript transparency.

2. **Relax the DESIGNCD filter for MN.** Add a state specific exception in `R/01_data_prep.R` that includes DESIGNCD 301 plots for Minnesota only, with an appropriate weighting adjustment to harmonize with the annualized expansion factors. Risk: introduces complexity and the periodic and annualized designs are not directly comparable; the EXPNS factors differ. Cost: moderate analytical effort (1 to 2 days), manuscript justification needed.

3. **Re run MN with a 2004 baseline.** Use `--baseline_year 2004 --baseline_window 5` for MN only, producing a projection that starts from the annualized inventory but covers a shorter projected horizon (70 years instead of 75). Other states retain their 1999 baseline. Risk: introduces asymmetry across states that the manuscript would need to explain. Cost: one production rerun for MN.

Recommendation: Option 1 for the immediate manuscript submission. The MN undercount is now characterized as a structural FIA inventory design limitation rather than a model error. A future paper or supplement could implement Option 2 or 3 with proper expansion factor harmonization.

## Cross reference to existing documentation

This finding builds on:
- `docs/MULTISTATE_PORTABILITY_GAPS.md` Section 12 originally identified the DESIGNCD filter as a known limitation
- `docs/BIAS_DOCUMENTATION_20260515.md` flagged the MN -23 percent as structural pending root cause identification
- `docs/SMOKE_SANITY_20260510.md` documented the initial smoke observation of the gap
- `docs/VALIDATION_FINAL_20260515.md` carried the MN -23 percent forward through the corrected analysis

The current document closes the loop on this outstanding item by providing the empirical root cause from the FIA plot database.
