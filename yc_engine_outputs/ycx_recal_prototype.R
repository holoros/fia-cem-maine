## ycx_recal_prototype.R  (read-only prototype for ADR 0002)
##
## Estimate the CONUS-scale magnitude of recalibrating the production hybrid's
## NEAR-TERM increment to the FIA longitudinal remeasurement record, and the
## residual validation bias after correction. Writes ONLY to treemap/recal/;
## touches no production series, no fia.json, no merge.
##
## Method
##  1. From undisturbed FIA remeasurement (same selection as ycx_ingrowth_gap.R),
##     build observed net AGC increment vs stand age, g_obs(age):
##       - per state: 10-yr age-bin means, 3-bin running smooth -> approxfun
##       - national pooled smoother as fallback where a state is data-poor
##  2. Re-project the TreeMap-2022 reserve trajectory exactly as
##     ycx_treemap_hybrid.R, but at 1-yr resolution, replacing the hybrid's
##     annual increment hinc(a) with a blended increment
##       cinc(a) = w(a)*g_obs_st(a) + (1-w(a))*hinc(a),  cinc >= 0
##     where w(a) = clamp((Astar - a)/Astar, 0, 1) so the lift is full near
##     culmination-distance, decays to 0 at the cell's culmination age Astar,
##     and is exactly 0 beyond it (senescence tail preserved).
##  3. Report corrected CONUS t0/t100 vs current hybrid, per-state deltas, and
##     the corrected near-term growth %/yr vs observed (new validation bias).
##
## Output: treemap/recal/conus_recal_100yr.csv, recal_state_delta.csv,
##         recal_validation.csv ; prints the headline numbers.
## Usage: Rscript ycx_recal_prototype.R [out_dir] [VAT_path]

suppressMessages({library(foreign)})
out <- if(length(commandArgs(TRUE))>=1) commandArgs(TRUE)[1] else file.path(Sys.getenv("HOME"),"yield_curves_conus")
cfg <- file.path(out,"config"); td <- file.path(out,"treemap")
rd  <- file.path(td,"recal"); dir.create(rd,showWarnings=FALSE,recursive=TRUE)
VAT <- if(length(commandArgs(TRUE))>=2) commandArgs(TRUE)[2] else
  "/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2022/TreeMap2022_CONUS.tif.vat.dbf"
fia <- "/fs/scratch/PUOM0008/crsfaaron/fia_by_state"
TM_BASE<-2022L; offs<-seq(0,100,10); LBAC_TO_MGHA<-0.00045359237*2.4710538; PIX_HA<-0.09
ABBR2FIPS <- c(AL=1,AZ=4,AR=5,CA=6,CO=8,CT=9,DE=10,FL=12,GA=13,ID=16,IL=17,
  IN=18,IA=19,KS=20,KY=21,LA=22,ME=23,MD=24,MA=25,MI=26,MN=27,MS=28,MO=29,
  MT=30,NE=31,NV=32,NH=33,NJ=34,NM=35,NY=36,NC=37,ND=38,OH=39,OK=40,OR=41,
  PA=42,RI=44,SC=45,SD=46,TN=47,TX=48,UT=49,VT=50,VA=51,WA=53,WV=54,WI=55,WY=56)
FIPS2ABBR <- setNames(names(ABBR2FIPS), as.character(ABBR2FIPS))
hyb<-function(age,A,k,p,d,As) A*(1-exp(-k*age))^p*exp(-d*pmax(0,age-As))

## ---------- 1. observed net increment vs age, from remeasurement ----------
rm <- read.csv(file.path(fia,"plot_remeas.csv"), colClasses="character")
rm$REMPER<-suppressWarnings(as.numeric(rm$REMPER))
agc_of <- function(abbr){
  fp<-file.path(fia,sprintf("%d_TREE.csv",ABBR2FIPS[[abbr]])); if(!file.exists(fp)) return(NULL)
  hdr<-gsub('"','',strsplit(readLines(fp,1),",")[[1]]); idx<-match(c("PLT_CN","STATUSCD","CARBON_AG","TPA_UNADJ"),hdr)
  tmp<-tempfile(fileext=".csv"); system(sprintf("cut -d, -f%s '%s' > '%s'",paste(idx,collapse=","),fp,tmp))
  t<-read.csv(tmp,stringsAsFactors=FALSE); unlink(tmp)
  t$STATUSCD<-suppressWarnings(as.integer(t$STATUSCD)); for(c0 in c("CARBON_AG","TPA_UNADJ")) t[[c0]]<-suppressWarnings(as.numeric(t[[c0]]))
  t<-t[!is.na(t$STATUSCD)&t$STATUSCD==1,]
  a<-aggregate(I(CARBON_AG*TPA_UNADJ)~PLT_CN,data=t,FUN=sum,na.rm=TRUE); names(a)[2]<-"agc"; a$PLT_CN<-as.character(a$PLT_CN); a
}
incr <- list()
for (st in names(ABBR2FIPS)) {
  mf<-file.path(cfg,sprintf("ycx_membership_%s.csv",st)); if(!file.exists(mf)) next
  mem<-read.csv(mf,colClasses="character"); trt<-setNames(mem$treatment,mem$PLT_CN); age<-setNames(suppressWarnings(as.numeric(mem$STDAGE)),mem$PLT_CN)
  ac<-agc_of(st); if(is.null(ac)) next; ci<-setNames(ac$agc,ac$PLT_CN)
  d<-rm[rm$STATECD==as.character(ABBR2FIPS[[st]]),]
  d$c1<-ci[d$PREV_PLT_CN]; d$c2<-ci[d$CN]; d$trt<-trt[d$CN]; d$age<-age[d$CN]
  d<-d[is.finite(d$c1)&is.finite(d$c2)&is.finite(d$REMPER)&d$REMPER>=3&d$REMPER<=15 &
       d$c1>0 & d$trt=="untreated" & is.finite(d$age) & d$age>0,]
  if(nrow(d)) incr[[st]]<-data.frame(state=st, age=d$age,
      grow=(d$c2-d$c1)/d$REMPER*LBAC_TO_MGHA)        # Mg C/ha/yr (net obs increment)
}
INC<-do.call(rbind,incr); cat(sprintf("[recal] remeasurement increments: %d plots, %d states\n",nrow(INC),length(unique(INC$state))))

## binned-age smoother -> approxfun.  bins of 10 yr, 3-bin running mean.
BIN<-10
smoother <- function(age,grow){
  b<-BIN*(age%/%BIN)+BIN/2; m<-tapply(grow,b,mean,na.rm=TRUE); ab<-as.numeric(names(m))
  o<-order(ab); ab<-ab[o]; m<-as.numeric(m[o]); if(length(m)>=3){ ms<-stats::filter(m,rep(1/3,3)); ms[is.na(ms)]<-m[is.na(ms)]; m<-as.numeric(ms) }
  approxfun(ab, pmax(m,0), rule=2)                  # flat extrapolation at ends
}
g_nat <- smoother(INC$age, INC$grow)
g_st  <- list()
for(st in unique(INC$state)){ s<-INC[INC$state==st,]; if(nrow(s)>=200) g_st[[st]]<-smoother(s$age,s$grow) }
gobs <- function(st,a){ f<-g_st[[st]]; if(is.null(f)) g_nat(a) else f(a) }
cat(sprintf("[recal] state-level g_obs fit for %d states; %d use national fallback\n",
            length(g_st), length(unique(INC$state))-length(g_st)))

## ---------- 2. TreeMap pixels + hybrid fits (as ycx_treemap_hybrid.R) ----------
v<-read.dbf(VAT,as.is=TRUE); names(v)<-toupper(names(v)); v<-v[,intersect(c("PLT_CN","COUNT"),names(v))]
v$PLT_CN<-sub("\\.0+$","",format(v$PLT_CN,scientific=FALSE,trim=TRUE))
mf<-list.files(cfg,pattern="^ycx_membership_.*\\.csv$",full.names=TRUE)
mem<-do.call(rbind,lapply(mf,function(f){d<-read.csv(f,colClasses="character"); d[,c("PLT_CN","STATECD","ft_group","prov_code","owner4","STDAGE")]}))
mem<-mem[!duplicated(mem$PLT_CN),]; mem$STDAGE<-suppressWarnings(as.numeric(mem$STDAGE))
key<-match(v$PLT_CN,mem$PLT_CN); v<-v[!is.na(key),]; mm<-mem[key[!is.na(key)],]
v<-cbind(v,mm[,c("STATECD","ft_group","prov_code","owner4","STDAGE")]); v<-v[is.finite(v$STDAGE)&v$STDAGE>0,]
v$abbr<-FIPS2ABBR[as.character(as.integer(v$STATECD))]; v<-v[!is.na(v$abbr),]
v$cell<-paste(v$ft_group,v$prov_code,v$owner4,sep="|"); v$area_ha<-v$COUNT*PIX_HA

H<-list()
for(st in unique(v$abbr)){ fp<-file.path(out,sprintf("ycx_%s_hybrid_fits.csv",st)); if(!file.exists(fp)) next
  f<-read.csv(fp,stringsAsFactors=FALSE); f<-f[f$response=="carbon_lbac" | is.na(f$response),]
  for(i in seq_len(nrow(f))){r<-f[i,]; id<-if(r$scope=="state")paste0(st,"@@state") else paste0(st,"@@",r$cell_key)
    if(is.null(H[[id]])) H[[id]]<-c(r$A,r$k,r$p,r$d,r$Astar)} }
geth<-function(st,cell){k<-H[[paste0(st,"@@",cell)]]; if(!is.null(k))return(k); H[[paste0(st,"@@state")]]}

## ---------- 3. project hybrid AND recalibrated, 1-yr resolution ----------
states<-sort(unique(v$abbr)); HOR<-100
res_h<-matrix(0,length(states),length(offs),dimnames=list(states,paste0("yr",offs)))   # current hybrid
res_r<-res_h                                                                            # recalibrated
area<-setNames(numeric(length(states)),states); n_noc<-0L
oidx<-match(offs,0:HOR)
for(i in seq_len(nrow(v))){
  h<-geth(v$abbr[i],v$cell[i]); if(is.null(h)){n_noc<-n_noc+1L;next}
  st<-v$abbr[i]; a0<-v$STDAGE[i]; Astar<-h[5]; ar<-v$area_ha[i]
  ages<-a0+(0:HOR)
  dens_h<-hyb(ages,h[1],h[2],h[3],h[4],h[5])*LBAC_TO_MGHA; dens_h[!is.finite(dens_h)|dens_h<0]<-0
  hinc<-diff(dens_h)                                   # hybrid annual increment, length HOR
  go  <-gobs(st,ages[-1])                              # observed increment at each projected age
  w   <-pmax(0,pmin(1,(Astar-ages[-1])/Astar))
  cinc<-pmax(w*go+(1-w)*hinc, 0)                       # blended, non-negative
  dens_r<-c(dens_h[1], dens_h[1]+cumsum(cinc))
  res_h[st,]<-res_h[st,]+dens_h[oidx]*ar/1e6
  res_r[st,]<-res_r[st,]+dens_r[oidx]*ar/1e6
  area[st]<-area[st]+ar
}
cat(sprintf("[recal] projected %d imputations (no curve %d)\n", nrow(v)-n_noc, n_noc))

long<-do.call(rbind,lapply(states,function(st) data.frame(state=st,year=TM_BASE+offs,
  hybrid_Tg=round(res_h[st,],3), recal_Tg=round(res_r[st,],3),
  area_Mha=round(area[st]/1e6,4),row.names=NULL)))
write.csv(long,file.path(rd,"conus_recal_100yr.csv"),row.names=FALSE)

ch<-colSums(res_h); cr<-colSums(res_r)
cat(sprintf("\n[recal] CONUS reserve t0:  hybrid %.0f  recal %.0f Tg (%+.1f%%)\n",ch[1],cr[1],100*(cr[1]/ch[1]-1)))
cat(sprintf("[recal] CONUS reserve t100: hybrid %.0f  recal %.0f Tg (%+.1f%%)\n",ch[length(offs)],cr[length(offs)],100*(cr[length(offs)]/ch[length(offs)]-1)))
cat(sprintf("[recal] 100-yr gain: hybrid %+.1f%%   recal %+.1f%%\n",100*(ch[length(offs)]/ch[1]-1),100*(cr[length(offs)]/cr[1]-1)))

## per-state delta
sd<-data.frame(state=states,
  hybrid_t100=round(res_h[,length(offs)],1), recal_t100=round(res_r[,length(offs)],1),
  delta_Tg=round(res_r[,length(offs)]-res_h[,length(offs)],1),
  delta_pct=round(100*(res_r[,length(offs)]/res_h[,length(offs)]-1),1), row.names=NULL)
write.csv(sd[order(-sd$delta_Tg),],file.path(rd,"recal_state_delta.csv"),row.names=FALSE)

## ---------- 4. validation: near-term growth %/yr vs observed ----------
obsf<-file.path(td,"obs_growth_by_state.csv")
val<-NULL
if(file.exists(obsf)){
  ob<-read.csv(obsf,stringsAsFactors=FALSE)
  gh<-(res_h[,2]-res_h[,1])/10/res_h[,1]*100   # t0->t10 %/yr, hybrid
  gr<-(res_r[,2]-res_r[,1])/10/res_r[,1]*100   # recalibrated
  val<-merge(ob[,c("state","growth_pct_yr")], data.frame(state=states,hybrid_pctyr=round(gh,3),recal_pctyr=round(gr,3)),by="state")
  names(val)[2]<-"observed_pctyr"
  write.csv(val,file.path(rd,"recal_validation.csv"),row.names=FALSE)
  bias_h<-mean(val$hybrid_pctyr-val$observed_pctyr); bias_r<-mean(val$recal_pctyr-val$observed_pctyr)
  r_h<-cor(val$hybrid_pctyr,val$observed_pctyr); r_r<-cor(val$recal_pctyr,val$observed_pctyr)
  cat(sprintf("\n[recal] validation (%d states): mean bias  hybrid %+.2f  recal %+.2f  %%/yr\n",nrow(val),bias_h,bias_r))
  cat(sprintf("[recal] spatial r:  hybrid %.2f  recal %.2f\n",r_h,r_r))
}
cat("[recal] wrote treemap/recal/{conus_recal_100yr,recal_state_delta,recal_validation}.csv\n")
