## ycx_treemap_project.R
##
## CONUS-wide 100-year NO-HARVEST growth, applying the finalized peak-decline
## yield curves to TreeMap 2022 (USFS RDS-2025-0032). TreeMap imputes an FIA plot (PLT_CN) to every
## 30 m forested pixel; the raster's value attribute table (VAT) gives, per
## imputation (TM_ID), the pixel Count (-> area) and PLT_CN. We join PLT_CN to
## the engine's plot membership (stand age, forest-type group, ecoregion,
## owner, state), look up that cell's carbon curve, and grow each imputed
## plot's area forward 0..100 yr (reserve / no harvest).
##
## Output: <out>/treemap/conus_noharvest_100yr.csv  (state, year_offset, agc_Tg, area_Mha)
##         <out>/treemap/conus_state_change.csv      (state, agc_t0, agc_t100, pct)
##         <out>/figures/treemap_conus_100yr.png

suppressMessages({ library(foreign); library(terra) })
out <- if (length(commandArgs(TRUE))>=1) commandArgs(TRUE)[1] else
       file.path(Sys.getenv("HOME"), "yield_curves_conus")
cfg <- file.path(out, "config"); td <- file.path(out, "treemap")
figd<- file.path(out, "figures"); dir.create(td, showWarnings=FALSE, recursive=TRUE)
## TreeMap 2022 CONUS (USFS RDS-2025-0032); arg 2 overrides the VAT path.
VAT <- if (length(commandArgs(TRUE))>=2) commandArgs(TRUE)[2] else
  "/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2022/TreeMap2022_CONUS.tif.vat.dbf"
TM_BASE <- 2022
LBAC_TO_MGHA <- 0.00045359237 * 2.4710538   # AG carbon lb/ac -> Mg C/ha
PIX_HA <- 0.09                               # 30x30 m = 900 m2 = 0.09 ha
FIPS2ABBR <- c("1"="AL","4"="AZ","5"="AR","6"="CA","8"="CO","9"="CT","10"="DE",
  "12"="FL","13"="GA","16"="ID","17"="IL","18"="IN","19"="IA","20"="KS","21"="KY",
  "22"="LA","23"="ME","24"="MD","25"="MA","26"="MI","27"="MN","28"="MS","29"="MO",
  "30"="MT","31"="NE","32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC",
  "38"="ND","39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV","55"="WI","56"="WY")

## ---- VAT (one row per imputation) ----
v <- read.dbf(VAT, as.is=TRUE)
names(v) <- toupper(names(v))
v <- v[, intersect(c("TM_ID","PLT_CN","COUNT","FORTYPCD"), names(v))]
v$PLT_CN <- format(v$PLT_CN, scientific=FALSE, trim=TRUE)
v$PLT_CN <- sub("\\.0+$","",v$PLT_CN)
cat(sprintf("[tm] VAT imputations: %d  | total pixels: %.3g\n", nrow(v), sum(v$COUNT)))

## ---- plot membership (PLT_CN -> strata + age + state) ----
mf <- list.files(cfg, pattern="^ycx_membership_.*\\.csv$", full.names=TRUE)
mem <- do.call(rbind, lapply(mf, function(f){
  d <- read.csv(f, colClasses="character")
  d[, c("PLT_CN","STATECD","ft_group","prov_code","owner4","STDAGE")]
}))
mem <- mem[!duplicated(mem$PLT_CN), ]
mem$STDAGE <- suppressWarnings(as.numeric(mem$STDAGE))
key <- match(v$PLT_CN, mem$PLT_CN)
cat(sprintf("[tm] PLT_CN matched to membership: %d / %d (%.1f%%)\n",
            sum(!is.na(key)), nrow(v), 100*mean(!is.na(key))))
v <- v[!is.na(key), ]; mm <- mem[key[!is.na(key)], ]
v <- cbind(v, mm[, c("STATECD","ft_group","prov_code","owner4","STDAGE")])
v <- v[is.finite(v$STDAGE) & v$STDAGE>0, ]
v$abbr <- FIPS2ABBR[as.character(as.integer(v$STATECD))]
v$cell <- paste(v$ft_group, v$prov_code, v$owner4, sep="|")
v$area_ha <- v$COUNT * PIX_HA

## ---- load carbon curves (b1,b2,b3) per state, cell + state fallback ----
chap <- function(age,a,b,c) a * pmax(age,1e-6)^b * c^age
L <- list()
for (st in unique(v$abbr)) {
  fp <- file.path(out, sprintf("ycx_%s_fits.csv", st)); if(!file.exists(fp)) next
  f <- read.csv(fp, stringsAsFactors=FALSE)
  f <- f[f$response=="carbon_lbac", ]
  for (i in seq_len(nrow(f))) {
    r <- f[i,]; id <- if (r$scope=="state") paste0(st,"@@state") else paste0(st,"@@",r$cell_key)
    if (is.null(L[[id]])) L[[id]] <- c(r$a, r$b, r$c)
  }
}
getc <- function(st, cell) {
  k <- L[[paste0(st,"@@",cell)]]; if (!is.null(k)) return(k)
  L[[paste0(st,"@@state")]]
}

## ---- project 0..100 yr, no harvest ----
offs <- seq(0, 100, 10)
res <- matrix(0, nrow=length(unique(v$abbr)), ncol=length(offs),
              dimnames=list(sort(unique(v$abbr)), paste0("yr", offs)))
area_state <- setNames(numeric(length(unique(v$abbr))), sort(unique(v$abbr)))
n_nocurve <- 0
for (i in seq_len(nrow(v))) {
  abc <- getc(v$abbr[i], v$cell[i]); if (is.null(abc)) { n_nocurve<-n_nocurve+1; next }
  dens <- chap(v$STDAGE[i] + offs, abc[1], abc[2], abc[3]) * LBAC_TO_MGHA  # Mg C/ha
  dens[!is.finite(dens) | dens<0] <- 0
  tg <- dens * v$area_ha[i] / 1e6                                          # Tg C
  res[v$abbr[i], ] <- res[v$abbr[i], ] + tg
  area_state[v$abbr[i]] <- area_state[v$abbr[i]] + v$area_ha[i]
}
cat(sprintf("[tm] imputations projected: %d (no curve: %d)\n", nrow(v)-n_nocurve, n_nocurve))

## ---- write outputs ----
long <- do.call(rbind, lapply(rownames(res), function(st)
  data.frame(state=st, year_offset=offs, agc_Tg=round(res[st,],3),
             area_Mha=round(area_state[st]/1e6,4))))
write.csv(long, file.path(td,"conus_noharvest_100yr.csv"), row.names=FALSE)
chg <- data.frame(state=rownames(res), agc_t0=round(res[,"yr0"],1),
                  agc_t100=round(res[,"yr100"],1))
chg$gain_Tg <- round(chg$agc_t100-chg$agc_t0,1)
chg$pct <- round(100*(chg$agc_t100/chg$agc_t0-1),1)
chg <- chg[order(-chg$gain_Tg),]
write.csv(chg, file.path(td,"conus_state_change.csv"), row.names=FALSE)

conus <- colSums(res)
cat(sprintf("\n[tm] === CONUS forest AG live carbon, NO HARVEST ===\n"))
cat(sprintf("  forest area (TreeMap, matched): %.1f Mha\n", sum(area_state)/1e6))
for (j in seq_along(offs))
  cat(sprintf("  +%3d yr (%d): %.0f Tg C\n", offs[j], TM_BASE+offs[j], conus[j]))
cat(sprintf("  net 100-yr gain: %.0f Tg C (%.1f%%)\n",
            conus[length(offs)]-conus[1], 100*(conus[length(offs)]/conus[1]-1)))
cat("  top gainers (Tg):\n"); print(head(chg[,c("state","agc_t0","agc_t100","gain_Tg","pct")],8), row.names=FALSE)

## ---- figure ----
png(file.path(figd,"treemap_conus_100yr.png"), width=820, height=520, res=120)
op<-par(mar=c(4,4.5,3,1))
plot(TM_BASE+offs, conus, type="o", pch=19, lwd=2.5, col="#1b7a4d",
     xlab="Year", ylab="CONUS forest AG live carbon (Tg C)",
     main="CONUS forest carbon under 100-yr NO-HARVEST growth\n(finalized peak-decline curves x TreeMap 2022)")
grid(col="grey88")
text(TM_BASE+offs[length(offs)], conus[length(offs)],
     sprintf("  +%.0f Tg (%.0f%%)", conus[length(offs)]-conus[1],
             100*(conus[length(offs)]/conus[1]-1)), pos=2, cex=0.9)
par(op); dev.off()
cat(sprintf("[tm] wrote treemap/conus_noharvest_100yr.csv + figure\n"))
