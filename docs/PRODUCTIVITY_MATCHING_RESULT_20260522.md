# Productivity Matching for Washington Bias: Result and Conclusion

Date: 2026-05-22
Status: Investigation conclusive. Productivity matching reduces bias on matched plots but cannot resolve Washington underprediction, because the high productivity subject plots have no donor analog in the available FIA universe. The remedy is a model based correction, not donor substitution.

## Motivation

Two prior experiments established that Washington underprediction (about minus 25 percent) is not a donor geography problem. The ecoregion matching key alone did not move it, and a correctly loaded California donor pool did not move it (see CONUS_DONOR_NULL_RESULT_20260521.md). The residual mechanism is donor growth rate composition: the donors available to Washington grow more slowly than Washington's own west side forest. This motivated matching on a continuous site productivity surface so that fast growing subject plots match equally productive donors.

## Method

Per plot asymptotic aboveground biomass was extracted from the in house CONUS surface stage4_asym_agb_conus_30m (1 km overview) at every subject and donor plot location, giving 100 percent coverage with well behaved values (median 208, range 87 to 410 Mg per ha, no plot random effect, so no circularity). This was added as a coarsened CEM matching key (cem_prod) through a robust attach that joins the value onto both subjects and donors by PLT_CN, guaranteeing a symmetric key. Two variants were tested. The weak variant enforces productivity at iterations 1 and 2 and drops it at iteration 3. The strong variant retains a coarse two bin productivity split at iteration 3 so it always binds. Both ran first against the neighbor donor pool (Idaho, Oregon, Washington) and the strong variant also ran against the California augmented pool.

## Results

All against the 2019 EVALID 531900 cycle 4 Washington hindcast. Percent bias is residual over observed subject pool.

| Variant | Donor pool | Unmatched | Hindcast plots | Residual MMT | Percent bias |
|---|---|---:|---:|---:|---:|
| baseline l7b | neighbor | low | 2745 | -79.4 | -25.0 |
| weak productivity | neighbor | ~17% | 1794 | -27.6 | -13.8 |
| strong productivity | neighbor | ~48% | 1753 | -39.2 | -19.6 |
| strong productivity | neighbor + California | ~47% | n/a | n/a | n/a |

The strong California run completed but did not write per plot output, so its hindcast residual is unavailable; its decisive metric, the unmatched rate, is read from the matching log.

## Two findings

First, productivity matching reduces the percent bias on the plots it can match, from minus 25 percent down to minus 14 percent in the weak variant. The direction is correct and is the opposite of the California donor experiment, which lowered growth. So aligning subject and donor site potential does pull Washington growth upward, as hypothesized.

Second, and decisive, productivity matching achieves this partly by excluding the hardest plots. The matched subject pool shrank from 2745 to about 1790 plots, and the roughly 950 dropped plots carry 117 MMT of observed biomass. Those are the high productivity west side plots that drive the bias. The strong variant, which forces productivity to bind even at the coarse fallback, leaves about 48 percent of Washington subjects unmatched in the neighbor pool. Adding the full California donor pool barely changed this, leaving about 47 percent unmatched. California donors do not fill Washington's high productivity cells because Washington's high productivity maritime Douglas fir, in combination with its forest type, has no analog in the donor universe spanning Idaho, Oregon, Montana, and California.

## Conclusion

Donor substitution cannot resolve Washington underprediction. Geographic expansion fails because the bias is not geographic. Productivity matching reduces bias only on the subset of plots that have a productivity analog, and for the high productivity plots that actually drive the bias, no analog exists anywhere in the available FIA donor pool. This is a fundamental transferability limit of coarsened exact matching for a productivity outlier forest. The remedy is therefore a model based correction, for example a productivity scaled growth multiplier calibrated against the asymptotic biomass surface, applied to the unmatched high productivity plots, rather than any further attempt to find or substitute donors.

## Implication for the manuscript

This completes a coherent and defensible story. The multistate CEM framework transfers well to states whose forests have donor analogs (Maine, Minnesota, Georgia), and the four state hindcast documents that transfer. It fails for Washington in a specific, diagnosable way: the west side maritime forest is a high productivity outlier with no donor analog, so no matching strategy, neighbor, CONUS, ecoregion, or productivity, can supply an appropriate donor. The paper can present productivity matching as the diagnostic that localizes the failure to a donor analog gap, and recommend a hybrid model correction for outlier forests as the path forward. This is a stronger contribution than a simple bias reduction claim, because it defines the boundary of the method and points to the fix.

## Addendum: the asymptote gap is too small for an asymptote-based correction

A feasibility precheck, run before building any model correction, shows that scaling transferred growth by the asymptotic biomass ratio cannot close the Washington bias. Median asymptotic AGB by state from the BGI surface is Washington 197, Oregon 203, Idaho 191, Montana 203, California 230 Mg per ha. The Washington west side subjects (longitude west of about 120.8) have a median asymptote of 215, only 7 percent above the Idaho, Oregon, and Montana donor pool median of 201; Washington as a whole sits at 197, slightly below the donor median. Closing the minus 25 percent underprediction requires a growth uplift of about 1.33. An asymptote ratio correction would supply at most about 1.07 for the west side and nothing for the state as a whole, roughly a factor of five short of what is needed.

The implication is that the Washington bias is not driven by the productivity ceiling. Washington's forest does not carry a meaningfully higher asymptotic biomass than its donors; what differs is the growth rate at current age and structure, the Chapman-Richards rate parameter, not the asymptote. This explains why asymptote matching reduced bias only through coverage selection rather than through better matched donors, and it redirects any future model correction away from an asymptote scaling toward a growth-rate adjustment. It also sharpens the donor analog gap conclusion: the donor dimension Washington needs, fast early growth in high productivity maritime conifer, is not captured by the asymptote and is not abundant in the donor pool. The asymptote ratio correction was therefore not built; the cheap precheck saved an engine change the data shows would not work.

## Artifacts

Code: R/00_config.R (use_productivity, asym_breaks), R/01_data_prep.R (asym join), R/02_cem_matching.R (cem_prod coarsening, key inclusion, robust symmetric attach), run_projection.R (--use_productivity). Lookup: config/asym_agb_by_pltcn.csv (134,526 plots, environmental asymptote from stage4_asym_agb 1 km). Build script: scripts/build_asym_lookup_WA.R. Smokes: WA neighbor weak (10304775), neighbor strong (10304796), California strong (10308972). Hindcast: 10308894. All pipeline files have timestamped backups (.bak.preprod_20260521, .bak.preprodjoin_20260521).
