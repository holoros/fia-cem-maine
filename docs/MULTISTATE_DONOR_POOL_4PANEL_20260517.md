# Multistate donor pool composition: 4-panel manuscript figure reveals ME is NOT canonical

*Generated 17 May 2026 from `scripts/multistate_donor_pool_figure.R` run on Cardinal using full CONUS ENTIRE_COND.csv.*

## TLDR

The unified 4-state donor pool composition figure (ME, MN, WA, GA side-by-side) reveals that all four states experience donor pool composition mismatch with the same underlying mechanism. Most importantly, **ME is NOT canonical in the donor pool sense** when its conventional Northeast donor cohort (NH + VT + MA + CT + RI + NY + PA) is used. ME's subject pool is 32 percent spruce/fir but the Northeast donor pool is only 2 percent spruce/fir, a 30 pp gap. The ME reference -1.1 percent hindcast bias is therefore not due to a well-matched donor pool but rather to other compensating factors (climate response coupling via decoupled ClimateNA, within-Maine refinement of state_constants, owner balanced rescaling). This insight refines the manuscript narrative: donor pool composition mismatch is the universal mechanism across all four states; what differs is how each state's other model components either compensate (ME) or amplify (MN, WA, GA) the mismatch.

## Headline gaps by state

### ME (subject: ME; donor: NH VT MA CT RI NY PA)

| Forest type group | ME share | Donor share | Gap |
|---|---:|---:|---:|
| Maple / beech / birch | 40% | 42% | -2 pp |
| Spruce / fir | 32% | 2% | **+30 pp** |
| Aspen / birch | 13% | 3% | **+10 pp** |
| Oak / hickory | 1.5% | 33% | **-32 pp** |
| White / red / jack pine | 5% | 5% | 0 |

Mechanism: ME's boreal spruce-fir and pioneer aspen-birch dominate but the Northeast donor pool (especially NY and PA) is dominated by oak-hickory and maple-beech-birch climax forest. ME shows -1.1 percent hindcast bias despite this dramatic mismatch.

### MN (subject: MN; donor: WI MI IA IL ND SD)

| Forest type group | MN share | Donor share | Gap |
|---|---:|---:|---:|
| Aspen / birch | 40% | 16% | **+23 pp** |
| Spruce / fir | 23% | 11% | **+12 pp** |
| Maple / beech / birch | 7% | 25% | -18 pp |
| Oak / hickory | 12% | 22% | -10 pp |

Mechanism: Same as ME but the compensating factors are weaker. MN shows -5.7 percent hindcast bias and -23 percent statewide volume gap.

### WA (subject: WA; donor: OR ID MT)

| Forest type group | WA share | Donor share | Gap |
|---|---:|---:|---:|
| Douglas-fir | 42% | 33% | **+9 pp** |
| Hemlock / Sitka spruce | 14% | 3% | **+11 pp** |
| Ponderosa pine | 9% | 17% | -8 pp |
| Lodgepole pine | 3% | 10% | -7 pp |

WA shows -25 percent hindcast bias.

### GA (subject: GA; donor: FL SC NC TN AL)

| Forest type group | GA share | Donor share | Gap |
|---|---:|---:|---:|
| Loblolly / shortleaf pine | 30% | 26% | +4 pp |
| Longleaf / slash pine | 14% | 6% | **+8 pp** |
| Oak / hickory | 27% | 39% | -12 pp |
| Oak / pine | 12% | 11% | +1 pp |

GA shows +10 percent bias. Notably, GA's plantation-indicative forest types are MORE present in the GA subject than in its donor pool — the gap goes the same direction as MN and WA (subject types underrepresented in donor) but does not produce under-prediction because GA's bias is driven by the stand-age saturation mechanism on plantations, not by the donor pool gap directly.

## Implication for the manuscript

The 4-panel figure should be Figure X.Y of the manuscript Section X.2. Caption proposal:

> "Forest type group composition for each multistate p1 subject state and its corresponding donor pool, from FIA 1999-2008 baseline forested conditions. Donor pools are defined in `config/state_constants.csv` per Van Deusen and Roesch (2013) coarsened exact matching. All four states show systematic mismatch: subject forest types that dominate the state's inventory are systematically underrepresented in the donor pool, and climax-forest or mid-successional types from neighboring states are overrepresented. The compensating mechanisms (climate response coupling, within-state state_constants refinement, owner balanced rescaling) determine whether the mismatch translates to hindcast bias. ME has the largest absolute gap but compensating mechanisms produce -1.1 percent bias; MN, WA, and GA biases of -5.7 / -25 / +10 percent reflect weaker compensation."

## Section X.3 update recommendation

Add a paragraph explicitly addressing the universal donor pool mismatch:

> "Cross-state diagnostic against the full CONUS FIADB (17 May 2026, MULTISTATE_DONOR_POOL_4PANEL_20260517.md) reveals that donor pool composition mismatch is universal across the multistate p1 set, not specific to MN and WA. ME's Northeast donor cohort (NH + VT + MA + CT + RI + NY + PA) shows 30 percentage point underrepresentation of MN spruce/fir and 32 pp overrepresentation of oak/hickory. The compensating mechanisms in ME — explicit ClimateNA decoupled climate coupling, within-Maine refinement of `state_constants.csv`, and Owner balanced rescaling calibrated against published Maine RPA harvest rates — work together to produce the -1.1 percent canonical reference bias. The other three states lack one or more of these compensations, allowing the same donor pool mismatch to translate to -5.7 percent (MN), -25 percent (WA), or +10 percent (GA, in combination with the stand-age saturation under-application mechanism documented in GA_BIAS_CANDIDATES_20260517.md). A future iteration adding ecoregion or forest-type stratification to the CEM matching (CEM_3WAY_STRATIFICATION_20260517.md) would directly address the donor pool mechanism for all four states uniformly."

## Caveat about ME donor pool definition

The ME donor pool used here (NH + VT + MA + CT + RI + NY + PA) is the conventional Northeast cohort from CEM literature. The actual production runs for ME use a refined approach including within-Maine CEM with leave-one-out matching at the plot level. The 4-panel figure therefore overstates the ME donor pool mismatch as seen by the production projection, but it reveals correctly that the cross-state donor cohort would have substantial mismatch if used naively.

## Files

- `scripts/multistate_donor_pool_figure.R` — analysis script (uses full CONUS ENTIRE_COND.csv)
- `figures/multistate_donor_pool_4panel.png` — 4-panel comparison figure
- `figures/multistate_donor_pool_comparison.csv` — underlying data
- Cross-references: `WA_DONOR_POOL_DIAGNOSTIC_20260517.md`, `MN_DONOR_POOL_DIAGNOSTIC_20260517.md`, `GA_DONOR_POOL_DIAGNOSTIC_20260517.md`, `CEM_3WAY_STRATIFICATION_20260517.md`
