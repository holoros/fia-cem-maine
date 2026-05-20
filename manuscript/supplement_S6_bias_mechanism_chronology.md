# Supplementary S6: Bias mechanism investigation chronology

*Manuscript supplement documenting the 13-20 May 2026 diagnostic suite as a methodological transparency record.*

## Purpose

This supplement records the hypothesis-testing chronology of the bias mechanism investigation, including hypotheses that were initially documented and later refuted. The intent is to provide a transparent record of how the multistate p1 cross-state biases were diagnosed, what diagnostics ruled out alternative explanations, and which findings ultimately drove the manuscript's mechanism narrative.

## Investigation chronology

### 13 May 2026: Initial bias documentation, smoke validation phase

- Multistate p1 production runs landed for MN, WA, GA × RCP 4.5, RCP 8.5.
- Initial hindcast bias estimates produced: MN -5.7%, WA -25%, GA +10%.
- Initial speculation in bias documentation (later partially refuted): MN gap "could reflect the DESIGNCD periodic plot exclusion (a known issue from the ME r17 work) or the HCB owner downscale at 74 percent agreement".
- Documented in `docs/VALIDATION_SYNTHESIS_20260513.md`.

### 14-15 May 2026: Validation framework + bias signal confirmation

- Subject matched hindcasts run for all 6 multistate p1 outputs.
- Carbon unit bug discovered and fixed (lb/ac vs kg/ac, ratio 2.20). Re-ran all hindcasts.
- Bias signals confirmed at production scale; not artifacts.
- BIAS_DOCUMENTATION_20260515.md drafted with initial candidate mechanisms.

### 16 May 2026: MN DESIGNCD hypothesis investigated and REFUTED

- Initial hypothesis: MN -23 percent statewide volume undercount due to DESIGNCD periodic plot filter excluding pre-2004 Lake States plots.
- Test: SLURM 9676388 ran MN-only diagnostic with baseline year shifted from 1999 to 2004 (aligning with MN's annualized FIA inventory start).
- Result: 2004 baseline produced 21.8 Bcuft vs 1999 baseline 21.6 Bcuft. Essentially identical.
- Conclusion: DESIGNCD filter is NOT the dominant cause. Documented in `docs/MN_VOLUME_GAP_REVISED_20260516.md`.
- Original DESIGNCD attribution doc (`docs/MN_VOLUME_GAP_ROOT_CAUSE_20260516.md`) flagged as SUPERSEDED.

### 16 May 2026: conus_hcs RPA aggregation cascade (5 patches)

- Layer 19: posterior_epred on list (regime-split fit). Fixed.
- Layer 19b: NaN in quantile() summary. Fixed.
- Layer 20: M4 HCS fit graceful skip. Fixed.
- Layer 21: STATECD type mismatch in left_join. Fixed.
- Layer 22: rpa_subregion column collision in left_join. Fixed; SLURM 9717200 succeeded.
- Cascade complete; aggregation produces 4 subregions (NC, SE, SC, PNW).
- M1 saturation flagged: median p_any = 0.873 vs Maine RPA reference 0.10. Documented in `docs/RPA_AGGREGATION_RESULTS_20260516.md`.

### 17 May 2026: WA donor pool diagnostic CONFIRMS mechanism

- Hypothesis: WA -25% bias due to donor pool composition.
- Test: `scripts/wa_donor_pool_diagnostic.R` against FIA COND for WA + OR/ID/MT 1999-2008 baseline.
- Result: Hemlock/Sitka spruce gap +11.1 pp; Doug-fir +9.0 pp; interior pine over-representation -7 to -8 pp.
- Conclusion: Donor pool composition mismatch CONFIRMED as the dominant -25% mechanism.
- Documented in `docs/WA_DONOR_POOL_DIAGNOSTIC_20260517.md`.

### 17 May 2026: GA plantation/natural donor mixing REFUTED

- Hypothesis: GA +10% bias due to plantation/natural donor mixing.
- Test: `scripts/ga_donor_pool_diagnostic.R` against FIA COND.
- Result: GA has 43% plantation-indicative types vs donor pool 30%. GA has MORE plantations than its donor pool, opposite of the hypothesis.
- Conclusion: Simple plantation/natural mixing REFUTED as dominant GA mechanism. Documented in `docs/GA_DONOR_POOL_DIAGNOSTIC_20260517.md`.

### 17 May 2026: WA west-of-Cascade donor restriction prototype REFUTED

- Hypothesis (Remediation Path 1): Restrict OR donors to LON < -122 would close WA gap.
- Test: `scripts/wa_westside_donor_prototype.R`.
- Result: Total absolute gap rises 0.401 to 0.457; restriction trades interior-pine over-representation for Douglas-fir over-representation. Would flip bias direction.
- Conclusion: Simple geographic donor restriction is NOT effective; need forest-type-aware or ecoregion stratification.
- Documented in `docs/WA_WESTSIDE_DONOR_PROTOTYPE_20260517.md`.

### 17 May 2026: GA bias Candidate 1 (multiplicative effect) REFUTED

- Hypothesis: GA's high productivity baseline × normal donor growth ratio = inflated absolute growth.
- Test: `scripts/multistate_growth_rate_comparison.R` using small CSVs (no 6.2GB RDS).
- Result: GA cycle 1 rel growth rate 0.0122 is the HIGHEST of 4 states (vs ME 0.0065). GA's rate is genuinely high, not normal applied to high baseline.
- Conclusion: Multiplicative effect REFUTED as dominant GA mechanism.
- Documented in `docs/GA_BIAS_CANDIDATES_20260517.md`.

### 17 May 2026: GA bias Candidate 4 (stand-age saturation) CONFIRMED

- Hypothesis: GA's young plantations escape sat_age attenuation because terminal_age = 80, growth_start_age = 60, and plantation rotations are 25-35 years.
- Test: `scripts/ga_bias_candidate_diagnostic.R` against GA COND with sat_age computation.
- Result: 95.4 percent of GA plantation-indicative conditions have sat_age = 1.0 (full unattenuated growth); median age 20, 95% under 60.
- Conclusion: Stand-age saturation under-application CONFIRMED as dominant GA mechanism. Combined with forest-type-agnostic BAU harvest selection (Candidate 3 companion), this produces the +10% over.
- Documented in `docs/GA_BIAS_CANDIDATES_20260517.md`.

### 17 May 2026: MN Lake States donor pool diagnostic CONFIRMS mechanism

- Hypothesis: MN -23% statewide volume gap due to Lake States donor pool composition.
- Test: `scripts/mn_donor_pool_diagnostic.R` using full CONUS ENTIRE_COND.csv now available at ~/FIA/.
- Result: MN aspen/birch +23.3 pp gap, spruce/fir +12.4 pp gap. Donor pool 89% MI+WI (central Great Lakes hardwood) underrepresents MN's northern boreal mix.
- Conclusion: Donor pool composition mismatch CONFIRMED for MN. Same mechanism as WA.
- Documented in `docs/MN_DONOR_POOL_DIAGNOSTIC_20260517.md`.

### 17 May 2026: 4-state donor pool comparison reveals ME is NOT canonical

- Test: `scripts/multistate_donor_pool_figure.R` covering ME, MN, WA, GA in 4-panel.
- Surprise finding: ME shows 30 pp gap in spruce/fir relative to its Northeast donor cohort; 32 pp gap in oak/hickory.
- ME's -1.1% bias arises despite the same dramatic mismatch.
- Mechanism: 3 compensating mechanisms in Maine production absorb the donor pool gap (ClimateNA decoupled climate coupling, within-Maine state_constants refinement, owner-balanced rescaling against published Maine RPA rates).
- Conclusion: Donor pool composition mismatch is UNIVERSAL across all 4 states; what differs is compensation. Documented in `docs/MULTISTATE_DONOR_POOL_4PANEL_20260517.md`.

### 17 May 2026: CEM 3-way stratification feasibility CONFIRMED

- Question: Can ecoregion × FORTYPCD × OWNGRPCD serve as CEM matching covariates without leaving too many empty subject cells?
- Test: `scripts/cem_ecoregion_fortyp_cell_sizes.R` (2-way) and `scripts/cem_3way_strat_cell_sizes.R` (3-way) against full CONUS ENTIRE_COND.
- Result: 2-way gives 156 cells, 33% with >=30 conds, 4% subj conds in low-donor cells. 3-way with OWNGRPCD gives 332 cells, 37% with >=30 conds, 3.1% subj conds in low-donor cells. The 3-way IMPROVES on 2-way because owner structure aligns naturally with geography.
- Conclusion: 3-way stratification feasible at L3 × FORTYPCD × OWNGRPCD with three-tier fallback. Documented in `docs/CEM_3WAY_STRATIFICATION_20260517.md`.

### 17 May 2026: M2 fit unit gap RESOLVED

- Question: Why does conus_hcs RPA removal_per_ha appear at 6-16% of RPA 2016 baseline?
- Test: Inspected M2 brms fit at `~/conus_hcs/models/m2_intensity_partial/fit.qs`.
- Result: M2 predicts `intensity_y`, a Beta-distributed dimensionless fraction [0,1] of stand removed per cycle. Partial median 0.398; clearcut median 0.999. The "-84 to -93% pct_diff" was a unit-comparison artifact. After unit conversion (fraction × mean stand vol ÷ cycle length), conus_hcs over-predicts RPA by 2.5x-3.7x — consistent with re-measured panel pair training bias. A ~0.35 correction factor would reconcile.
- Documented in `docs/M2_UNIT_RESOLUTION_20260517.md`.

### 17 May 2026: CEM Layer 7+7b ecoregion patch deployed

- Patch: Added `coarsen_ecoregion` helper + `cem_ecoregion` key to iter1/2/3 strata in `R/02_cem_matching.R`.
- Layer 7b: Cast cem_ecoregion to character at all three levels for type consistency.
- Smoke test SLURM 9914786 (ME 10-sim 5-cycle): 99.7% CEM match rate, BA/volume/carbon trajectories within sampling of L2 baseline.
- Documented in `docs/CEM_LAYER7_DEPLOYMENT_20260517.md` and `docs/CEM_LAYER7_SMOKE_RESULT_20260517.md`.

### 17-20 May 2026: 2020 RPA Assessment baselines transcribed

- Source: 2020 RPA Assessment WO-GTR-102 (USDA Forest Service July 2023), Chapter 6 Figure 6-4.
- 2016 CONUS total removals: 13 Bcuft/yr.
- Region shares: North 19.2%, South 60.4%, Pacific Coast 17.3%, Rocky Mountain 3.1%.
- Subregion baselines pro-rated by within-region timberland area share.
- `~/conus_hcs/config/rpa_baselines.csv` populated; conus_hcs RPA aggregation rerun produced pct_diff column.
- Documented in `docs/RPA_COMPARISON_RESULTS_20260517.md`.

### 20 May 2026: Layer 7b production reruns queued

- 8 SLURM jobs submitted (10021618-10021625): ME, MN, WA, GA × RCP 4.5, RCP 8.5.
- 100 simulations × 15 cycles × all econ overlays per state.
- Expected wall time: ~3-8 hours per job; ~12 hours total clock time in parallel.
- Output dirs: `<STATE>_20260520_rcp<rcp>_wear_l7b/`.

### 20 May 2026: Manuscript skeleton drafted

- Abstract: `manuscript/ABSTRACT_DRAFT_20260520.md` (350 words, 3 title alternatives)
- Introduction: `manuscript/INTRODUCTION_DRAFT_20260520.md` (1200 words, 6 subsections)
- Methods Section X.1: `manuscript/SECTION_X1_DATA_AND_METHODS_DRAFT_20260520.md` (7 subsections)
- Methods Section X.2 (bias mechanism): `manuscript/SECTION_X2_BIAS_MECHANISM_DRAFT_20260520.md` (6 subsections)
- Results outline + Suppl materials: `manuscript/RESULTS_OUTLINE_AND_SUPPL_20260520.md` (figures + tables index)
- Discussion: `manuscript/DISCUSSION_DRAFT_20260520.md` (6 subsections + conclusion)
- All sections await the Layer 7b production results for bias reduction numbers.

## Methodological transparency

This supplement is intended as transparency about hypothesis testing rather than as a primary source. The diagnostic suite tested multiple plausible bias mechanisms and refuted several. The final published mechanism narrative (donor pool composition + GA stand-age saturation auxiliary) is the result of empirical convergence, not the first hypothesis chosen. The chronology demonstrates that the framework is testable and that alternative hypotheses can be ruled out with FIA data alone.

For each refuted hypothesis, the diagnostic memo at `docs/` retains the analysis. Future researchers extending this work should consult both the manuscript and the memos.
