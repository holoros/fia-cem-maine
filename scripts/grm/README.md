# Macroplot-aware FIA GRM gross growth

Refinement of the GRM plot-summary pipeline in response to John Shaw's
2026-05-22 email ("FIA growth calcs").

## The issue

When a tree crosses the 5 in subplot threshold, FIA estimates its T1 and
midpoint diameters so the ingrowth receives a gross growth value that is added
to the remeasured trees. The same is not done for trees crossing the macroplot
threshold (24 in interior West, 30 in coastal PNW). The original GRM script
compounded this by expanding every flux with the subplot design only
(`SUBP_TPAGROW_UNADJ_AL_FOREST`), so in macroplot states the entire macroplot
tree pool was dropped from gross growth, removals, and mortality.

## Two parts to the fix

1. **Code** (`GRM_2026_macroplot_aware.R`). Expands each flux with
   subplot **+** macroplot design TPA (`combine_designs`). Microplot is
   deliberately excluded so the 5 in ingrowth already booked on the subplot is
   not double counted (adding microplot inflated Maine gross growth by ~146%,
   an artifact). On data without `MACR_` columns the script is an exact no-op,
   so eastern states (e.g. Maine) reproduce the original results. An optional,
   off-by-default `reconstruct_macro_ingrowth()` scaffold mirrors the subplot
   ingrowth treatment for trees crossing the macroplot threshold; it requires a
   volume model and validation against EVALIDator before use.

2. **Data** (`fia_grm_extract_macroplot.R`). The current GRM exports on Cardinal
   (per-state CSVs and the `fia_db_*.rds` rFIA databases) are 78-column
   `TREE_GRM_COMPONENT` tables with **no `MACR_*` columns and empty
   `SUBPTYP_BEGIN/MIDPT/END`**. Verified across OR, WA, ME, and the WA+CA rFIA
   database (937,693 records). The macroplot accounting was lost at extraction
   time, so the code fix is a no-op on this data until the tables are re-pulled
   with the full schema. This script re-pulls from the FIA DataMart and asserts
   the `MACR_*` columns are present.

## Verification done

- Refined logic parses and runs at scale on Cardinal (WA+CA, 937,693 rows);
  identical to subplot-only because `MACR_` is absent (safe no-op confirmed).
- Synthetic macroplot case: a 24/30 in crosser contributes 0 under the old code
  and is recovered under subplot+macroplot.
- Maine real data: subplot-only and subplot+macroplot identical (no macroplots).

## Next step

Run `fia_grm_extract_macroplot.R` for the macroplot states, point
`GRM_2026_macroplot_aware.R` `data_dir` at the re-pulled files, and validate the
corrected gross growth against an EVALIDator query for one PNW state.
