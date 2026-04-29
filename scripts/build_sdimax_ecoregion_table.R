## build_sdimax_ecoregion_table.R
## Aggregate plot-specific BRMS SDImax estimates (Weiskittel et al.) by Maine
## ecoregion and FIA forest type. Produces publication-ready summary tables.
## Base R implementation (no tidyverse dependency).

base <- "/sessions/wonderful-peaceful-feynman/mnt/outputs/fia_cem_results"
plot_csv <- file.path(base, "sdimax_brms", "sdimax_brms_plot.csv")

sdf <- read.csv(plot_csv, stringsAsFactors = FALSE)
cat(sprintf("Loaded %d plot rows across %d states\n",
            nrow(sdf), length(unique(sdf$STATECD))))

## --- Maine-only subset --------------------------------------------------
me <- subset(sdf, STATECD == 23L)
cat(sprintf("Maine plots: %d\n", nrow(me)))

## --- Maine county -> ecoregion crosswalk --------------------------------
## EPA Omernik Level III approximation grouped into 4 zones used in CRSF
## reporting (Acadian Highlands, Western Mountains, Central Maine,
## Eastern/Coastal).
me_eco <- data.frame(
  COUNTYCD = c(1L, 3L, 5L, 7L, 9L, 11L, 13L, 15L,
               17L, 19L, 21L, 23L, 25L, 27L, 29L, 31L),
  county   = c("Androscoggin", "Aroostook", "Cumberland", "Franklin",
               "Hancock", "Kennebec", "Knox", "Lincoln",
               "Oxford", "Penobscot", "Piscataquis", "Sagadahoc",
               "Somerset", "Waldo", "Washington", "York"),
  ecoregion = c("Central Maine", "Acadian Highlands", "Central Maine",
                "Western Mountains", "Eastern/Coastal", "Central Maine",
                "Eastern/Coastal", "Eastern/Coastal", "Western Mountains",
                "Central Maine", "Acadian Highlands", "Central Maine",
                "Western Mountains", "Central Maine", "Eastern/Coastal",
                "Central Maine"),
  stringsAsFactors = FALSE
)

## --- FORTYPCD label crosswalk (FIA standard) ----------------------------
fortype_lookup <- data.frame(
  FORTYPCD = c(102L, 103L, 104L, 105L, 121L, 122L, 123L, 124L, 125L,
               126L, 127L, 128L, 167L, 381L, 401L, 402L, 409L,
               503L, 505L, 506L, 513L, 515L, 519L, 520L,
               701L, 703L, 704L, 708L, 801L, 802L, 805L, 809L,
               901L, 902L, 903L, 904L, 922L, 950L),
  fortype_label = c(
    "Tamarack", "Eastern white pine", "Eastern white pine / red pine",
    "Eastern white pine / eastern hemlock",
    "Balsam fir", "White spruce", "Red spruce", "Red spruce / balsam fir",
    "Black spruce", "Tamarack (eastern)", "Northern white-cedar",
    "Fraser fir", "Eastern hemlock", "Scotch pine",
    "Eastern white pine / N. red oak / wht ash",
    "Eastern redcedar / hardwood", "Other pine / hardwood",
    "White oak / red oak / hickory", "Northern red oak",
    "Yellow-poplar / white oak / N. red oak",
    "Sassafras / persimmon", "Chestnut oak", "Red maple / oak",
    "Mixed upland hardwoods",
    "Black ash / American elm / red maple", "Cottonwood", "Willow",
    "Sweetgum / Nuttall oak / willow oak",
    "Sugar maple / beech / yellow birch", "Black cherry",
    "Hard maple / basswood", "Red maple (upland)",
    "Aspen", "Paper birch", "Gray birch", "Balsam poplar",
    "Mixed northern hardwoods", "Other / nonstocked"),
  fortype_group = c(
    "Softwood", "Softwood", "Softwood", "Softwood",
    "Spruce-fir", "Spruce-fir", "Spruce-fir", "Spruce-fir",
    "Spruce-fir", "Spruce-fir", "Spruce-fir", "Spruce-fir",
    "Softwood", "Softwood",
    "Mixed", "Mixed", "Mixed",
    "Hardwood", "Hardwood", "Hardwood", "Hardwood", "Hardwood",
    "Hardwood", "Hardwood",
    "Hardwood", "Hardwood", "Hardwood", "Hardwood",
    "Northern hardwood", "Northern hardwood", "Northern hardwood",
    "Northern hardwood",
    "Aspen-birch", "Aspen-birch", "Aspen-birch", "Aspen-birch",
    "Northern hardwood", "Other"),
  stringsAsFactors = FALSE
)

## --- Merge --------------------------------------------------------------
me_full <- merge(me, me_eco, by = "COUNTYCD", all.x = TRUE)
me_full <- merge(me_full, fortype_lookup, by = "FORTYPCD", all.x = TRUE)

me_full$fortype_label[is.na(me_full$fortype_label)] <-
  paste0("FORTYPCD ", me_full$FORTYPCD[is.na(me_full$fortype_label)])
me_full$fortype_group[is.na(me_full$fortype_group)] <- "Other"
me_full$ecoregion[is.na(me_full$ecoregion)] <- "Unclassified"

## --- Summary helper -----------------------------------------------------
sdimax_summary <- function(d, by) {
  spl <- split(d, d[, by, drop = FALSE], drop = TRUE)
  rows <- lapply(seq_along(spl), function(i) {
    s <- spl[[i]]
    keys <- s[1, by, drop = FALSE]
    cbind(keys,
          n_plots         = nrow(s),
          sdimax_m_mean   = round(mean(s$sdimax_metric_mean,   na.rm = TRUE), 0),
          sdimax_m_median = round(median(s$sdimax_metric_mean, na.rm = TRUE), 0),
          sdimax_m_p10    = round(quantile(s$sdimax_metric_mean, 0.10, na.rm = TRUE, names = FALSE), 0),
          sdimax_m_p90    = round(quantile(s$sdimax_metric_mean, 0.90, na.rm = TRUE, names = FALSE), 0),
          sdimax_e_mean   = round(mean(s$sdimax_english_mean,   na.rm = TRUE), 0),
          sdimax_e_median = round(median(s$sdimax_english_mean, na.rm = TRUE), 0),
          sdimax_e_p10    = round(quantile(s$sdimax_english_mean, 0.10, na.rm = TRUE, names = FALSE), 0),
          sdimax_e_p90    = round(quantile(s$sdimax_english_mean, 0.90, na.rm = TRUE, names = FALSE), 0))
  })
  do.call(rbind, rows)
}

## (1) Ecoregion x forest type (Maine, full)
eco_ft <- sdimax_summary(me_full, c("ecoregion", "fortype_group", "fortype_label", "FORTYPCD"))
eco_ft <- eco_ft[order(eco_ft$ecoregion, eco_ft$fortype_group, -eco_ft$n_plots), ]
write.csv(eco_ft,
          file.path(base, "sdimax_brms", "sdimax_by_ecoregion_fortype_full.csv"),
          row.names = FALSE)

## (1b) Compact (n >= 5)
eco_ft_compact <- eco_ft[eco_ft$n_plots >= 5,
                         c("ecoregion", "fortype_group", "fortype_label",
                           "n_plots", "sdimax_m_mean", "sdimax_m_p10",
                           "sdimax_m_p90", "sdimax_e_mean", "sdimax_e_p10",
                           "sdimax_e_p90")]
write.csv(eco_ft_compact,
          file.path(base, "sdimax_brms", "sdimax_by_ecoregion_fortype_compact.csv"),
          row.names = FALSE)

## (2) Ecoregion only
eco <- sdimax_summary(me_full, "ecoregion")
write.csv(eco, file.path(base, "sdimax_brms", "sdimax_by_ecoregion.csv"),
          row.names = FALSE)

## (3) Forest-type group only
ft <- sdimax_summary(me_full, "fortype_group")
write.csv(ft, file.path(base, "sdimax_brms", "sdimax_by_fortype_group_maine.csv"),
          row.names = FALSE)

## (4) FORTYPCD detail (Maine)
ft_detail <- sdimax_summary(me_full, c("fortype_group", "fortype_label", "FORTYPCD"))
ft_detail <- ft_detail[order(ft_detail$fortype_group, -ft_detail$n_plots), ]
write.csv(ft_detail,
          file.path(base, "sdimax_brms", "sdimax_by_fortype_detail_maine.csv"),
          row.names = FALSE)

cat("\n=== Ecoregion summary (Maine, trees ha-1 metric, trees ac-1 english) ===\n")
print(eco, row.names = FALSE)

cat("\n=== Forest-type group summary (Maine) ===\n")
print(ft, row.names = FALSE)

cat(sprintf("\n=== Top 20 ecoregion x forest-type cells (n_plots >= 5; %d total) ===\n",
            nrow(eco_ft_compact)))
top <- eco_ft_compact[order(-eco_ft_compact$n_plots), ][1:min(20, nrow(eco_ft_compact)), ]
print(top, row.names = FALSE)

cat("\nFiles written to", file.path(base, "sdimax_brms"), "\n")
