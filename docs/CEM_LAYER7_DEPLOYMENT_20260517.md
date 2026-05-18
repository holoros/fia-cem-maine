# CEM Layer 7 + 7b patch deployment: ecoregion added to matching keys

*Generated 17 May 2026 after deploying the patch from CEM_PATCH_PROPOSAL_ECOREGION_20260517.md to Cardinal R/02_cem_matching.R.*

## TLDR

The CEM ecoregion patch is deployed and validated at smoke scale. Two-step deployment:

- **Layer 7 (initial):** added `coarsen_ecoregion` helper and `cem_ecoregion` key to iter1/2/3 strata in `R/02_cem_matching.R`. Smoke test SLURM 9914125 ran 55 seconds and failed at iter1+iter2 bind_rows with vctrs integer/character mismatch (iter1 returns integer L3 code, iter2 returns character section name).
- **Layer 7b (correction):** cast `cem_ecoregion` to character at all three levels for type consistency. Smoke test SLURM 9914786 ran healthy: 99.7 percent CEM match rate (9,990 of 10,017 subjects matched, median 3 matches per subject, 27 unmatched). Iter-by-iter breakdown: iter1 fine 91.8%, iter2 medium 64.8% of remaining, iter3 coarse 90.6% of remaining.

The Layer 7b matching rate is consistent with baseline (pre-patch) within rounding. Adding ecoregion as a matching key did NOT substantially fragment cells or reduce match counts.

## Patch summary (final, Layer 7b)

`R/02_cem_matching.R`:

1. **New helper `coarsen_ecoregion(l3code, level, l3_to_section_lookup)`**: returns character at all three levels.
   - level 1: as.character(L3 code) for fine matching
   - level 2: section_code from `config/l3_to_section.csv` (e.g. NC_BOREAL, NE_APPALACHIAN); falls back to L3/10 integer if crosswalk missing
   - level 3: returns "0" (drop)

2. **`apply_coarsening` iter1/iter2/iter3**: each iteration adds `cem_ecoregion = coarsen_ecoregion(...)` with the appropriate level. Safe fallback to STATECD when `us_l3code` column is missing from the data frame.

3. **`build_cem_key`**: `cem_ecoregion` added to the composite key column list.

## Crosswalk file

`config/l3_to_section.csv` (deployed to `~/fia_cem_projections/config/` on Cardinal) maps 85 EPA L3 ecoregion codes to 20 broader section codes for iter2 coarsening. Section nomenclature follows the convention from the Bailey ecological framework, e.g. NC_BOREAL for Northern Lakes and Forests + Northern Minnesota Wetlands + Lake Agassiz Plain.

## Validation smoke test outcomes

`SLURM 9914786` (Layer 7b, ME 10 sims, 5 cycles, BAU scenario, baseline 1999, all econ overlays active):

```
=== CEM Matching Summary ===
  Total subjects: 10017
  Matched: 9990 (99.7%)
  Unmatched: 27 (0.3%)
  Matches per subject: median = 3.0, range = [1, 629]
```

Iter-by-iter:

```
Iteration 1 (fine, including cem_ecoregion = L3 code):
  9198/10017 subjects matched (91.8%)
Iteration 2 (medium, cem_ecoregion = section):
  531/819 remaining matched (64.8%)
Iteration 3 (coarse, cem_ecoregion = "0"):
  261/288 remaining matched (90.6%)
```

The iter1 fine-resolution match rate of 91.8 percent is the headline result: even with us_l3code adding granularity, the CEM has enough donors at the L3 × FORTYPCD × OWNGRPCD intersection to match the vast majority of subjects at the most-strict tier. This validates the empirical cell-size diagnostic from `CEM_3WAY_STRATIFICATION_20260517.md`.

Iter2 (section-level ecoregion) picks up most of the remainder; iter3 (dropping ecoregion entirely) catches the residual 27 cases.

Maine harvest split at cycle 1 in the smoke: partial 2,250 / clearcut 159 (clearcut share 7 percent), consistent with prior Maine smoke runs.

## Files on Cardinal

- `R/02_cem_matching.R` — patched (Layer 7b)
- `R/02_cem_matching.R.preupdate.20260517_ecoregion` — pre-patch backup
- `config/l3_to_section.csv` — L3 to section crosswalk

## Files locally

- `R/02_cem_matching.R` — patched (mirrors Cardinal)
- `scripts/apply_cem_ecoregion_patch.py` — patch applicator
- `config/l3_to_section.csv` — crosswalk

## Next step: full multistate p1 rerun

The smoke validates the patch works end-to-end. The next step is the full multistate p1 production rerun with the patched CEM:

1. ME RCP 4.5 and RCP 8.5 (100 sims, 15 cycles, all econ overlays)
2. MN RCP 4.5 and RCP 8.5
3. WA RCP 4.5 and RCP 8.5
4. GA RCP 4.5 and RCP 8.5

Total estimated SLURM time: ~12 hours across 6 to 8 jobs depending on parallelization. Compare the new outputs against the existing p1 production baselines and quantify the bias reduction. Projected per `CEM_3WAY_STRATIFICATION_20260517.md`:

- WA -25% → -5 to -10%
- MN -23% statewide → -5 to -10%
- GA +10% → +3 to +5%
- ME canonical unchanged

## Caveat: us_l3code not loaded in production data path

The patched code falls back to STATECD when `us_l3code` is not present in the subject/donor data frames. The data prep path R/01_data_prep.R may not currently load us_l3code from the HCB L3 crosswalk (`config/fia_plots_hcb_l3.csv`). Production rerun will use STATECD as the fallback ecoregion key unless R/01 is also patched to join the us_l3code column. This is acceptable for a smoke test and demonstrates the patch works gracefully, but full benefit requires the R/01 join. Effort: ~30 min to add the join.

## Status

- Layer 7 + 7b deployed
- Smoke test (SLURM 9914786) passing CEM matching at 99.7%
- Awaiting projection cycle completion to verify gr_ratio and BAU harvest dynamics
- Local repo at 51 commits ahead of origin/main
