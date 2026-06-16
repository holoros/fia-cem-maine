#!/usr/bin/env Rscript
# Decomposition for the TPA-saturation fix verify run. Auto-finds the newest
# ME_*tpasat_verify* output dir, computes per-cycle area/density/TPA, and prints
# a success verdict against the broken-run baseline.
suppressWarnings(suppressMessages({ library(dplyr); library(readr) }))

base <- path.expand("~/fia_cem_projections/output")
cands <- list.dirs(base, recursive = FALSE)
cands <- cands[grepl("tpasat_verify", basename(cands))]
stopifnot(length(cands) >= 1)
run_dir <- cands[order(file.info(cands)$mtime, decreasing = TRUE)][1]
cat("Using run dir:", run_dir, "\n")

x <- readRDS(file.path(run_dir, "per_plot_projections.rds"))
x1 <- x %>% filter(sim == min(sim)); x1$uid <- paste(x1$PLT_CN, x1$CONDID)

dec <- x1 %>% group_by(scenario, cycle) %>%
  summarise(n_uid=n_distinct(uid), area_cprop=sum(CONDPROP_UNADJ,na.rm=TRUE),
            carbon_mean=mean(proj_carbon,na.rm=TRUE), ba_mean=mean(proj_BA,na.rm=TRUE),
            tpa_mean=mean(proj_tpa,na.rm=TRUE), qmd_mean=mean(proj_qmd,na.rm=TRUE),
            .groups="drop") %>% arrange(scenario, cycle)
write_csv(dec, file.path(run_dir, "tpasat_decomp_area_density.csv"))

pc <- function(a,b) sprintf("%+.0f%%", 100*(b-a)/a)
for (sc in unique(dec$scenario)) {
  ss <- dec %>% filter(scenario==sc)
  cat("\n== ", sc, " ==\n")
  print(as.data.frame(ss %>% filter(cycle %in% c(1,5,9,15)) %>%
    select(cycle,n_uid,area_cprop,carbon_mean,ba_mean,tpa_mean,qmd_mean)),
    row.names=FALSE, digits=4)
  a<-ss%>%filter(cycle==min(cycle)); z<-ss%>%filter(cycle==max(cycle))
  cat(sprintf("   cyc1->15: carbon %s | BA %s | tpa %s | qmd %s\n",
    pc(a$carbon_mean,z$carbon_mean), pc(a$ba_mean,z$ba_mean),
    pc(a$tpa_mean,z$tpa_mean), pc(a$qmd_mean,z$qmd_mean)))
}

cat("\n=== Verdict (BAU + No_harvest) ===\n")
for (sc in c("BAU","No_harvest")) {
  z <- dec %>% filter(scenario==sc, cycle==max(cycle))
  if (nrow(z)==0) next
  ba_impl <- z$tpa_mean * 0.005454 * z$qmd_mean^2
  ratio <- ba_impl / z$ba_mean
  tpa_ok <- z$tpa_mean < 3000
  coh_ok <- ratio > 0.7 & ratio < 1.4
  cat(sprintf("%-11s cyc15: tpa=%.0f (%s)  BA_reported=%.1f BA_implied=%.1f ratio=%.2f (%s)\n",
      sc, z$tpa_mean, ifelse(tpa_ok,"PLAUSIBLE","STILL RUNAWAY"),
      z$ba_mean, ba_impl, ratio, ifelse(coh_ok,"COHERENT","DECOUPLED")))
}
cat("\nBroken baseline for comparison: BAU cyc15 tpa=9773 BA=44.1 implied=6990 ratio=159x;",
    "No_harvest cyc15 tpa=20997.\n")
cat("Done.\n")
