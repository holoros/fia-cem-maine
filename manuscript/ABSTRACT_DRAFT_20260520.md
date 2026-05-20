# Multistate carbon projection abstract draft

*Drafted 20 May 2026 for the multistate CEM paper.*

## Title (working)

"A coarsened exact matching framework for state-level forest carbon projection: cross-state extension, bias mechanism, and ecoregion stratification"

Alternates:
- "Donor pool composition limits transferability of FIA-based CEM forest carbon projections: diagnosis and stratified-matching remediation"
- "Forest carbon projection across heterogeneous ecoregions: the coarsened exact matching donor pool problem and a three-iteration remediation"

## Abstract (350 words target)

The coarsened exact matching (CEM) framework of Van Deusen and Roesch (2013) provides an analytically tractable basis for state-level forest carbon projection from FIA panel pair data, but its transferability across heterogeneous ecoregions has not been quantitatively documented. We extend the Maine CEM framework to three additional states (Minnesota, Washington, Georgia) representing the northern boreal, Pacific Northwest, and southeastern coastal plain biomes respectively, and report subject-matched hindcasts against the canonical FIA EXPALL EVALIDs spanning 2004 to 2024.

Across the four-state set, cross-state hindcast bias spans -25 percent (Washington) to +11 percent (Georgia), bracketing the canonical Maine reference of -1.1 percent on both sides. Diagnostic analyses of donor pool composition against the full CONUS FIA database reveal a universal mechanism: each state's neighbor-based donor cohort systematically underrepresents the dominant forest types of the subject state's forested inventory. Minnesota's aspen/birch and spruce/fir, dominant at 40 and 23 percent of subject area, occupy only 16 and 11 percent of the Lake States donor pool. Washington's west-side Douglas-fir and hemlock/Sitka spruce, dominant at 42 and 14 percent, occupy 33 and 3 percent of the Pacific Northwest interior donor pool. CEM matching transfers slower-growing donor type trajectories onto faster-growing subject types, suppressing projected biomass accumulation for Minnesota and Washington. Georgia's bias direction is opposite (+10 percent over) and traces to a separate mechanism: the stand-age saturation function leaves 95 percent of GA's plantation cohort (median age 20 years) at full unattenuated growth, combined with forest-type-agnostic BAU harvest selection that does not preferentially clearcut plantations at rotation age.

Notably, Maine's reference -1.1 percent bias arises despite the same dramatic donor pool mismatch (30 pp gap in spruce/fir): three compensating mechanisms (decoupled ClimateNA climate coupling, within-state `state_constants.csv` refinement, owner-balanced rescaling against published RPA rates) absorb the donor pool gap in the Maine reference. The other three states lack one or more of these compensations.

We propose and implement a three-iteration ecoregion-stratified CEM matching strategy that adds EPA L3 ecoregion as a matching key alongside the existing FORTYPCD and OWNGRPCD strata, with graceful fallback through Bailey-section-equivalent collapse and within-state leave-one-out matching. Empirical cell-size diagnostics across CONUS confirm feasibility: at the fine resolution 99.7 percent of subject conditions match at least one donor (median 3 matches). [Placeholder: actual bias reductions from full production reruns to be inserted: projected WA -25 to -5/-10 percent, MN -23 to -3/-8 percent, GA +10 to +3/+5 percent, ME canonical unchanged.]

The findings establish donor pool composition mismatch as the dominant transferability barrier for CEM forest projection across heterogeneous ecoregions, and ecoregion-stratified matching as a reproducible remediation path. The framework is computationally tractable, requires no new data beyond what the FIA database already publishes, and produces RPA-comparable state-level carbon projections suitable for the methodologically heterogeneous multi-model comparison community.

## Keywords

forest inventory and analysis, coarsened exact matching, carbon projection, ecoregion stratification, donor pool composition, transferability, RPA Assessment, multistate, methodological transfer
