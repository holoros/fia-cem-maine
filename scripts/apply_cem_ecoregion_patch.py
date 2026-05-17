#!/usr/bin/env python3
"""apply_cem_ecoregion_patch.py
Layer 7 patch: add cem_ecoregion to CEM matching keys in R/02_cem_matching.R.
"""
import pathlib

p = pathlib.Path("/users/PUOM0008/crsfaaron/fia_cem_projections/R/02_cem_matching.R")
text = p.read_text()

# 1) Insert coarsen_ecoregion helper before coarsen_sitecl
inject_after = "#' Coarsen site class code"
helper = '''#' Coarsen ecoregion (EPA L3 code)
#' Layer 7 patch (17 May 2026): add ecoregion as a CEM matching key.
#' Required to address donor pool composition mismatch documented in
#' CEM_3WAY_STRATIFICATION_20260517.md and MULTISTATE_DONOR_POOL_4PANEL_20260517.md.
#' @param l3code EPA L3 ecoregion code (integer or NA)
#' @param level Coarsening level: 1 (full L3), 2 (section), 3 (drop)
#' @param l3_to_section_lookup Optional data.table us_l3code -> section_code
#' @return Coarsened ecoregion key
coarsen_ecoregion <- function(l3code, level = 1, l3_to_section_lookup = NULL) {
  if (is.null(l3code)) return(integer(0))
  n <- length(l3code)
  if (all(is.na(l3code))) return(rep(0L, n))
  if (level == 1) {
    out <- as.integer(l3code)
    out[is.na(out)] <- 0L
    return(out)
  } else if (level == 2) {
    if (is.null(l3_to_section_lookup)) {
      fp <- file.path("config", "l3_to_section.csv")
      if (file.exists(fp)) {
        l3_to_section_lookup <- data.table::fread(fp, showProgress = FALSE)
      }
    }
    if (!is.null(l3_to_section_lookup)) {
      idx <- match(l3code, l3_to_section_lookup$us_l3code)
      out <- l3_to_section_lookup$section_code[idx]
      out[is.na(out)] <- "UNKNOWN_SECTION"
      return(as.character(out))
    } else {
      return(as.integer(l3code) %/% 10L)
    }
  } else {
    return(rep(0L, n))
  }
}

'''
if "coarsen_ecoregion" not in text:
    text = text.replace(inject_after, helper + inject_after, 1)
    print("Helper coarsen_ecoregion inserted")
else:
    print("Helper already present; skipping")

# 2) Add cem_ecoregion to apply_coarsening iter1
old1 = """      cem_condprop = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp   = OWNGRPCD,
        cem_fortyp   = FORTYPCD,
        cem_stdorg   = STDORGCD,"""
new1 = """      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp    = OWNGRPCD,
        cem_fortyp    = FORTYPCD,
        cem_ecoregion = coarsen_ecoregion(if ("us_l3code" %in% names(data)) us_l3code else STATECD, level = 1),
        cem_stdorg    = STDORGCD,"""
if old1 in text:
    text = text.replace(old1, new1)
    print("iter1 patched")
else:
    print("WARN: iter1 pattern not found")

# 3) Iter 2
old2 = """      cem_condprop = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp   = coarsen_owngrp(OWNGRPCD, level = 2),
        cem_fortyp   = FORTYPCD,
        cem_stdorg   = STDORGCD,"""
new2 = """      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp    = coarsen_owngrp(OWNGRPCD, level = 2),
        cem_fortyp    = FORTYPCD,
        cem_ecoregion = coarsen_ecoregion(if ("us_l3code" %in% names(data)) us_l3code else STATECD, level = 2),
        cem_stdorg    = STDORGCD,"""
if old2 in text:
    text = text.replace(old2, new2)
    print("iter2 patched")
else:
    print("WARN: iter2 pattern not found")

# 4) Iter 3: drop ecoregion
old3 = """      cem_condprop = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp   = 1L,  # drop ownership
        cem_fortyp   = FORTYPCD,
        cem_stdorg   = STDORGCD,"""
new3 = """      cem_condprop  = coarsen_condprop(CONDPROP_UNADJ),
        cem_owngrp    = 1L,
        cem_fortyp    = FORTYPCD,
        cem_ecoregion = 0L,
        cem_stdorg    = STDORGCD,"""
if old3 in text:
    text = text.replace(old3, new3)
    print("iter3 patched")
else:
    print("WARN: iter3 pattern not found")

# 5) Add cem_ecoregion to build_cem_key
old_keys = """  key_cols <- c("cem_condprop", "cem_owngrp", "cem_fortyp", "cem_stdorg",
                "cem_sitecl", "cem_age", "cem_ba")"""
new_keys = """  key_cols <- c("cem_condprop", "cem_owngrp", "cem_fortyp", "cem_ecoregion",
                "cem_stdorg", "cem_sitecl", "cem_age", "cem_ba")"""
if old_keys in text:
    text = text.replace(old_keys, new_keys)
    print("build_cem_key patched")
else:
    print("WARN: build_cem_key pattern not found")

p.write_text(text)
print("Layer 7 ecoregion patch applied")
