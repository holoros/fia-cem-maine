#!/usr/bin/env Rscript
# ============================================================================
# ingest_cem_state.R   (state-general CEM adapter)
#
# Generalizes ingest_cem_rcp_scenarios.R from Maine-only to any state. Ingests
# one state-aggregated CEM CI file (the output of 10_state_expansion.R /
# run_state_expansion_all.R, i.e. state_<tag>_ci.csv with the mmt_* carbon-pool
# columns and a `year` column) as a cls="CEM" engine for the target state.
#
# NOTE on input contract: this consumes the STATE-EXPANDED CI (columns
# scenario, cycle, year, mmt_agc_mean/lo/hi, mmt_bgc_*, ... , merch_vol_mcf_*,
# rd_*, sdi_*). The per-run output/<STATE>_<date>_<tag>/ci_summaries.csv is
# per-acre and is NOT a valid input; run state expansion first.
#
# Usage:
#   Rscript ingest_cem_state.R <project_root> \
#     --state WA --csv /path/state_rcp45_wear_prodW_l7b_ci.csv \
#     --model cem_wear_prodW_rcp45 --climate rcp45_hadgem3 \
#     [--version cem_state_v1] [--species fia_current_WA] [--db <db_path>]
#
# Maine behavior is preserved by the original adapter; this script is additive
# and never touches the ME-specific path. It is idempotent per
# (state, model, scenario, year) via a delete-then-insert on the version key.
# ============================================================================

suppressPackageStartupMessages({
  library(DBI); library(RSQLite); library(dplyr); library(readr); library(tibble); library(stringr)
})

# ---- arg parsing -----------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1 && !startsWith(args[[1]], "--")) args[[1]] else normalizePath(".")
getarg <- function(flag, default = NA_character_) {
  i <- which(args == flag)
  if (length(i) == 0 || i[1] == length(args)) return(default)
  args[[i[1] + 1]]
}
state    <- toupper(getarg("--state", "ME"))
csv_path <- path.expand(getarg("--csv"))
model    <- getarg("--model")
climate  <- getarg("--climate", "rcp45_hadgem3")
version  <- getarg("--version", "cem_state_v1")
species  <- getarg("--species", sprintf("fia_current_%s", state))
db_path  <- getarg("--db", file.path(project_root, "db", "perseus_results.sqlite"))

stopifnot("missing --csv"   = !is.na(csv_path),
          "missing --model" = !is.na(model),
          "csv not found"   = file.exists(csv_path),
          "db not found"    = file.exists(db_path))
cat(sprintf("[cem_state] state=%s model=%s climate=%s version=%s\n            csv=%s\n            db=%s\n",
            state, model, climate, version, csv_path, db_path))

# ---- column families (state-aggregated mmt_* pools) ------------------------
col_families <- list(
  agc_live_total    = c(median = "mmt_agc_mean",       lo = "mmt_agc_lo",       hi = "mmt_agc_hi"),
  bgc_live_total    = c(median = "mmt_bgc_mean",       lo = "mmt_bgc_lo",       hi = "mmt_bgc_hi"),
  dead_wood_c       = c(median = "mmt_dead_c_mean",    lo = "mmt_dead_c_lo",    hi = "mmt_dead_c_hi"),
  litter_c          = c(median = "mmt_litter_c_mean",  lo = "mmt_litter_c_lo",  hi = "mmt_litter_c_hi"),
  soil_c            = c(median = "mmt_soil_c_mean",    lo = "mmt_soil_c_lo",    hi = "mmt_soil_c_hi"),
  understory_c      = c(median = "mmt_under_c_mean",   lo = "mmt_under_c_lo",   hi = "mmt_under_c_hi"),
  total_ecosystem_c = c(median = "mmt_total_c_mean",   lo = "mmt_total_c_lo",   hi = "mmt_total_c_hi"),
  agb_dry           = c(median = "mmt_biomass_mean",   lo = "mmt_biomass_lo",   hi = "mmt_biomass_hi"),
  vol_stem          = c(median = "total_vol_mcf_mean", lo = "total_vol_mcf_lo", hi = "total_vol_mcf_hi"),
  merch_vol_mcf     = c(median = "merch_vol_mcf_mean", lo = "merch_vol_mcf_lo", hi = "merch_vol_mcf_hi"),
  rd_mean_wtd       = c(median = "rd_mean_wtd_mean",   lo = "rd_mean_wtd_lo",   hi = "rd_mean_wtd_hi"),
  sdi_mean_wtd      = c(median = "sdi_mean_wtd_mean",  lo = "sdi_mean_wtd_lo",  hi = "sdi_mean_wtd_hi")
)

df <- readr::read_csv(csv_path, show_col_types = FALSE)
if (!all(c("scenario", "year") %in% names(df)) || !("mmt_agc_mean" %in% names(df))) {
  stop("input lacks state-expanded columns (need scenario, year, mmt_agc_mean ...). ",
       "Run 10_state_expansion.R / run_state_expansion_all.R first; the per-run ",
       "ci_summaries.csv is per-acre and not a valid input.")
}
cat(sprintf("[cem_state] rows=%d scenarios=%s years=%d..%d\n",
            nrow(df), paste(unique(df$scenario), collapse = ","),
            min(df$year), max(df$year)))

# ---- metric + harvest-rule registration (same as ME adapter) ---------------
metric_defs <- tibble::tibble(
  metric_code = c("bgc_live_total","dead_wood_c","litter_c","soil_c","understory_c","total_ecosystem_c"),
  label = c("Below-ground live carbon (BGC)","Dead wood carbon (standing + downed)","Litter carbon",
            "Soil organic carbon","Understory carbon","Total ecosystem carbon (all pools)"),
  kind = "stock", canonical_unit = "Tg C", metric_group = "carbon")

con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
on.exit(DBI::dbDisconnect(con))
DBI::dbExecute(con, "PRAGMA foreign_keys = ON;")

for (i in seq_len(nrow(metric_defs))) {
  DBI::dbExecute(con,
    "INSERT OR IGNORE INTO metric (metric_code, label, kind, canonical_unit, metric_group) VALUES (?,?,?,?,?)",
    params = unname(as.list(metric_defs[i, ])))
}
# Each scenario gets its own harvest_rule_id. The result_v02 UNIQUE key uses
# harvest_rule_id (not scenario_preset_id) to separate rows, so distinct
# scenarios must map to distinct rules or they collide.
scenario_to_harvest <- function(scen) paste0("cem_", gsub("[^a-z0-9]+", "_", tolower(scen)))
for (scen in unique(df$scenario)) {
  DBI::dbExecute(con, "INSERT OR IGNORE INTO harvest_rule (harvest_rule_id,label) VALUES (?,?)",
                 params = list(scenario_to_harvest(scen), sprintf("CEM scenario: %s", scen)))
}

NOW <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
git_commit <- tryCatch(system2("git", c("-C", project_root, "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE)[1],
                       error = function(e) "no-git")

# ---- model + scenario_preset registration ---------------------------------
DBI::dbExecute(con,
  "INSERT OR IGNORE INTO model (model_code,label,model_class,native_unit,agb_to_agc_factor,notes)
   VALUES (?,?,'CEM','Mt C / Mt biomass / Mcf',1.0,
           'CEM (Carbon Empirical Model) state-aggregated trajectory with bootstrap CIs.')",
  params = list(model, sprintf("CEM %s %s aggregate", model, state)))

for (scen in unique(df$scenario)) {
  sp_id <- sprintf("%s_%s_%s", model, scen, state)
  DBI::dbExecute(con,
    "INSERT OR IGNORE INTO scenario_preset
       (scenario_id,state_code,harvest_rule_id,climate_id,species_id,horizon_year,description,is_curated)
     VALUES (?,?,?,?,?,?,?,1)",
    params = list(sp_id, state, scenario_to_harvest(scen), climate, species,
                  as.integer(max(df$year)), sprintf("CEM %s scenario preset", state)))
}

# ---- write results ---------------------------------------------------------
plaus_cap <- c(rd_mean_wtd = 2.0, sdi_mean_wtd = 1500)
DBI::dbBegin(con); n_ins <- 0L
for (r in seq_len(nrow(df))) {
  scen <- df$scenario[r]; sp_id <- sprintf("%s_%s_%s", model, scen, state)
  harvest_id <- scenario_to_harvest(scen); yr <- as.integer(df$year[r])
  DBI::dbExecute(con,
    "DELETE FROM result_v02 WHERE state_code=? AND model_code=? AND scenario_preset_id=? AND year=? AND version=?",
    params = list(state, model, sp_id, yr, version))
  for (mc in names(col_families)) {
    stats <- col_families[[mc]]
    if (!all(unname(stats) %in% names(df))) next
    for (stat in names(stats)) {
      val <- df[[stats[[stat]]]][r]; if (is.na(val)) next
      is_cur <- 1L; note_val <- NA_character_
      if (mc %in% names(plaus_cap) && is.finite(val) && val > plaus_cap[[mc]]) {
        is_cur <- 0L
        note_val <- sprintf("quarantined: %s exceeds physical bound %g", mc, plaus_cap[[mc]])
      }
      DBI::dbExecute(con,
        "INSERT INTO result_v02
           (state_code,scenario_preset_id,harvest_rule_id,climate_id,species_id,
            metric_code,model_code,year,statistic,value,state_expansion,version,is_current,notes,ingested_at)
         VALUES (?,?,?,?,?,?,?,?,?,?,'fia_expns',?,?,?,?)",
        params = list(state, sp_id, harvest_id, climate, species, mc, model, yr, stat, val,
                      version, is_cur, note_val, NOW))
      n_ins <- n_ins + 1L
    }
  }
}
DBI::dbCommit(con)
DBI::dbExecute(con,
  "INSERT INTO ingest_log (adapter,version,state_code,model_codes,source_files,rows_ingested,
                           started_at,finished_at,git_commit,operator,status,message)
   VALUES ('ingest_cem_state',?,?,?,?,?,?,?,?,'autopilot','ok','State-general CEM ingest.')",
  params = list(version, state, model, csv_path, n_ins, NOW, NOW, git_commit))

cat(sprintf("[cem_state] DONE. Inserted %d rows for %s / %s.\n", n_ins, state, model))
print(DBI::dbGetQuery(con, sprintf(
  "SELECT state_code, model_code, COUNT(*) rows, COUNT(DISTINCT scenario_preset_id) scenarios,
          COUNT(DISTINCT metric_code) metrics, MIN(year) y0, MAX(year) y1
   FROM result_v02 WHERE state_code='%s' AND model_code='%s' GROUP BY 1,2", state, model)))
