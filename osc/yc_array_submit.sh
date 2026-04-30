#!/bin/bash
#SBATCH --job-name=yc_array
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=2 --mem=8G
#SBATCH --array=1-140%32
#SBATCH --output=/users/PUOM0008/crsfaaron/yield_curves/logs/yc_%A_%a.out
#SBATCH --error=/users/PUOM0008/crsfaaron/yield_curves/logs/yc_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

YC_DIR=${HOME}/yield_curves
mkdir -p ${YC_DIR}/logs

INDEX=${YC_DIR}/runs/yc_run_index.csv

LINE=$(awk -F, -v aid=$SLURM_ARRAY_TASK_ID 'NR>1 && $1==aid {print; exit}' "$INDEX")
if [ -z "$LINE" ]; then
  echo "No row for array_id=$SLURM_ARRAY_TASK_ID in $INDEX"
  exit 1
fi

RUNDIR=$(echo "$LINE"  | awk -F, '{print $2}' | tr -d '"')
CELLKEY=$(echo "$LINE" | awk -F, '{print $3}' | tr -d '"')
TREATMENT=$(echo "$LINE" | awk -F, '{print $4}' | tr -d '"')
VARIANT=$(echo "$LINE" | awk -F, '{print $5}' | tr -d '"')

echo "Array task: $SLURM_ARRAY_TASK_ID  cell: $CELLKEY  treatment: $TREATMENT  variant: $VARIANT"
echo "Run dir   : $RUNDIR"

cd "$RUNDIR" || exit 1

if [ "$VARIANT" == "acd" ]; then
  FVS_BIN=${HOME}/fvs-modern/lib/FVSacd
else
  FVS_BIN=${HOME}/fvs-modern/lib/FVSne
fi

# FVS-modern wants 6 file names interactively, in order:
#   keyword, tree-data, main-out, treelist, summary, cheap/calbstat
cat > answers.txt <<EOF
fvs_run.key
fvs_run.tre
fvs_run.out
fvs_run.trl
fvs_run.sum
fvs_run.cal
EOF

ulimit -s unlimited
"$FVS_BIN" < answers.txt 2>&1 | tail -20

echo "FVS exit: $?"
ls -la fvs_run.* 2>/dev/null | head
