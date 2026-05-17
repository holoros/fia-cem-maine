# WA west-of-Cascade donor pool prototype: simple LON cutoff does not help

*Generated 17 May 2026 from `scripts/wa_westside_donor_prototype.R` run on Cardinal.*

## TLDR

The simple Remediation Path 1 from `WA_DONOR_POOL_DIAGNOSTIC_20260517.md` (restrict OR donors to plots west of -122 longitude) does NOT improve the overall donor pool match for WA. The total absolute gap across the top 8 WA forest type groups actually rises from 0.401 (current OR+ID+MT) to 0.457 (OR westside only). The restriction trades one form of mismatch for another: it eliminates interior pine overrepresentation but creates a Douglas-fir overrepresentation. Adding WA westside plots as donors (Remediation Path 2 leave-one-out style) brings the total gap to 0.410, essentially equivalent to current. The deeper Remediation Path 3 (Bailey ecological section as a CEM matching covariate) remains the most promising methodological direction.

## Donor pool sizes

| Configuration | Conditions |
|---|---:|
| Current (OR + ID + MT) | 15,816 |
| OR westside only (LON < -122) | 5,589 |
| OR west + WA west | 7,563 |

## Per forest type group, top 8 WA groups

Sign convention: gap = WA share - donor share. Positive gap means donor is UNDER-represented (good remediation reduces |gap|).

| Group | WA share | Current donor | OR westside only | OR west + WA west |
|---|---:|---:|---:|---:|
| Douglas-fir | 41.6% | 32.6% (+9.0) | 59.9% (-18.2) | 56.1% (-14.5) |
| Fir / spruce / mountain hemlock | 15.9% | 16.2% (-0.3) | 8.4% (+7.4) | 7.8% (+8.1) |
| Hemlock / Sitka spruce | 14.1% | 3.0% (+11.1) | 6.2% (+7.9) | 11.3% (+2.8) |
| Ponderosa pine | 9.0% | 16.7% (-7.8) | 2.7% (+6.2) | 2.0% (+7.0) |
| Alder / maple | 7.1% | 2.4% (+4.6) | 7.6% (-0.5) | 10.3% (-3.2) |
| Nonstocked | 3.6% | 3.2% (+0.4) | 1.9% (+1.7) | 2.2% (+1.4) |
| Lodgepole pine | 3.4% | 9.8% (-6.4) | 1.6% (+1.9) | 1.3% (+2.1) |
| Western larch | 1.8% | 1.3% (+0.5) | 0.0% (+1.8) | 0.0% (+1.8) |
| **Total absolute gap** | | **0.401** | **0.457** | **0.410** |

## Interpretation

The simple longitude cut over-corrects:

1. **Interior pine types collapse, but Douglas-fir over-represents.** Current donor pool has 32.6 percent Douglas-fir, close to WA's 41.6 percent. OR westside only is 59.9 percent Douglas-fir, well above WA's share. The restriction drops the interior pines (lodgepole 9.8 to 1.6 percent, ponderosa 16.7 to 2.7 percent) but the residual is overwhelmingly Doug-fir from OR coastal counties.

2. **Hemlock/Sitka spruce only partially fills.** OR has some coastal hemlock/Sitka spruce, but not enough to match WA's 14.1 percent share. Westside OR shows 6.2 percent, a real improvement from 3.0 percent but still a 7.9 pp gap.

3. **Adding WA westside best matches hemlock but doesn't fix Doug-fir over.** The OR west + WA west config brings hemlock/Sitka spruce up to 11.3 percent (a 2.8 pp gap, much improved). But the Douglas-fir share remains 56.1 percent vs WA's 41.6, an 14.5 pp over-representation.

## What this means for the WA -25 percent hindcast bias

The Remediation Path 1 won't fix the WA bias because it does not preserve WA's actual forest type composition in the donor pool. CEM matching that draws from a donor pool with 60 percent Douglas-fir will preferentially apply Douglas-fir growth trajectories to all WA subject plots, including the 14 percent hemlock/Sitka spruce subjects. The bias direction would flip from underestimate to overestimate as the donor pool shifts from interior-dominated to coastal-Doug-fir-dominated.

The findings sharpen the methodology recommendation: **Bailey ecological section (or finer EPA L3 ecoregion) stratified CEM matching is the right remediation path**. Restricting the geographic donor pool alone does not preserve forest type composition; stratified matching at the ecological-region level forces the matcher to find a donor with similar forest type composition AND similar climate envelope.

## Remediation paths revised

| Path | Description | Expected effect | Effort |
|---|---|---|---|
| 1. Simple OR westside cut | Restrict OR donors to LON < -122 | NOT EFFECTIVE: flips bias from -25% to potential +X% via Douglas-fir over-representation | 1 hr |
| 2. WA as own donor (leave-one-out) | Include WA westside plots as donors with leave-one-out | PARTIALLY EFFECTIVE: hemlock match improves, Doug-fir over remains | 3 hr |
| 3. Bailey ecological section stratification | Add Bailey section as a CEM matching covariate | LIKELY EFFECTIVE: stratifies before geographic restriction | 4 to 8 hr |
| 4. Forest type as CEM matching covariate | Add TYPGRPCD to the CEM matching set | LIKELY EFFECTIVE: forces forest-type-aware matching | 2 hr; risk of over-matching small cells |

Recommended next step before manuscript: Path 4 or Path 3. Path 4 is faster but may produce empty CEM cells for rare forest types. Path 3 is slower but methodologically cleaner.

## Files

- `scripts/wa_westside_donor_prototype.R` — analysis script with 3 donor pool configurations
- `figures/wa_westside_donor_prototype.png` — 4-way cascading bar comparison
- `figures/wa_westside_donor_comparison.csv` — per TYPGRPCD by config
- `figures/wa_westside_donor_gap_table.csv` — gap by config for top 8 WA groups
- `figures/wa_westside_donor_prototype_summary.txt` — text summary
