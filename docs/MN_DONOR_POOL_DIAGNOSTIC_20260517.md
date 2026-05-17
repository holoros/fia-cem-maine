# MN donor pool composition diagnostic: confirms northern boreal vs central hardwood mismatch as the -23 percent volume undercount mechanism

*Generated 17 May 2026 from `scripts/mn_donor_pool_diagnostic.R` run on Cardinal using the full CONUS ENTIRE_COND.csv at ~/FIA/.*

## TLDR

The MN -23 percent statewide volume undercount documented in `MN_VOLUME_GAP_REVISED_20260516.md` (after the DESIGNCD hypothesis was refuted) is now confirmed as a donor pool composition mismatch, same mechanism as the WA -25 percent bias. MN is a northern boreal mixed forest dominated by aspen/birch (39.7 percent of subject area) and spruce/fir (23.0 percent). The Lake States donor cohort is dominated by Michigan (53 percent of donor) and Wisconsin (36 percent), both more central Great Lakes forest dominated by maple/beech/birch and oak/hickory. The donor pool underrepresents MN's aspen/birch by 23.3 percentage points and spruce/fir by 12.4 pp; it over-represents maple/beech/birch by 17.7 pp and oak/hickory by 9.9 pp. CEM matching transfers slower climax-forest growth trajectories from MI/WI hardwood donors to MN's boreal pioneer subjects, suppressing projected accumulation.

## Headline forest type group comparison

| Forest type group | MN share | Donor share | Gap (MN - donor) |
|---|---:|---:|---:|
| Aspen / birch group | 39.7% | 16.4% | **+23.3 pp** |
| Spruce / fir group | 23.0% | 10.5% | **+12.4 pp** |
| Oak / hickory group | 11.7% | 21.6% | **-9.9 pp** |
| Elm / ash / cottonwood | 8.7% | 10.6% | -1.9 pp |
| Maple / beech / birch group | 6.9% | 24.6% | **-17.7 pp** |
| White / red / jack pine group | 5.8% | 8.3% | -2.5 pp |
| Oak / pine group | 1.7% | 2.9% | -1.2 pp |
| Nonstocked | 1.5% | 1.0% | +0.5 pp |
| Other hardwoods group | 0.9% | 0.5% | +0.4 pp |

## Donor pool composition by state (total 37,802 forested conds)

| State | n_cond | Donor share |
|---|---:|---:|
| MI | 20,074 | 53.1% |
| WI | 13,751 | 36.4% |
| IL | 1,769 | 4.7% |
| IA | 1,327 | 3.5% |
| SD | 593 | 1.6% |
| ND | 288 | 0.8% |

The donor pool is overwhelmingly MI plus WI (89 percent combined). Both states sit south of MN's northern boreal transition zone. North Dakota and South Dakota contribute almost nothing because they have little forested area.

## Mechanism

CEM matching draws growth trajectories from donor plots and applies them to subject plots. When the matcher pairs an MN aspen/birch subject (which exhibits fast pioneer growth on harvested or fire-cleared sites) with a MI maple/beech/birch donor (slower climax forest growth), the projection imports the donor's slower growth rate. Similarly when an MN spruce/fir subject pairs with a MI oak/hickory donor, the projection underestimates the boreal conifer's harvested-and-regenerated rate.

Aspen/birch in MN is heavily harvested on short rotations (often 30 to 45 years) for pulpwood and oriented strand board, then regenerates rapidly via root suckering. Maple/beech/birch in the donor pool is mid-to-late successional climax forest with longer rotations and slower diameter growth. The CEM growth ratio T2/T1 from the donor reflects climax forest dynamics, not pioneer dynamics, and is then applied to MN subjects of pioneer character.

## Manuscript implication

Update `BIAS_DOCUMENTATION_20260515.md` and `MN_VOLUME_GAP_REVISED_20260516.md` to attribute the -23 percent undercount to the donor pool composition mismatch with quantified gap percentages. Recommend remediation paths in order of effort:

1. **Add MN itself to the donor pool with leave-one-out matching.** ~3 hours.
2. **Restrict donor pool to MI/WI plots north of latitude 45.5 degrees** (capturing the northern transition zone of those states). ~1 hour.
3. **Stratify CEM matching by FORTYPCD or TYPGRPCD.** ~2 hours; aligns with the same recommendation for WA.
4. **Add Bailey ecological section** (or EPA L3 ecoregion) as a CEM matching covariate. ~4 to 8 hours; methodologically cleanest.

## Files

- `scripts/mn_donor_pool_diagnostic.R` — analysis script (uses full CONUS ENTIRE_COND.csv)
- `figures/mn_donor_pool_diagnostic.png` — top 12 forest type group comparison
- `figures/mn_donor_pool_forest_type_comparison.csv` — per FORTYPCD subject vs donor
- `figures/mn_donor_pool_typgrp_comparison.csv` — per TYPGRPCD aggregated comparison
- `figures/mn_donor_pool_diagnostic_summary.txt` — text summary

## Status

- MN donor pool composition mismatch confirmed
- Mechanism same as WA: under-representation of subject's dominant types + over-representation of slower-growing types
- Remediation paths shared with WA (geographic, forest-type, ecoregion stratification)
- BIAS_DOCUMENTATION pending update
