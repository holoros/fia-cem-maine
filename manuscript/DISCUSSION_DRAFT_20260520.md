# Discussion section draft

*Drafted 20 May 2026 for the multistate CEM paper.*
*Intended to fit between the Results section and Limitations/Future Work.*

## 4.1 The donor pool composition problem is general to CEM

Coarsened exact matching has been adopted across the forest-projection literature as a tractable framework for connecting inventory data to growth-and-yield projections (Van Deusen and Roesch 2013; Woodall and Westfall 2018; Brooks and Wear 2024). Our cross-state extension reveals a heretofore underdocumented limitation: when the donor cohort is defined by geographic adjacency rather than ecological similarity, the donor pool systematically underrepresents the dominant forest types of the subject state. The mechanism is mechanically simple, with the matcher pairing subjects to donors that share the existing matching keys (forest type, owner, age, basal area) but which represent slower-growing climax-forest trajectories from neighboring states.

The pattern operates universally across the four states examined. Minnesota's northern boreal aspen-birch and spruce-fir face a Lake States donor pool dominated by central Great Lakes maple-beech-birch. Washington's high-productivity coastal Douglas-fir and hemlock-Sitka spruce face an interior Pacific Northwest donor pool dominated by ponderosa and lodgepole pine. Georgia's southern pine plantations face a southeastern coastal donor pool relatively rich in oak-hickory. Maine's spruce-fir faces a Northeast donor pool dominated by NY and PA hardwoods.

The mechanism's universality runs counter to the conventional intuition that geographically proximate states share forest types. Our results suggest that ecological transition zones (the Cascade crest, the southern boreal forest boundary, the southern Appalachian-Piedmont break) are sharper than political state lines in determining forest composition, and that traditional state-cohort donor pool construction crosses these transitions in ways that systematically suppress subject growth.

## 4.2 Why Maine's bias is small despite the dramatic mismatch

A perhaps more illuminating finding is that Maine's canonical reference -1.1 percent bias arises despite a dramatic donor pool mismatch (30 percentage point spruce-fir gap, 32 pp oak-hickory gap relative to the Northeast donor cohort). Three compensating mechanisms in the Maine production framework absorb the donor pool gap:

1. **Explicit ClimateNA decoupled climate coupling.** Maine production uses per-plot ClimateNA-derived temperature and precipitation projections through 2070 (HadGEM2-AO downscaled). This couples the projection to Maine's actual maritime-influenced climate trajectory rather than a single national climate multiplier.

2. **Within-state state_constants.csv refinement.** Maine has terminal_age = 120 (vs default 80 for GA, 110 for MN, 200 for WA), SDImax = 440 (calibrated to northern hardwood-conifer mix), and wildfire baseline 0.005 per cycle reflecting Maine's relatively low disturbance regime.

3. **Owner-balanced rescaling against published RPA rates.** Maine production applies `--use_owner_balanced` which rescales per-owner harvest fractions to match the published 2021 Forests of Maine RPA aggregate harvest rate of approximately 10 percent per cycle. This calibration step is Maine-specific and not currently applied to the other three states.

The contribution of each of these three compensations to the residual -1.1 percent has not been independently quantified in this paper. We hypothesize they enter approximately additively, with each absorbing some 5 to 10 percent of the donor pool gap, leaving the residual at the canonical reference.

The implication for the field is that bias-mitigation in a CEM forest projection is not just a question of donor pool selection; it depends on the interaction of donor pool, climate coupling, state-specific calibration parameters, and harvest module rescaling. The single largest leverage point is donor pool selection, but the other three each compound. Our proposed ecoregion-stratified matching addresses donor pool selection directly; the other three compensations should be considered in parallel.

## 4.3 Three-iteration ecoregion-stratified CEM as a portable remediation

The proposed remediation is portable because:

1. **Requires no new data.** EPA L3 ecoregion codes are available for all CONUS FIA plots via the HCB crosswalk (and easily extended to full coverage via spatial join). FORTYPCD and OWNGRPCD are in FIA COND directly. The L3-to-section crosswalk for iter2 coarsening is provided in the manuscript supplement (`config/l3_to_section.csv`, 85 ecoregions to 20 sections).

2. **Computationally tractable.** Empirical cell-size diagnostics show 99.7 percent of subject conditions match at least one donor at the finest tier. The three-iteration relaxation handles the residual cells gracefully.

3. **Reproducible across modeling frameworks.** The same ecoregion x forest type x owner stratification can be applied to other CEM-style forest projection systems (FOROM, RPA Forest Resources, the conus_hcs project) and even non-CEM frameworks where donor selection occurs.

4. **Aligned with ecological understanding.** Bailey ecological sections are the standard mid-level ecological stratification in US forest ecology; using EPA L3 ecoregions with a section-level coarsening lookup respects this convention.

## 4.4 Implications for the PERSEUS multi-model comparison

The PERSEUS effort compares four state-level forest carbon projection frameworks (FIA CEM, FVS NE/Acadian, GCBM/libcbm, LANDIS-II) using the Harris/Caputo/Butler 2025 landowner stratification as a cross-cutting refinement. Our findings suggest a parallel cross-cutting refinement should be considered: ecoregion-stratified subject pool definition. The current PERSEUS comparison uses subject pool definitions that vary by framework; standardizing to ecoregion-stratified subject and donor pools would isolate methodological differences from data-driven differences in projection skill.

## 4.5 Limitations and future work

[Inherited from existing Section X.3 + additional points:]

- HCB owner classification covers only Maine in the current crosswalk. CONUS extension is a multi-day geospatial task that would enable HCB's 10-class stratification instead of OWNGRPCD's 4-class.
- The Layer 7b ecoregion patch is validated at smoke scale (ME 10-sim) and at the cell-size feasibility level. Full production bias reduction from the 8-job multistate p1 rerun is the publishable headline number [to be inserted from production results].
- The GA stand-age saturation mechanism is identified but not corrected in the current Layer 7b patch. A `terminal_age` reduction for plantation FORTYPCDs is staged as a future iteration.
- ClimateNA decoupled climate coupling is only active for Maine because ClimateNA's desktop GUI workflow blocks automated execution across CONUS. Once per-state ClimateNA outputs are processed externally, decoupled climate coupling for MN, WA, GA would close additional residual bias.
- The conus_hcs RPA aggregation comparison (this paper's Section X.4) over-predicts the RPA 2016 baseline by 2.5x to 3.7x after unit conversion. The re-measurement bias correction factor (~0.35) is a methodological refinement applicable to all CEM frameworks that train on re-measured panel pairs.

## 4.6 Conclusion

State-level forest carbon projection using FIA panel pair data is methodologically tractable across heterogeneous ecoregions when donor pool composition is matched ecologically rather than geographically. The proposed three-iteration ecoregion-stratified CEM matching reduces multistate hindcast bias by approximately half [to be confirmed by production results] while preserving the canonical Maine reference framework. The findings reframe transferability in CEM forest projection from "donor pool selection is a state-by-state engineering decision" to "ecoregion-stratified donor pool construction is a portable methodological refinement that should be standard practice."
