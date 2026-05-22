# Multistate carbon projection abstract draft

*Drafted 20 May 2026 for the multistate CEM paper.*

## Title (working)

"A coarsened exact matching framework for state-level forest carbon projection: cross-state extension, the donor pool composition mechanism, and a transferability limit"

Alternates:
- "Donor pool composition limits transferability of FIA-based CEM forest carbon projections: diagnosis and stratified-matching remediation"
- "Forest carbon projection across heterogeneous ecoregions: the coarsened exact matching donor pool problem and a three-iteration remediation"

## Abstract (350 words target)

The coarsened exact matching (CEM) framework of Van Deusen and Roesch (2013) provides an analytically tractable basis for state-level forest carbon projection from FIA panel pair data, but its transferability across heterogeneous ecoregions has not been quantitatively documented. We extend the Maine CEM framework to three additional states (Minnesota, Washington, Georgia) representing the northern boreal, Pacific Northwest, and southeastern coastal plain biomes respectively, and report subject-matched hindcasts against the canonical FIA EXPALL EVALIDs spanning 2004 to 2024.

Across the four-state set, cross-state hindcast bias spans -25 percent (Washington) to +11 percent (Georgia), bracketing the canonical Maine reference of -1.1 percent on both sides. Diagnostic analyses of donor pool composition against the full CONUS FIA database reveal a universal mechanism: each state's neighbor-based donor cohort systematically underrepresents the dominant forest types of the subject state's forested inventory. Minnesota's aspen/birch and spruce/fir, dominant at 40 and 23 percent of subject area, occupy only 16 and 11 percent of the Lake States donor pool. Washington's west-side Douglas-fir and hemlock/Sitka spruce, dominant at 42 and 14 percent, occupy 33 and 3 percent of the Pacific Northwest interior donor pool. CEM matching transfers slower-growing donor type trajectories onto faster-growing subject types, suppressing projected biomass accumulation for Minnesota and Washington. Georgia's bias direction is opposite (+10 percent over) and traces to a separate mechanism: the stand-age saturation function leaves 95 percent of GA's plantation cohort (median age 20 years) at full unattenuated growth, combined with forest-type-agnostic BAU harvest selection that does not preferentially clearcut plantations at rotation age.

Notably, Maine's reference -1.1 percent bias arises despite the same dramatic donor pool mismatch (30 pp gap in spruce/fir): three compensating mechanisms (decoupled ClimateNA climate coupling, within-state `state_constants.csv` refinement, owner-balanced rescaling against published RPA rates) absorb the donor pool gap in the Maine reference. The other three states lack one or more of these compensations.

We then test three donor side remedies against the largest bias, Washington. A three-iteration ecoregion-stratified matching strategy that adds EPA L3 ecoregion alongside the FORTYPCD and OWNGRPCD strata, with graceful fallback, is feasible at the matching level (99.7 percent of subject conditions match a donor at fine resolution) but does not change the Washington hindcast (residual unchanged at minus 79 MMT). Expanding the donor pool to the full continental FIA database including California likewise leaves it unchanged, because California donors carry a lower growth potential than the Pacific Northwest maritime forest. Matching on a continental site productivity surface (asymptotic aboveground biomass) reduces the Washington percent bias on matched plots from minus 25 to minus 14 percent, but only by leaving roughly half of the high-productivity subject plots unmatched, a coverage loss continental donors do not repair. These convergent results show Washington's high-productivity maritime Douglas-fir has no analog in the FIA donor universe.

The findings establish donor pool composition mismatch as the dominant transferability barrier for CEM forest projection across heterogeneous ecoregions. Where donor analogs exist the framework transfers well, as in Maine, Minnesota, and Georgia; where the subject forest is a site-productivity outlier without a donor analog, as in Washington, donor substitution reaches a fundamental limit, and a model-based productivity correction rather than a better donor search is the remediation path. The framework is computationally tractable, requires no new data beyond what the FIA database already publishes, and produces RPA-comparable state-level carbon projections suitable for the methodologically heterogeneous multi-model comparison community.

## Keywords

forest inventory and analysis, coarsened exact matching, carbon projection, ecoregion stratification, donor pool composition, transferability, RPA Assessment, multistate, methodological transfer
