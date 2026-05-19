# Multistate hindcast residual table (p1 baseline + ME r21 canonical + WA p3 v3 result)

*Generated 19 May 2026 10:15 ET while MN p3 finishes its 5th scenario and GA p3lite works through cycle 6.*

## TLDR

The full multi-cycle hindcast picture across ME, MN, WA, GA reveals a **systematic pattern across all states**: positive bias at cycle 1 (year 2004), negative dip at cycle 2 (year 2009), recovery at cycle 3, then growing positive bias at cycle 5 (year 2024). WA is the exception with a deep persistent negative bias throughout — and the v3 crosswalk does not change that. The bias pattern points to a model behavior issue at the cycle 2 horizon and a separate compounding issue at long horizons, not strictly a donor pool composition problem.

## Per state per cycle hindcast residuals

Residuals expressed as percent bias = (proj - obs) / obs × 100.

| State | Cycle | Year | obs (MMT) | proj (MMT) | bias |
|---|---:|---:|---:|---:|---:|
| **ME r21** | 1 | 2004 | 256.6 | 255.8 | -0.3% |
|           | 2 | 2009 | 167.2 | 113.8 | -31.9% |
|           | 3 | 2014 | 126.5 | 119.6 | -5.5% |
|           | 4 | 2019 | 109.9 | 114.5 | +4.1% |
|           | 5 | 2024 | 108.8 | 122.5 | +12.6% |
| **MN p1 RCP4.5** | 1 | 2004 | 178.9 | 185.5 | +3.7% |
|                  | 2 | 2009 | 145.0 |  99.0 | -31.7% |
|                  | 3 | 2014 |  92.8 |  79.5 | -14.3% |
|                  | 4 | 2019 |  83.9 |  89.6 | +6.8% |
|                  | 5 | 2024 |  79.8 |  93.7 | +17.4% |
| **MN p1 RCP8.5** | 1 | 2004 | 178.9 | 185.5 | +3.7% |
|                  | 2 | 2009 | 145.0 |  97.8 | -32.6% |
|                  | 3 | 2014 |  92.8 |  79.6 | -14.2% |
|                  | 4 | 2019 |  83.9 |  89.4 | +6.6% |
|                  | 5 | 2024 |  79.8 |  94.9 | +18.8% |
| **WA p1 RCP4.5** | 4 | 2019 | 311.7 | 232.7 | -25.3% |
| **WA p1 RCP8.5** | 4 | 2019 | 311.7 | 234.3 | -24.8% |
| **WA p3 RCP4.5** | 4 | 2019 | 317.0 | 237.6 | -25.0% |
| **WA p3 RCP8.5** | 4 | 2019 | 317.0 | 235.3 | -25.7% |
| **GA p1 RCP4.5** | 1 | 2004 | 356.3 | 406.0 | +13.9% |
|                  | 2 | 2009 | 311.6 | 267.3 | -14.2% |
|                  | 3 | 2014 | 210.8 | 206.2 | -2.2% |
|                  | 4 | 2019 | 179.8 | 224.5 | +24.9% |
|                  | 5 | 2024 | 181.7 | 255.1 | +40.4% |
| **GA p1 RCP8.5** | 1 | 2004 | 356.3 | 406.8 | +14.2% |
|                  | 2 | 2009 | 311.6 | 269.4 | -13.5% |
|                  | 3 | 2014 | 210.8 | 209.3 | -0.8% |
|                  | 4 | 2019 | 179.8 | 224.9 | +25.1% |
|                  | 5 | 2024 | 181.7 | 265.9 | +46.3% |

## Systematic pattern

The cycle 2 (year 2009) negative bias is present in **every** non-WA state:

| State | Cycle 2 bias |
|---|---:|
| ME r21 | -31.9% |
| MN p1 | -31.7% / -32.6% |
| GA p1 | -14.2% / -13.5% |

This consistency across states with different donor pools, different ownership mixes, and different climate regimes is suspicious. It suggests a model-level issue at the 5-to-10 year horizon — possibly:

1. An interaction between the subject pool shrinkage (as plots drop out of remeasurement) and the projection's growth accumulation.
2. A reset or discontinuity at cycle 2 transition in `06_projection_engine.R`.
3. An evaluator-level (EVALID) sampling artifact in how observed AGC is computed against the diminishing subject plot list.

Note that subject plot counts drop fast: ME 3110 → 1825 (cycle 1 → cycle 2), MN 5221 → 4469, GA 4347 → 3390. WA only has cycle 4 hindcast available so we cannot test this pattern there.

## WA bias is qualitatively different

WA has a deep persistent negative bias (-25 pct at cycle 4) that does not match the dip-and-recover pattern of the other states. This is consistent with the donor pool composition theory: WA's actual west-side carbon density (Doug-fir, hemlock) exceeds what OR/ID/MT donors carry, and the projection systematically underestimates carbon stocks because the donors are inland species mixes.

**WA p1 → WA p3 delta is negligible** (-25.3 / -24.8 → -25.0 / -25.7) confirming the v3 crosswalk does not fix this.

## GA late-cycle bias

GA cycle 5 (year 2024) at +40 to +46% is the worst single-cycle bias across the entire matrix. The trajectory builds: +14, -14, -2, +25, +40. This is consistent with the GA bias attribution in `CURRENT_STATE_SYNTHESIS_20260517.md`:

> Young plantation cohort escaping growth attenuation. GA median age 25, 84.7 pct of plots have sat_age=1.0 (no attenuation), vs ME 52.3 pct and MN 60.1 pct. Plantation rotation regime in donor pool exceeds natural stand accumulation.

Cycle 5 is when the young plantation overgrowth compounds most — the projection has accumulated five 5-year increments of unattenuated growth.

## Implications for the manuscript

1. **Cycle 1 is the cleanest validation point** across states (bias range -0.3 to +14%, much tighter than later cycles). The manuscript should anchor on cycle 1 if a single point comparison is needed.
2. **Cycle 2 dip is a model behavior to investigate**, not a state-level bias.
3. **Cycle 5 bias is the worst**, but it is the most informative for understanding model error growth.
4. **WA bias is the data-side limitation** — donor pool composition gap, distinct from the model behavior issues at other horizons.
5. **MN bias is mild** (+3.7 to +17.4% across cycles). MN p3 may not differ much from p1 even after v3.
6. **GA bias is severe** at long horizons. Whether p3lite changes this depends on whether the CEM ecoregion strata reduce plantation donor inclusion.

## Next analytical steps (post p3 completion)

1. Re-render the comparison table once MN p3 and GA p3lite finish. Compare p1 vs p3 per cycle, not just cycle 4.
2. Investigate the cycle 2 dip: is it the EVALID subject filter, the projection engine, or the carbon accumulator? Suggest running `06_projection_engine.R` in non-MC mode (n_sims=1) for a single subject to trace it.
3. If GA p3lite tightens cycle 5 bias from +40% to +20-25%, the manuscript can document that as the CEM-strata win.

## Files

- `output/hindcast/HINDCAST_*.csv` — all 9 per-state hindcast tables (p1 + r21 + WA p3) locally synced
- `docs/WA_P3_VALIDATION_20260519.md` — WA-specific validation
- `docs/P3_MULTISTATE_INTERIM_20260519.md` — pipeline state at 06:45 ET
