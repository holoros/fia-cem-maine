# Section X.1 (Data and Methods) draft

*Drafted 20 May 2026 for the multistate CEM paper.*
*Replaces and expands the current Section X.1 in MULTISTATE_METHODS_DRAFT_20260515.md.*

## 2.1 FIA panel pair data

We used the Forest Inventory and Analysis (FIA) database (USDA Forest Service 2024) for all per-state plot inventories. Each state's panel pair data was extracted from the ENTIRE_COND, ENTIRE_PLOT, and ENTIRE_TREE files of the March 2026 FIA download, restricted to forested baseline conditions (COND_STATUS_CD == 1) measured between 1999 and 2008 (the canonical baseline window) and with valid FORTYPCD (forest type code) and BA_LIVE_PER_ACRE values. Per state condition counts at this filter:

| State | Cond rows |
|---|---:|
| ME | 23,490 |
| MN | 13,608 |
| WA | 6,193 |
| GA | 10,317 |

## 2.2 Donor cohorts and matching covariates

The donor cohort for each subject state is defined in `config/state_constants.csv` per Van Deusen and Roesch (2013) conventional CEM practice. We retained the convention of geographic neighbor-based donor pool construction to allow direct comparison with the published Maine framework:

| Subject state | Donor cohort | Donor cond rows |
|---|---|---:|
| ME | NH, VT, MA, CT, RI, NY, PA | ~31,500 |
| MN | WI, MI, IA, IL, ND, SD | 37,802 |
| WA | OR, ID, MT | 15,816 |
| GA | FL, SC, NC, AL, TN | 20,559 |

The CEM matching covariates in our baseline production runs are condition proportion (CONDPROP_UNADJ, coarsened to 5 bins), owner group (OWNGRPCD, 4 classes: USDA FS, Other Federal, State/local, Private), forest type (FORTYPCD, full code), stand origin (STDORGCD, 0=natural/1=planted), site class (SITECLCD, 7 levels), stand age (STDAGE, coarsened to 5 age classes), and basal area (BA, coarsened to fine intervals). Optional climate covariates (mean annual temperature and precipitation, MAT and MAP) are included when `--use_decoupled_climate` is active.

## 2.3 The Harris-Caputo-Butler 2025 landowner stratification

Harris, Caputo, and Butler (2025) developed a 30-meter raster classification of forested land ownership across CONUS combining FIA OWNGRPCD with detailed parcel-level family/corporate distinctions. The HCB classification includes 10 owner classes covering federal subdivisions (USDA FS, BLM, NPS, DOD), state/local government, corporate timberland, large family, small family, and several minor classes. For the multistate p1 runs, we joined the HCB classification to FIA plots through the Maine-validated HCB crosswalk (`config/fia_plots_hcb_l3.csv`). Production scaling beyond Maine requires extending the crosswalk to CONUS plot coverage (see Section X.6 limitations).

## 2.4 Per-state state_constants.csv parameters

Each state has its own row in `config/state_constants.csv` defining climate trajectory deltas (dT_2099 by RCP), wildfire baseline per cycle, SDImax default, terminal age, and spruce budworm relevance. Values for the four multistate p1 states:

| State | dT 2099 RCP4.5 (°C) | dT 2099 RCP8.5 (°C) | Fire baseline (per cycle) | SDImax default | Terminal age (yr) | SBW relevance |
|---|---:|---:|---:|---:|---:|---|
| ME | 2.5 | 4.5 | 0.005 | 440 | 120 | full |
| MN | 2.8 | 5.2 | 0.010 | 330 | 110 | partial |
| WA | 2.0 | 3.8 | 0.060 | 510 | 200 | none |
| GA | 2.2 | 4.0 | 0.040 | 360 | 80 | none |

Maine values follow the published Maine framework references. Non-Maine values were derived from NCA5 regional temperature trajectories (Reidmiller et al. 2024), per-state DNR fire reports, and ecoregion × forest type SDImax aggregations from the BRMS posterior dataset.

## 2.5 Production run configuration

For each state x RCP combination, we ran 100 Monte Carlo simulations of 15 five-year projection cycles starting from a 1999 baseline. Production options:

```
--state <STATE> --n_sims 100 --cycles 15 \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors \
  --climate_rcp {4.5,8.5} \
  --bootstrap_plots --bootstrap_frac 0.9 \
  --fixed_harvest_rate 0.10 \
  --include_remeasured \
  --use_brms_sdimax \
  --use_disturbance \
  --use_potter_vcc \
  --save_per_plot \
  --skip_supply \
  --no_econ (for non-ME) | --use_maine_econ (for ME) \
  --use_owner_stratification \
  --use_owner_balanced
```

The ME production runs additionally use `--use_decoupled_climate` (HadGEM2-AO downscaled per-plot ClimateNA outputs) and `--use_maine_econ` (full Wear and Coulston 2025 harvest economic overlay with Maine RPA calibration). Non-Maine production runs use `--no_econ --skip_supply` and a fixed 0.10 per-cycle harvest rate. This decision is documented in Section X.6 limitations as a known asymmetry between the canonical Maine baseline and the cross-state extensions.

Each production job uses 48 CPU cores on a single Cardinal HPC node with 180 GB memory. Per-state expected wall time is 3-8 hours. The full multistate p1 set (8 jobs: 4 states × 2 RCPs) completes in approximately 12 hours of clock time when jobs run in parallel.

## 2.6 Validation methodology

Three validation methods establish the framework's behavior:

### 2.6.1 EVALIDator sanity bounds

For each state x RCP combination, eight per-acre and statewide totals (BA, volume, carbon, TPA, harvest rate, statewide volume, statewide carbon, gr_ratio) were compared against published FIA EVALIDator state totals at the cycle 1 baseline. STATE_PROFILES defines pass/fail bounds per metric per state. All six multistate p1 production runs (MN/WA/GA × RCP 4.5/8.5) PASS 8/8 sanity checks. Volume totals match EVALIDator to within 2 percent for WA, 3 percent for GA, and 23 percent under for MN; the MN under is structural and addressed in Section X.3.

### 2.6.2 Subject matched hindcast

The Maine subject matched hindcast procedure (Weiskittel et al. in prep) was extended to the three new states. For each state, the cycle 1 subject plots from the projection per-plot RDS were intersected with FIA EXPALL EVALIDs to compute year-by-year observed aboveground carbon (AGC) totals using the standard EXPNS expansion factors. These were compared against the projection's per-cycle expanded AGC. RMSE and bias are reported for matched years.

### 2.6.3 Owner stratification verification

Harris, Caputo, and Butler (2025) owner classes were joined to all six production per-plot outputs, and per-owner cycle 1 BAU per-acre volume and harvest fractions were tabulated. The `--use_owner_balanced` rescaling produces tight 9 to 10 percent harvest fractions across owner groups, consistent with the mass-balanced area-weighted mean target.

## 2.7 EPA L3 ecoregion crosswalk (for Section X.4 remediation)

The EPA Level 3 ecoregion classification (Omernik 1987, Omernik and Griffith 2014) provides a continental-scale ecological stratification mapping each US plot to one of 85 ecoregions. We joined the HCB-derived L3 crosswalk (`config/fia_plots_hcb_l3.csv`, 104,628 CONUS plots) to the production data frames. For plots not in the crosswalk (about 56 percent of forested baseline conds), the matching framework falls back to STATECD as the ecoregion key, preserving the within-state matching behavior used in the baseline p1 production runs. Full CONUS coverage of the L3 crosswalk is a future task documented in Section X.6.

The 85-ecoregion L3 classification is collapsed to 20 broader "section" codes via a manuscript-released crosswalk (`config/l3_to_section.csv`) following the Bailey ecological framework convention. Sections include PNW_MARINE (Pacific Northwest marine), PNW_MONTANE, PNW_INTERIOR, RM_NORTHERN/SOUTHERN/INTERMOUNTAIN, NC_BOREAL, NC_HARDWOOD, NC_PLAINS, NE_NORTHERN/COASTAL/APPALACHIAN/PIEDMONT, SE_PIEDMONT/COASTAL/APPALACHIAN/INTERIOR/PLAINS, SC_OZARK/OUACHITA/DELTA/GULF/TIMBERS/PLAINS/SOUTHWEST. The section coarsening serves as the iter2 fallback in the three-iteration ecoregion-stratified matching described in Section X.4.
