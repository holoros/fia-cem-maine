# Proposed CEM patch: add cem_ecoregion to the matching keys

*Generated 17 May 2026 after inspecting `R/02_cem_matching.R`.*

## Key discovery

The current CEM matching at `R/02_cem_matching.R` ALREADY uses both `OWNGRPCD` (as `cem_owngrp`) and `FORTYPCD` (as `cem_fortyp`) in its matching keys. The actual gap in the matching is that **ECOREGION (us_l3code or Bailey section) is not a matching key**. That is why donor pool composition mismatches drive bias: the matcher pairs an MN aspen-birch FORTYPCD 901 OWNGRPCD 40 subject with a MI aspen-birch FORTYPCD 901 OWNGRPCD 40 donor as long as the other coarsened keys (condprop, sitecl, stdage, BA) match. There is no check that the donor sits in the same northern boreal ecoregion as the subject.

## Current keys in iter1 (build_cem_key)

```r
key_cols <- c("cem_condprop", "cem_owngrp", "cem_fortyp", "cem_stdorg",
              "cem_sitecl", "cem_age", "cem_ba")
```

Plus optional climate (`cem_mat`, `cem_map`) when `cfg$climate$use_climate = TRUE`.

## Proposed patch

Add `cem_ecoregion` to the key set, populated from `us_l3code` if the ecoregion attribute is present on the subject and donor data frames, otherwise fall back to STATECD (which is what implicit current behavior gives within-state).

### Patch to `apply_coarsening` (iter1):

```r
# Iter 1: full strict matching including ecoregion
if (iteration == 1) {
  data <- data |>
    mutate(
      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
      cem_owngrp    = OWNGRPCD,
      cem_fortyp    = FORTYPCD,
      cem_ecoregion = if ("us_l3code" %in% names(data)) us_l3code else STATECD,  # NEW
      cem_stdorg    = STDORGCD,
      cem_sitecl    = SITECLCD,
      cem_age       = coarsen_age(STDAGE, cem_cfg$iter1$stdage_breaks),
      cem_ba        = coarsen_ba(BA, method = "fine")
    )
}
```

### Patch to iter2 (already relaxes OWNGRPCD; relax ecoregion to Bailey section or regional collapse):

```r
# Iter 2: relax OWNGRPCD (already done) and ecoregion (NEW)
} else if (iteration == 2) {
  data <- data |>
    mutate(
      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
      cem_owngrp    = coarsen_owngrp(OWNGRPCD, level = 2),
      cem_fortyp    = FORTYPCD,
      cem_ecoregion = if ("us_l3code" %in% names(data)) coarsen_ecoregion(us_l3code, level = 2) else STATECD,  # NEW
      cem_stdorg    = STDORGCD,
      cem_sitecl    = coarsen_sitecl(SITECLCD, cem_cfg$iter2$siteclcd_breaks),
      cem_age       = coarsen_age(STDAGE, cem_cfg$iter2$stdage_breaks),
      cem_ba        = coarsen_ba(BA, breaks = cem_cfg$iter2$ba_breaks)
    )
}
```

### Patch to iter3 (already drops OWNGRPCD; drop ecoregion entirely):

```r
# Iter 3: drop OWNGRPCD (already done) and drop ecoregion
} else if (iteration == 3) {
  data <- data |>
    mutate(
      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
      cem_owngrp    = 1L,
      cem_fortyp    = FORTYPCD,
      cem_ecoregion = 1L,  # drop ecoregion
      cem_stdorg    = STDORGCD,
      cem_sitecl    = coarsen_sitecl(SITECLCD, cem_cfg$iter3$siteclcd_breaks),
      cem_age       = coarsen_age(STDAGE, cem_cfg$iter3$stdage_breaks),
      cem_ba        = coarsen_ba(BA, breaks = cem_cfg$iter3$ba_breaks)
    )
}
```

### Patch to `build_cem_key`:

```r
key_cols <- c("cem_condprop", "cem_owngrp", "cem_fortyp", "cem_ecoregion",
              "cem_stdorg", "cem_sitecl", "cem_age", "cem_ba")
```

### New helper: `coarsen_ecoregion`

```r
coarsen_ecoregion <- function(l3code, level = 1) {
  if (level == 1) {
    return(l3code)  # full L3 resolution
  } else if (level == 2) {
    # Collapse L3 to Bailey section (a coarser ecological grouping)
    # CONUS L3 ecoregions cluster naturally into ~10 sections (eastern
    # mixed forest, eastern broadleaf, mid-continent prairie-forest,
    # northern boreal, southern coastal plain, Pacific NW marine, etc.)
    # The crosswalk would live at config/l3_to_section.csv.
    crosswalk <- read_l3_to_section_crosswalk()  # NEW config file
    return(crosswalk[match(l3code, crosswalk$us_l3code), section])
  } else {
    return(1L)  # drop
  }
}
```

## Required data infrastructure

Beyond the code patch, ECOREGION must be attached to plot data BEFORE matching. Current state:

- `config/fia_plots_hcb_l3.csv` covers ~104k plots out of ~239k forested baseline conds (44% coverage). Used in the existing diagnostic test.
- For production use, need geospatial join of remaining ~135k plots to EPA L3 ecoregions, OR use the FIA `EPA_L3` column already present in some FIADB extracts (ENTIRE_COND.csv may have ECOREGION attributes — needs check).

Production-ready fast path:
1. Use the existing 44% coverage as Tier 1.
2. For plots without us_l3code, fall back to STATECD (the existing implicit behavior). This gracefully degrades to current behavior for unattributed plots.
3. Schedule the geospatial fill as a separate maintenance task (~4 hours).

## Implementation plan

1. **Add `coarsen_ecoregion` helper** to `R/02_cem_matching.R` (15 min)
2. **Update `apply_coarsening`** to add `cem_ecoregion` to iter1/2/3 (30 min)
3. **Update `build_cem_key`** to include `cem_ecoregion` (5 min)
4. **Build `config/l3_to_section.csv` crosswalk** for iter2 coarsening (~1 hr; from EPA L3 ecoregion documentation)
5. **Smoke test ME, MN, WA, GA each with 10 simulations** to confirm cell counts and matching success rates are healthy (~1 hr)
6. **Full production rerun all 6 multistate p1 outputs** with the patched CEM (~12 hr SLURM time)
7. **Re-run hindcasts and validation** for the 6 outputs (~2 hr)
8. **Update manuscript Section X.2 with revised bias percentages**

Total elapsed: ~12 hr code + ~12 hr SLURM time = roughly 2 days of work.

## Projected impact

Per `CEM_3WAY_STRATIFICATION_20260517.md`:
- WA -25% → -5 to -10%
- MN -23% statewide → -5 to -10%
- GA +10% → +3 to +5%
- ME canonical reference unchanged

If the patch lands and reruns produce within those projections, the manuscript bias documentation can move from "documented as known limitation" to "demonstrated and quantitatively reduced by stratified matching" — a substantially stronger narrative.

## Status

- Patch design complete
- Not deployed; needs explicit user approval before modifying R/02_cem_matching.R
- All projections subject to confirmation from the smoke test rerun
