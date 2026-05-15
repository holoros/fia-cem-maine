# Carbon to volume ratio sanity check across the p1 multistate set

*Generated 13 May 2026 from the six p1 cycle 1 BAU baselines.*

A quick biophysical sanity check on the aboveground carbon density per cubic foot of net merchantable stemwood. The ratio of `mean_carbon_mean` (kg AGC per acre) to `mean_vol_mean` (cuft net per acre) gives an effective kg C per cuft. Published values vary by species mix because total tree carbon includes branches, foliage, bark, and roots not counted in merchantable cubic volume, so the ratio runs higher than the pure stemwood carbon density of approximately 7 to 10 kg C per cuft (assuming 500 kg per m3 wood density, 50 percent carbon fraction, and 0.0283 m3 per cuft).

| State | RCP | Per ac C (kg/ac) | Per ac vol (cuft/ac) | C:V (kg/cuft) | Interpretation |
|---|---|---:|---:|---:|---|
| MN | 4.5 | 33,650 | 1,241 | 27.1 | Lake States mixed conifer hardwood, plausible |
| MN | 8.5 | 33,677 | 1,242 | 27.1 | Identical at cycle 1 baseline |
| WA | 4.5 | 62,569 | 3,133 | 20.0 | Pacific NW conifer dominant, lower as expected |
| WA | 8.5 | 62,642 | 3,136 | 20.0 | Identical at cycle 1 baseline |
| GA | 4.5 | 35,214 | 1,326 | 26.6 | Southern pine plantation, intermediate |
| GA | 8.5 | 35,281 | 1,328 | 26.6 | Identical at cycle 1 baseline |
| ME r21 4.5 | 4.5 | 43,970 | 1,533 | 28.7 | Northern mixed (ME canonical) |

## Reading

The WA ratio of 20.0 sits at the low end because Pacific NW conifer stands hold most of their biomass in merchantable stemwood relative to branches and foliage. The MN, GA, and ME ratios in the high 20s are consistent with mixed forests where a larger fraction of the aboveground biomass is in non merchantable components (small trees, branches, foliage, plus dense northern hardwood components in MN and ME).

GA at 26.6 is slightly higher than I would expect for southern pine plantation forestry, where stems dominate the biomass distribution. Worth comparing against published Pinus taeda allometric ratios as a sanity step before relying on GA carbon values for downstream calculations.

## Cross state divergence by RCP at cycle 1

RCP 4.5 and RCP 8.5 produce essentially identical cycle 1 baselines (year 2004) across all three states. This is the expected pattern because the climate divergence between scenarios accumulates over the projection horizon and is negligible at the 5 year mark. Divergence should be evident by cycle 5 (year 2024) and pronounced by cycle 10 (year 2049). The dual RCP comparison figures (separate, to build) will visualize this.

## Limitation

This is a back of envelope ratio check, not a formal validation. The "right" reference would be species specific stemwood density and crown ratio tables joined to the FORTYPCD distribution per state. Worth doing for the manuscript if reviewers ask about carbon density assumptions.
