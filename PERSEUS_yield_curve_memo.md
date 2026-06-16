# Memo: PERSEUS FIA yield curve engine, refinement and the "decline" question

**To:** PERSEUS team
**From:** A. Weiskittel
**Re:** Why the FIA yield curves looked like they declined, and what changed
**Status:** deployed to https://holoros.github.io/perseus-forest-intelligence (db v0.60)

## Short version

The reserve (no harvest) curves do not decline. CONUS aboveground carbon under a
reserve rises about 63 percent over 100 years, which is consistent with the FIA
remeasurement record (forests are currently a net sink of roughly 1.1 percent per
year). The declines you saw were in the managed scenarios, and they came from a
modeling assumption that was too aggressive, not from the growth biology. That
assumption has now been corrected and the latest outputs are live.

## What the engine now does

All five FIA stock metrics (live carbon, dry biomass, stem volume, merchantable
volume, merchantable biomass) now run on one model form: a hybrid Chapman Richards
growth curve with a senescence decline tail, recalibrated to the FIA longitudinal
increment and capped at the 95th percentile of observed standing stock. This
replaced the older peak decline form, which kept piling on old stand mass without an
observed ceiling and so over projected the century totals. On the reserve scenario
the change brought CONUS carbon from an implausible plus 112 percent down to plus 63
percent, which now sits in the same family as the TreeMap engine (plus 48 percent),
so the gap between the two reads as a real inventory difference rather than a model
artifact.

## Why the managed curves appeared to crash

Each managed scenario was applying an owner typical harvest rotation to every single
acre of that owner at once: clear every industrial acre on a 45 year cycle, partial
cut every family and public acre on its cycle, and so on. Marched forward that
removes roughly 1.9 percentage points of carbon per year, which flips the reserve
gain of plus 1.45 percent per year into a loss of about 0.5 percent per year.

The FIA record says the real landscape removal is tiny by comparison. Averaged across
all forest conditions, observed harvest removal is about 0.02 percent of standing
carbon per year, because in any given remeasurement only about 0.8 percent of plots
are actually cut. The dashboard was therefore modeling something close to 100 times
the real harvest intensity, which is why the managed curves dove while FIA and the
other engines (CEM, FVS, libCBM), which reflect realistic light management, kept
rising.

## The fix

Two data grounded holdouts now move land off the harvest path:

First, FIA reserved status. FIADB flags whether each plot is in reserved (legally
protected) forest. Those plots are never harvested in any scenario. The reserved
share is about 4 percent of CONUS forest but 14 to 28 percent across the West (for
example Wyoming 28 percent, California 17 percent, Idaho 15 percent, New York 14
percent), so this matters a great deal regionally.

Second, a working forest fraction. Of the non reserved land, only a fraction carries
the modeled regime and the rest tracks ordinary growth, reflecting that most non
reserved forest is not actively cut in any given decade. The effective managed
fraction is therefore (1 minus reserved share) times the working fraction.

With both holdouts in place the managed scenarios now show realistic gains and a
sensible ordering: reserve plus 63 percent, conservation plus 61 percent, business as
usual harvest plus 53 percent, intensive plus 38 percent. All gain carbon, consistent
with FIA and the other models, and the spread reflects management intensity. The only
place declines remain is in the disturbance exposed variants of each scenario, which
is correct: the real downside risk to these forests is fire, insects, and drought
mortality, not routine harvest.

## What is tunable

The working forest fractions (0.10 for harvest, 0.20 for intensive, 0.05 for
conservation) are explicit assumptions, documented in the code, and easy to change if
the team wants a heavier or lighter business as usual. A purely data exact calibration
to observed removals would push the managed curves even closer to the reserve. The
reserved share is taken straight from FIADB and is not a tuning knob.

## Caveats

Volume and merch mortality under the stress scenarios is mapped from the carbon
mortality record through a per response ratio, because the FIA growth removal file
does not carry mortality at merchantable resolution. This is adequate for the
secondary stress arms; central trajectories do not depend on it.

## Where to look

Reserve and managed scenarios, all five stock metrics, 48 states plus a CONUS
aggregate, are live at the link above (select the metric and scenario in the Engine
compare panel). Methods and decision records are in the repository under
docs/decisions (ADR 0003) and docs/results.
