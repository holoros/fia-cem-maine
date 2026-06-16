# SDImax constraint: units check and status

**Date:** 2026-06-08
**Author:** A. Weiskittel (Cowork)
**Prompted by:** the maximum-SDI constraint matters; confirm metric vs imperial handling.

## Verdict: the SDImax constraint is units-consistent (imperial throughout). No units bug.

The Reineke SDImax cap in `R/06_projection_engine.R` (lines ~757-766) is internally consistent
in imperial units end to end:

- `proj_sdi = proj_tpa * (proj_qmd / 10)^REINEKE_EXP`, with `REINEKE_EXP = 1.605`,
  `proj_tpa` in trees per acre, `proj_qmd` in inches, and a 10-inch reference. That is the
  imperial Reineke SDI.
- The cap compares it to `sdimax_eng`, taken from the **english** columns of the BRMS lookups
  (`sdimax_english_mean`), with imperial default `GLOBAL_SDIMAX_DEFAULT_ENG = 440`.

The lookup carries BOTH unit systems and converts correctly. From `build_brms_sdimax_lookup.R`:
`sdimax_english = sdimax_metric * 0.4046856` (trees/ha -> trees/acre). Verified numerically on
the data: english/metric = 0.404686 exactly.

The subtle point that makes the density-only conversion valid: Reineke SDI is a density evaluated
at a reference diameter. The metric reference is 25 cm and the imperial reference is 10 in =
25.4 cm, which are effectively the same diameter. So only the per-area density unit changes
(trees/ha -> trees/acre, x 0.4047); the diameter-reference term needs no separate conversion.
That is exactly what the build script does, and the cap consumes the english column against an
imperial `proj_sdi`. Consistent.

## The real watch-item is data quality, not units

The per-plot BRMS SDImax posterior (english) has implausible tails: min 36, mean 380, max 1478
trees/acre across 10,125 plots. Imperial SDImax for fully stocked stands is typically ~300-600.
A plot whose posterior mean lands at 36 would be capped far too low (massive over-suppression);
1478 would never bind. The cap uses plot-level first, then forest-type, then the 440 default
(`coalesce(sdimax_eng_plot, sdimax_eng_fortyp, 440)`). The forest-type level is tighter and more
defensible (ME fortyp means ~450-495). Recommend either winsorizing the plot posterior to a
sane band (say 200-700) or preferring the fortyp-level value, so noisy plot tails do not distort
individual-plot capping.

## Implication for the harmonized CONUS rerun

The `gr_tpa` saturation (the critical runaway fix) is OUTSIDE the cap and always applies. But the
SDImax cap itself, and the cap-based parts of the fix (the `proj_tpa` scaling and the QMD
recompute), only engage when `--use_brms_sdimax` is set. The in-flight harmonized CONUS array
does NOT set it. If the maximum-SDI constraint is to be enforced (it should be, since it is what
keeps projected density on a biological ceiling), the harmonized runs need `--use_brms_sdimax`,
which means re-running them with that flag. That is a coordinated re-run decision.
