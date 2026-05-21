## build_fia_db_WA_addCA.R
## Take the validated baseline fia_db_WA.rds (states ID/OR/WA) and append
## California per-state CSV rows (PLOT/COND/TREE) to create a western donor
## pool that includes CA. Preserves baseline donors exactly; isolates the
## effect of adding the one western state with complete data that the
## original CONUS run silently failed to load.
suppressPackageStartupMessages(library(data.table))
DATA_DIR <- file.path(Sys.getenv("HOME"), "fia_data")
base_path <- file.path(DATA_DIR, "fia_db_WA.rds")
cat("Reading baseline db:", base_path, "\n")
db <- readRDS(base_path)
cat("Baseline tables:", paste(names(db), collapse=", "), "\n")
add_states <- c("CA")
tables_ext <- c("PLOT","COND","TREE")
for (tbl in tables_ext) {
  if (is.null(db[[tbl]])) { cat("  base missing table", tbl, "- skip\n"); next }
  base_dt <- as.data.table(db[[tbl]])
  base_cols <- names(base_dt)
  for (st in add_states) {
    f <- file.path(DATA_DIR, sprintf("%s_%s.csv", st, tbl))
    if (!file.exists(f)) { cat("  MISSING", f, "\n"); next }
    add_dt <- fread(f, showProgress=FALSE)
    common <- intersect(base_cols, names(add_dt))
    add_dt <- add_dt[, ..common]
    for (m in setdiff(base_cols, common)) add_dt[[m]] <- NA
    setcolorder(add_dt, base_cols)
    for (cc in base_cols) {
      bc <- class(base_dt[[cc]])[1]
      if (bc=="integer") suppressWarnings(set(add_dt, j=cc, value=as.integer(add_dt[[cc]])))
      else if (bc=="numeric") suppressWarnings(set(add_dt, j=cc, value=as.numeric(add_dt[[cc]])))
      else if (bc=="character") set(add_dt, j=cc, value=as.character(add_dt[[cc]]))
    }
    base_dt <- rbindlist(list(base_dt, add_dt), use.names=TRUE, fill=TRUE)
    cat(sprintf("  %s: +%d rows from %s\n", tbl, nrow(add_dt), st))
  }
  db[[tbl]] <- base_dt
}
out <- file.path(DATA_DIR, "fia_db_WA_addCA.rds")
saveRDS(db, out)
cat("Wrote", out, "\n")
for (t in intersect(c("PLOT","COND","TREE","TREE_GRM_COMPONENT"), names(db))) {
  s <- sort(unique(db[[t]]$STATECD))
  cat(sprintf("  %s STATECD: %s | nrow=%d\n", t, paste(s,collapse=","), nrow(db[[t]])))
}
