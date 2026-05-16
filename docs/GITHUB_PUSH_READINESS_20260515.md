# GitHub push readiness assessment

*Generated 15 May 2026 in response to the question "should we commit to github?"*

## Recommendation: yes, push the 16 local commits now

The local repo at `~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching/` is 16 commits ahead of `origin/main`. The work covers a coherent arc with one critical course correction (the unit bug fix) that is now resolved. The current state is a reasonable landing point to share with collaborators or to make recoverable from any future workstation accident.

## What is in the 16 commits

```
da1ef1a docs: corrected WA hindcasts (-25 pct after lb fix), synthesis updated with retraction
2b4ad3f docs: HANDOFF TLDR captures the unit bug retraction up top
259b481 fix: lb/ac vs kg/ac unit bug in hindcast and validation tooling
251a998 docs: synthesis + remaining hindcast memos
206c705 validate_template: refresh STATE_PROFILES bounds + Layer 2 verified
61cc865 docs: MN RCP 4.5 hindcast result + synthesis update
076ac82 docs: refresh HANDOFF_20260513 with the validation arc
ca539bc validation arc: hindcast script, Layer 2 smoke validated, owner distributions populated, synthesis memo
4ff20fd R + scripts + docs: Layer 2 patch applied, owner col fix, three more memos, handoff refresh
86c03d7 docs: production runs COMPLETE for all 4 states x 2 RCPs (8 of 8)
574b3f2 scripts + docs: validation pipeline landed, three p1 memos, layer2 patch ready, session handoff
7541592 docs: handoff for second-half session (RCP 8.5 queued, cleanup, gr_ratio L2 audit)
32018df scripts + docs: RCP 8.5 production runs queued, gr_ratio Layer 2 audit, smoke sanity check
75a5cfd scripts + docs: production submit scripts + session handoff
bd48a2c docs: update gr_ratio bug analysis after partial fix validation
bc0a2cf fix: gr_ratio units mismatch at 06_projection_engine.R line 922
```

The commits represent four broad themes:

1. **Multistate p1 production sprint (May 8 to 10):** building the RCP 4.5 submit scripts, queueing them on Cardinal, identifying the gr_ratio Layer 2 bug, smoke sanity checking against EVALIDator. The May 10 production runs queued, producing canonical outputs for MN, WA, GA each under RCP 4.5 and RCP 8.5.

2. **Validation framework (May 11 to 13):** writing the validation R scripts (`validate_template.R`, `validate_wa_rcp45_r21.R`), running them against the six landed production runs, generating memos, applying the Layer 2 patch to `R/03_harvest_choice.R`, fixing the owner column issue.

3. **Hindcast validation (May 13 to 15):** adapting the existing ME hindcast workflow to a multistate script (`hindcast_multistate.R`), running it against the six production outputs plus the ME r21 reference.

4. **Unit bug discovery and fix (May 15):** identifying the lb/ac vs kg/ac confusion in my analysis tooling, fixing `hindcast_multistate.R` and `validate_template.R`, retracting the earlier over prediction findings, rerunning everything.

## Why this is a good push point

The hindcast tooling bug has been identified, documented, and fixed. The retraction is captured in the synthesis memo and the unit bug finding doc. Pushing now preserves the full diagnostic record including the discovery process, which is publishable methodology for the manuscript and helps future analysts avoid the same trap.

Two hindcast jobs still running on Cardinal will produce the final corrected memos in the next 30 to 45 minutes, but those will be a small follow up commit. The substantive work is already in place.

## How to push from workstation

The sandbox cannot authenticate to GitHub HTTPS. Push from your workstation:

```bash
cd ~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching
git status               # confirm clean working tree
git log origin/main..HEAD --oneline | wc -l  # should show 16 (or 17 after the next session commits)
git push origin main
```

## What to do before pushing (optional checks)

1. Verify the `MEMORY.md` file at the project root is untracked and not accidentally caught by `git add`. The local working tree shows it as untracked (`??`); good.
2. Skim `docs/HANDOFF_20260513.md` TLDR for accuracy. The unit bug retraction is captured up top.
3. If anyone else has pushed to `origin/main` since the last fetch, do a `git fetch origin && git rebase origin/main` first.

## What stays in flight after the push

- SLURM job 9602288 (hindcast v2 rerun): producing corrected hindcast memos for MN, GA, ME r21. Will land in roughly 30 to 45 minutes.
- SLURM job 9603371 (validation v3 rerun): producing refreshed validation memos for all six p1 outputs with the corrected `total_carbon_tgc` and recalibrated `STATE_PROFILES` bounds.

These produce follow up commits (one or two more) but do not change anything substantive about the work captured in the 16 commits above. The push can happen now without waiting for them.

## Optional: bundle for offline if push not feasible

If GitHub auth is unavailable temporarily, create a bundle for transport:

```bash
cd ~/Documents/Claude/CRSF-Cowork/active-projects/fia-plot-matching
git bundle create /tmp/fia-cem-maine_20260515.bundle origin/main..HEAD
```

The bundle file (probably a few MB) can be transferred and then `git pull /tmp/fia-cem-maine_20260515.bundle main` on the destination.
