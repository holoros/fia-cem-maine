#!/usr/bin/env Rscript
# multistate_sat_age_comparison.R
# Cross state comparison of stand age distribution + sat_age outcome for the
# four multistate p1 states. Establishes that GA's young plantation cohort
# is unique among the four and that the sat_age mechanism uniquely affects
# GA.
#
# Run on Cardinal. Inputs: ~/fia_data/<STATE>_COND.csv.
# Outputs:
#   multistate_sat_age_summary.csv
#   multistate_sat_age_distribution.png

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

FIA_DIR <- "/users/PUOM0008/crsfaaron/fia_data"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/multistate_sat_age_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Per state terminal_age and growth_start_age from state_constants.csv
STATE_PARAMS <- list(
  GA = list(terminal_age = 80,  growth_start_age = 60),
  ME = list(terminal_age = 120, growth_start_age = 60),
  WA = list(terminal_age = 200, growth_start_age = 60),
  MN = list(terminal_age = 110, growth_start_age = 60)
)

read_cond <- function(state) {
  fp <- file.path(FIA_DIR, paste0(state, "_COND.csv"))
  if (!file.exists(fp)) return(NULL)
  hdr <- names(data.table::fread(fp, nrows = 0, showProgress = FALSE))
  cols <- intersect(c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
                       "STDAGE", "CONDPROP_UNADJ"), hdr)
  dt <- data.table::fread(fp, select = cols, showProgress = FALSE)
  if (!"CONDPROP_UNADJ" %in% names(dt)) dt[, CONDPROP_UNADJ := 1.0]
  dt[, state := state]
  dt
}

sat_for_age <- function(age, terminal_age, growth_start_age) {
  age <- pmin(pmax(ifelse(is.na(age), 0, age), 0), terminal_age)
  pmax(0, pmin(1, (terminal_age - age) / (terminal_age - growth_start_age)))
}

cat("Reading COND files...\n")
all <- list()
for (st in names(STATE_PARAMS)) {
  d <- read_cond(st)
  if (is.null(d)) next
  d <- d[COND_STATUS_CD == 1 & INVYR %in% 1999:2008 &
          !is.na(FORTYPCD) & FORTYPCD > 0 &
          !is.na(STDAGE) & STDAGE > 0]
  cat(sprintf("  %s: %d forested baseline conds\n", st, nrow(d)))
  ta <- STATE_PARAMS[[st]]$terminal_age
  ga <- STATE_PARAMS[[st]]$growth_start_age
  d[, sat_age := sat_for_age(STDAGE, ta, ga)]
  d[, terminal_age := ta]
  all[[st]] <- d
}
all_dt <- data.table::rbindlist(all, fill = TRUE)

# Per state summary
state_summary <- all_dt[, .(
  n_cond           = .N,
  median_age       = median(STDAGE),
  mean_age         = round(mean(STDAGE), 1),
  pct_age_lt_30    = round(mean(STDAGE < 30), 3),
  pct_age_lt_60    = round(mean(STDAGE < 60), 3),
  pct_sat_full_1   = round(mean(sat_age == 1.0), 3),
  mean_sat_age     = round(mean(sat_age), 3),
  terminal_age     = unique(terminal_age)
), by = state][order(state)]

fwrite(state_summary, file.path(OUT_DIR, "multistate_sat_age_summary.csv"))

cat("\nPer state summary:\n")
print(state_summary)

# Plot: 4 panel age distribution with sat_age zones
state_levels <- state_summary[order(median_age)]$state
all_dt[, state := factor(state, levels = state_levels)]

p <- ggplot(all_dt, aes(x = STDAGE)) +
  geom_histogram(binwidth = 5, fill = "#3a78a3", alpha = 0.8) +
  geom_vline(xintercept = 60, linetype = "dashed", color = "grey40") +
  facet_wrap(~ state, scales = "free_y", ncol = 2) +
  labs(
    title    = "Cross state stand age distribution (baseline 1999-2008 forested conds)",
    subtitle = "Vertical dashed line at growth_start_age = 60. Stands left of line have sat_age = 1.0 (unconstrained growth).",
    x = "STDAGE (years)", y = "Count of conditions"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title       = element_text(face = "bold"),
        strip.background = element_rect(fill = "#f0f0f0", color = NA),
        strip.text       = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "multistate_sat_age_distribution.png"),
       plot = p, width = 10, height = 6, dpi = 150, bg = "white")

# Bar plot of pct_sat_full_1 by state
p2 <- ggplot(state_summary, aes(x = reorder(state, -pct_sat_full_1),
                                 y = pct_sat_full_1)) +
  geom_col(fill = "#c08020", alpha = 0.85) +
  geom_text(aes(label = scales::percent(pct_sat_full_1, accuracy = 0.1)),
            vjust = -0.4, size = 4) +
  geom_text(aes(label = paste0("median age = ", median_age),
                 y = 0.02), vjust = 0, size = 3.5, color = "white") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                      limits = c(0, 1.05), expand = c(0, 0)) +
  labs(
    title    = "Share of forested conditions with sat_age = 1.0 (unconstrained growth)",
    subtitle = "Higher share = more conditions escape age-class growth attenuation",
    x = NULL, y = "% conds with sat_age = 1.0"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "multistate_sat_age_share.png"),
       plot = p2, width = 8, height = 5, dpi = 150, bg = "white")

cat("\nOutputs at:", OUT_DIR, "\n")
