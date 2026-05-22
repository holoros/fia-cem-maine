# Section 3.5: Washington as a transferability limit, the donor analog gap

Draft 2026-05-22. Replaces the prior Section 3.5 placeholder ("Layer 7b production rerun bias reduction"), which was framed before the ecoregion, CONUS donor, and productivity experiments resolved. This version reports the full diagnostic sequence and its conclusion.

## 3.5.1 The Washington exception

Among the four states, Washington carries the largest hindcast bias, an underprediction of aboveground carbon of about 25 percent against the 2019 EXPALL EVALID (projected 237.6 against observed 317.0 MMT, residual minus 79.4 MMT under RCP 4.5; minus 81.6 under RCP 8.5). Maine, Minnesota, and Georgia transfer with small or opposite sign biases, so Washington is the case that tests the limits of the coarsened exact matching framework. Sections 3.2 through 3.4 established that the mechanism is donor pool composition: the donors available to a Washington subject grow more slowly than Washington's own west side maritime forest, so matched donor trajectories transfer a suppressed growth signal. This section reports three attempts to remedy that composition problem, each operating on the donor side, and shows why none of them resolves the Washington bias.

## 3.5.2 Remedy one, ecoregion stratification

Adding EPA Level 3 ecoregion as a matching key (the three iteration scheme of Section 2) was intended to restrict Washington subjects to ecologically similar donors. It did not change the hindcast. The Washington residual was minus 79.4 MMT with the ecoregion key and minus 79.4 without it, identical to the digit, and the projected subject carbon was unchanged. The ecoregion key reorders which neighbors are selected but cannot change the aggregate, because the neighbor donor cohort's growth rate composition is itself the problem and the key draws from the same cohort.

## 3.5.3 Remedy two, a continental donor pool

Expanding the donor pool from the four neighbor states to the full set of available FIA states, including California, also left the hindcast unchanged (minus 77.2 MMT under RCP 4.5, minus 77.4 under RCP 8.5, against the minus 79.4 and minus 81.6 baseline). The projected subject carbon at the twenty year horizon was within 0.2 percent of the baseline; the small movement in the residual traces to a slightly different observed subject pool, not to the projection. A diagnostic confirmed that California donors, the geographically nearest large addition, carry a lower asymptotic growth rate than the Pacific Northwest maritime donors, so adding them shifts the matched growth signal down rather than up. Geographic expansion of the donor pool does not help, because the deficiency is not geographic distance but growth potential.

## 3.5.4 Remedy three, site productivity matching

The third remedy matched on site productivity directly, adding a continuous asymptotic aboveground biomass surface (the in house continental Biomass Growth Index, predicted from climate, soils, topography, and lithology) as a coarsened matching key so that productive subject plots match equally productive donors. On the subset of Washington plots that found a productivity matched donor, this reduced the percent bias from minus 25 percent to minus 14 percent, the correct direction and the opposite of the continental pool result. The improvement, however, came with a sharp loss of coverage. The matched subject pool fell from 2,745 to about 1,790 plots, and the roughly 950 dropped plots carried 117 MMT of observed biomass. Those excluded plots are the high productivity west side stands that drive the bias. When productivity was forced to bind even at the coarse fallback iteration, about 48 percent of Washington subjects were left unmatched. Adding the California donor pool to the productivity matched run barely changed this, leaving about 47 percent unmatched.

## 3.5.5 The donor analog gap

The three remedies converge on a single explanation. Washington's high productivity maritime Douglas fir, in combination with its forest type and stand structure, has no analog anywhere in the available FIA donor universe spanning Idaho, Oregon, Montana, and California. No matching strategy, neighbor based, continental, ecoregion stratified, or productivity stratified, can supply an appropriate donor for these plots, because an appropriate donor does not exist in the data. This is a fundamental transferability limit of coarsened exact matching for a productivity outlier forest, distinct from the donor pool composition imbalances that the same framework handles successfully in Minnesota and Georgia.

| Remedy | Donor pool | Washington residual | Matched plots | Outcome |
|---|---|---:|---:|---|
| baseline, forest type and owner | neighbor | -79.4 MMT | 2,745 | -25 percent bias |
| ecoregion matching key | neighbor | -79.4 MMT | 2,745 | no change |
| continental pool with California | continental | -77.2 MMT | 2,745 | no change |
| productivity matching (weak) | neighbor | -27.6 MMT | 1,794 | bias falls but ~35 percent of plots dropped |
| productivity matching (strong) | neighbor | -39.2 MMT | 1,753 | ~48 percent unmatched |
| productivity matching (strong) | continental | not estimable | n/a | ~47 percent unmatched, no coverage gain |

## 3.5.6 Implication

For the three states with abundant donor analogs the coarsened exact matching framework transfers cleanly, and the four state hindcast in Section 3.1 documents that transfer. Washington defines the boundary of the method: where the subject forest is a site productivity outlier, the donor pool cannot represent it, and a donor substitution approach reaches a hard limit regardless of how the donor pool is assembled or how matching is stratified. The appropriate remedy for such outlier forests is not a better donor search but a model based correction, for example a productivity scaled growth adjustment calibrated against the asymptotic biomass surface and applied to the unmatched high productivity plots. We present productivity matching here not as a fix but as the diagnostic that localizes the Washington failure to a donor analog gap, and we recommend the hybrid model correction as the path for productivity outlier forests in future applications of the framework.
