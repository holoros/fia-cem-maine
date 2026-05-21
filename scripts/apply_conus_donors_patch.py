#!/usr/bin/env python3
"""apply_conus_donors_patch.py
Add a --conus_donors flag to run_projection.R that expands the donor pool to
all available FIA states. Combined with the Layer 7b cem_ecoregion matching
key, this implements a CONUS-wide ecoregion-membership donor pool: donors are
drawn from all states but the matcher restricts to same-ecoregion donors.

Safe: opt-in flag, default behavior (neighbor-state cohort) unchanged.
"""
import pathlib

p = pathlib.Path("/users/PUOM0008/crsfaaron/fia_cem_projections/run_projection.R")
text = p.read_text()

# 1) Add CLI flag parsing next to --untreated_donors
anchor = '''      } else if (args[i] == "--untreated_donors") {
        parsed$untreated_donors <- TRUE; i <- i + 1'''
addition = '''      } else if (args[i] == "--untreated_donors") {
        parsed$untreated_donors <- TRUE; i <- i + 1
      } else if (args[i] == "--conus_donors") {
        parsed$conus_donors <- TRUE; i <- i + 1'''
if "--conus_donors" not in text:
    text = text.replace(anchor, addition, 1)
    print("CLI flag --conus_donors added")
else:
    print("CLI flag already present")

# 2) Honor the flag when setting donor states
anchor2 = '''    # Update donor states based on region
    CONFIG$donor_states <- get_donor_states(cli_args$state)'''
addition2 = '''    # Update donor states based on region
    if (isTRUE(cli_args$conus_donors)) {
      # CONUS-wide ecoregion-membership donor pool. Donors drawn from all
      # available FIA states; the Layer 7b cem_ecoregion matching key
      # restricts actual matches to same-ecoregion donors. This addresses the
      # finding (L7B_HINDCAST_RESULTS_20260520.md) that bias-driving subject
      # cells have no ecologically-matched donors in the neighbor cohort.
      CONFIG$donor_states <- get_all_available_states()
      cat("CONUS-wide donor pool enabled: ",
          length(CONFIG$donor_states), " states\\n")
    } else {
      CONFIG$donor_states <- get_donor_states(cli_args$state)
    }'''
if "get_all_available_states()" not in text:
    text = text.replace(anchor2, addition2, 1)
    print("donor_states selection patched")
else:
    print("donor_states selection already patched")

# 3) Add get_all_available_states helper next to get_donor_states
anchor3 = "# --- Helper: get neighboring/donor states by region --------------------------"
helper3 = '''# --- Helper: all available FIA states for CONUS-wide donor pool --------------
# Returns the set of states with COND/TREE/PLOT files in FIA_DATA_DIR. Used
# with --conus_donors so the donor pool spans CONUS and the cem_ecoregion
# matching key (Layer 7b) restricts matches to same-ecoregion donors.
get_all_available_states <- function() {
  data_dir <- Sys.getenv("FIA_DATA_DIR", unset = file.path(Sys.getenv("HOME"), "fia_data"))
  cond_files <- list.files(data_dir, pattern = "_COND\\\\.csv$")
  states <- unique(sub("_COND\\\\.csv$", "", cond_files))
  states <- states[nchar(states) == 2]  # two-letter postal codes only
  if (length(states) == 0) {
    warning("get_all_available_states found no _COND.csv files; falling back to single state")
  }
  states
}

# --- Helper: get neighboring/donor states by region --------------------------'''
if "get_all_available_states <- function" not in text:
    text = text.replace(anchor3, helper3, 1)
    print("get_all_available_states helper added")
else:
    print("helper already present")

p.write_text(text)
print("conus_donors patch applied")
