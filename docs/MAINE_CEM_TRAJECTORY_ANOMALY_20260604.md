# Maine CEM trajectory anomaly + GA full-sample result

**Date:** 2026-06-04
**Author:** A. Weiskittel (Cowork autopilot)
**Trigger:** PERSEUS explorer shows Maine CEM "managed (harvest)" AGC crashing to ~70 Tg by 2099, far below other engines and the 221 Tg observed.

## GA is fixed (full n_sims)

The GA plantation-rotation production hindcast (n_sims 100, 35,794 subjects) came back at **bias +0.3% (+0.8/+1.0 MMT)**, down from +20.4% baseline. The plantation rotation lever (planted stands -> 35yr) nailed GA on average; the +6.5% smoke was pessimistic. GA is essentially unbiased. RMSE 19.2% is year-to-year scatter, not systematic bias.

## The Maine anomaly, quantified

Maine CEM AGC (Tg C), managed (harvest) vs no-harvest, from the ingested series:

| series | 2004 | 2024 | 2074 | 2099 |
|---|---|---|---|---|
| cem_wear_rcp45 (BAU + harvest) | 239 | 186 | 96 | 70 |
| cem_wear_rcp85 | 239 | 188 | 100 | 73 |
| cem_policy / cem_wear_econ | 238 | 180 | 79 | 53 |
| **cem_wear_nh (NO harvest)** | 239 | **246** | **273** | **280** |
| FIA observed | ~240 | 221 | n/a | n/a |

No-harvest is stable and physical (grows to 280). Every harvest variant crashes by 60 to 78%. So harvest is the necessary ingredient of the crash.

## Mechanism (from per-cycle diagnostics, recent ME wear_econ run)

| cycle | mean C/ac | harvest_rate | plant_rate | gr_ratio |
|---|---|---|---|---|
| 1 | 43,985 | 0.088 | 0.075 | 3.4 |
| 4 | **46,305 (peak)** | 0.075 | 0.067 | 5.5 |
| 8 | 40,962 | 0.061 | 0.056 | 5.8 |
| 15 | 29,749 | 0.045 | 0.037 | 6.9 |

Carbon peaks at cycle 4 then declines 35% to cycle 15, even though:
- gr_ratio (gross growth / removal) stays healthy at 3 to 7, and
- harvest_rate is modest (5 to 9%) and falling.

The resolution: gr_ratio measures growth on the unharvested plots only. Each cycle, harvested stands are reset (age setback / ~95% clearcut removal) to low carbon, and they regrow too slowly to recover before the next entry. plant_rate < harvest_rate every cycle, so the harvested area is not fully re-established. The growing pool of recently-harvested, slowly-regrowing stands drags the area-weighted mean down, and the trajectory ratchets down rather than reaching a managed steady state. **This is the same slow-donor-regrowth mechanism as the WA underprediction: the donor pool grows too slowly, so harvested Maine stands do not recover.** It is amplified by the growth-throttling stack: the r-tag history shows the BRMS SDImax cap alone dropped 2074 AGC from 257 (r11) to 95 (r13).

So the Maine crash has two compounding drivers:
1. **Slow post-harvest regrowth** (donor growth-rate composition; the WA theme), so harvest is not recovered.
2. **The SDImax cap (and disturbance/climate)** throttling growth, heavily implicated by the r-tag history.

Real Maine forests are near carbon steady state under current harvest, so a managed trajectory that crashes to 70 to 96 Tg is non-physical and the explorer is right to flag it.

## Secondary issues

- **cem_v5_anchored discontinuity:** jumps 182 -> 241 Tg at the 2027 anchor (a re-baseline artifact), the spike visible in the explorer.
- **Stale PERSEUS Maine CEM:** the ingested files are the 7 May HRF runs (about r13-level), predating the current engine and all the recent WA/GA work. PERSEUS Maine CEM should be refreshed.
- **Structural offset:** part of the low level is the known projection-vs-inventory definitional gap (CEM projects the subject pool; full EXPALL is ~96 MMT higher). The decline SHAPE is the new concern, separate from the offset.

## Suggested next steps (in priority order)

1. **Isolate the driver.** Run Maine BAU at full n_sims with the SDImax cap toggled off vs on, holding everything else fixed. The r-tag history says SDImax is a large driver; this confirms how much of the crash is SDImax vs slow regrowth.
2. **Test productivity weighting on Maine.** prodW (the WA lever) re-matches regrowing stands to productivity-appropriate donors and may flatten the decline. This run also refreshes the stale PERSEUS Maine CEM with the current engine. Both RCPs, n_sims 100.
3. **Examine the post-harvest regen path.** plant_rate < harvest_rate and the age-setback may be too aggressive; check whether harvested Maine stands are being re-seeded with too-slow donors or set back too far.
4. **Refresh and re-ingest** the canonical Maine CEM into PERSEUS once the trajectory is defensible, and fix the v5_anchored anchor discontinuity.

Items 1 and 2 are full-n_sims runs (smokes mislead on magnitude, per the established lesson) of ~5 to 6 h each.
