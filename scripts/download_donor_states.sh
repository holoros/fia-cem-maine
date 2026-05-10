#!/bin/bash
# =============================================================================
# download_donor_states.sh
#
# Login-node serial driver for osc/00_download_data.R covering the three
# multistate cohorts (MN, WA, GA). Routes writes to ~/FIA (scratch, no
# quota impact) via OSC_PROJECT_DIR. Logs each cohort separately so
# partial completion is recoverable.
#
# Usage on Cardinal login node:
#   nohup bash scripts/download_donor_states.sh > /dev/null 2>&1 &
#   tail -f ~/FIA/download_logs/cohort_*.log
#
# Estimated time per cohort: 30 to 90 minutes (depends on FIA Datamart
# response time and donor count). Total: ~3 hours wall-clock.
# =============================================================================

set -e

LOG_DIR=${HOME}/FIA/download_logs
mkdir -p "$LOG_DIR"

cd ${HOME}/fia_cem_projections

# Modules and library path. rFIA pulls in sf -> needs proj/gdal/geos.
module load gcc/12.3.0 R/4.4.0 proj/9.2.1 gdal/3.7.3 geos/3.12.0 2>/dev/null
export R_LIBS="${HOME}/R/cardinal_libs/4.4.0:${HOME}/R/cardinal_libs:${HOME}/R/x86_64-pc-linux-gnu-library/4.4"
unset R_LIBS_USER

# Route output to scratch (~/FIA) so we don't burn /users quota
export OSC_PROJECT_DIR=${HOME}/FIA

echo "============================================" | tee -a "$LOG_DIR/master.log"
echo "  Donor state download driver" | tee -a "$LOG_DIR/master.log"
echo "  Started: $(date)" | tee -a "$LOG_DIR/master.log"
echo "  OSC_PROJECT_DIR: $OSC_PROJECT_DIR" | tee -a "$LOG_DIR/master.log"
echo "  Quota at start: $(quota -s 2>/dev/null | tail -1 | awk '{print $1, $2}')" | tee -a "$LOG_DIR/master.log"
echo "============================================" | tee -a "$LOG_DIR/master.log"

for state in MN WA GA; do
  log="$LOG_DIR/cohort_${state}.log"
  echo | tee -a "$LOG_DIR/master.log"
  echo "--- $state cohort ---" | tee -a "$LOG_DIR/master.log"
  echo "  Started: $(date)" | tee -a "$LOG_DIR/master.log"
  echo "  Log: $log" | tee -a "$LOG_DIR/master.log"

  # Run the existing 00_download_data.R; it expands the donor pool internally.
  # Set options(timeout = 3600) up front because the default 60 s download.file
  # timeout fails on the 174+ MB TREE.zip files on Cardinal's outbound link.
  Rscript -e 'options(timeout = 3600); commandArgs <- function(trailingOnly = TRUE) c("'"$state"'"); source("osc/00_download_data.R")' > "$log" 2>&1
  rc=$?

  echo "  Finished: $(date), exit code $rc" | tee -a "$LOG_DIR/master.log"
  if [ $rc -ne 0 ]; then
    echo "  FAILED. See $log for details." | tee -a "$LOG_DIR/master.log"
    echo "  Continuing to next cohort." | tee -a "$LOG_DIR/master.log"
  fi
done

echo | tee -a "$LOG_DIR/master.log"
echo "============================================" | tee -a "$LOG_DIR/master.log"
echo "  Donor state download driver done" | tee -a "$LOG_DIR/master.log"
echo "  Finished: $(date)" | tee -a "$LOG_DIR/master.log"
echo "  Quota at end: $(quota -s 2>/dev/null | tail -1 | awk '{print $1, $2}')" | tee -a "$LOG_DIR/master.log"
echo "  Files now in OSC_PROJECT_DIR:" | tee -a "$LOG_DIR/master.log"
ls -lh ${OSC_PROJECT_DIR}/fia_db_*.rds 2>/dev/null | tee -a "$LOG_DIR/master.log"
echo "============================================" | tee -a "$LOG_DIR/master.log"
