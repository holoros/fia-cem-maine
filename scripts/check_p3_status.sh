#!/bin/bash
## check_p3_status.sh
## Quick status probe for the p2 to p3 production pipeline.
## Reports queue state, latest cycle reached per p2 job, and any p3 jobs that
## have moved out of pending. Run from any session as:
##   bash scripts/check_p3_status.sh
## or remotely:
##   ssh cardinal "bash ~/fia_cem_projections/scripts/check_p3_status.sh"

set -u

P2_IDS=(9936857 9936858 9936859 9936860 9936861 9936862)
P3_IDS=(9939142 9939143 9939144 9939145 9939146 9939147)

LOGDIR="${HOME}/fia_cem_projections/logs"
OUTDIR="${HOME}/fia_cem_projections/output"

echo "=========================================="
echo "  p2/p3 pipeline status  $(date)"
echo "=========================================="

echo ""
echo "Queue state:"
squeue -u crsfaaron -o "%i %j %T %M %r" 2>/dev/null \
  | awk 'NR==1 || /p2|p3/' \
  | sort -k1

echo ""
echo "p2 last activity (file mtime + cycle line):"
for j in "${P2_IDS[@]}"; do
  f=$(ls "${LOGDIR}"/*_${j}.out 2>/dev/null | head -1)
  if [ -z "$f" ]; then continue; fi
  name=$(basename "$f" .out)
  mtime=$(stat -c %y "$f" 2>/dev/null | cut -c-19)
  cycle=$(grep -E 'Climate RCP' "$f" 2>/dev/null | tail -1 \
          | grep -oE 'cycle [0-9]+' | head -1)
  echo "  $name  mtime=$mtime  $cycle"
done

echo ""
echo "p3 dependency state:"
for j in "${P3_IDS[@]}"; do
  dep=$(squeue -j "$j" -h -o "%E" 2>/dev/null)
  state=$(squeue -j "$j" -h -o "%T" 2>/dev/null)
  echo "  $j  $state  $dep"
done

echo ""
echo "Completed p2 (today):"
sacct -u crsfaaron --starttime=$(date +%Y-%m-%d) \
  --format=JobID,JobName%25,State,Elapsed -X 2>/dev/null \
  | awk '/_p2/ && /COMPLETED/' | head -10

echo ""
echo "Output dirs touched today:"
ls -lt "${OUTDIR}/" 2>/dev/null | awk 'NR>1 && /_(p2|p3)$/ && $7=="May" {print "  ", $0}' | head -10

echo ""
echo "Done."
