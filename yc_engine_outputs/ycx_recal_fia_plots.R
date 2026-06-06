## ycx_recal_fia_plots.R  (read-only)
## Clean inventory comparison: project the FIA PLOT inventory with the SAME hybrid +
## agedist+ceiling recalibration used for the TreeMap pixels, uniform-grid A0 anchored to
## fia.json (merge convention: per-state A0 for anchored states, median A0 elsewhere).
## Output per-state recal reserve Tg -> conus_recal_fiaplot_100yr.csv. Compared offline to
## treemap/recal_cell/conus_recal_capped_100yr.csv (TreeMap-pixel, same method) to isolate
## inventory basis from model form.
## Usage: Rscript ycx_recal_fia_plots.R [out_dir] [fia_tgagc.csv]
out <- if(length(commandArgs(TRUE))>=1) commandArgs(TRUE)[1] else file.path(Sys.getenv("HOME"),"yield_curves_conus")
TGF <- if(length(commandArgs(TRUE))>=2) commandArgs(TRUE)[2] else file.path(out,"fia_tgagc.csv")
cfg<-file.path(out,"config"); td<-file.path(out,"treemap"); rd<-file.path(td,"recal_cell"); dir.create(rd,showWarnings=FALSE,recursive=TRUE)
fia<-"/fs/scratch/PUOM0008/crsfaaron/fia_by_state"
offs<-seq(0,100,10); LBAC_TO_MGHA<-0.00045359237*2.4710538; BIN<-10L; MIN_CELL<-50L; MIN_FT<-80L; MIN_ST<-200L
ABBR2FIPS <- c(AL=1,AZ=4,AR=5,CA=6,CO=8,CT=9,DE=10,FL=12,GA=13,ID=16,IL=17,IN=18,IA=19,KS=20,KY=21,LA=22,ME=23,MD=24,MA=25,MI=26,MN=27,MS=28,MO=29,MT=30,NE=31,NV=32,NH=33,NJ=34,NM=35,NY=36,NC=37,ND=38,OH=39,OK=40,OR=41,PA=42,RI=44,SC=45,SD=46,TN=47,TX=48,UT=49,VT=50,VA=51,WA=53,WV=54,WI=55,WY=56)
hyb<-function(age,A,k,p,d,As) A*(1-exp(-k*age))^p*exp(-d*pmax(0,age-As))
## ---- g_obs kernel + ceiling (same as recal) ----
rm<-read.csv(file.path(fia,"plot_remeas.csv"),colClasses="character"); rm$REMPER<-suppressWarnings(as.numeric(rm$REMPER))
agc_of<-function(fips){fp<-file.path(fia,sprintf("%d_TREE.csv",fips)); if(!file.exists(fp))return(NULL)
  hdr<-gsub('"','',strsplit(readLines(fp,1),",")[[1]]); idx<-match(c("PLT_CN","STATUSCD","CARBON_AG","TPA_UNADJ"),hdr)
  tmp<-tempfile(fileext=".csv"); system(sprintf("cut -d, -f%s '%s' > '%s'",paste(idx,collapse=","),fp,tmp)); t<-read.csv(tmp); unlink(tmp)
  t$STATUSCD<-suppressWarnings(as.integer(t$STATUSCD)); for(c0 in c("CARBON_AG","TPA_UNADJ"))t[[c0]]<-suppressWarnings(as.numeric(t[[c0]]))
  t<-t[!is.na(t$STATUSCD)&t$STATUSCD==1,]; a<-aggregate(I(CARBON_AG*TPA_UNADJ)~PLT_CN,t,sum,na.rm=TRUE); names(a)[2]<-"agc"; a$PLT_CN<-as.character(a$PLT_CN); a}
incr<-list()
for(st in names(ABBR2FIPS)){mf<-file.path(cfg,sprintf("ycx_membership_%s.csv",st)); if(!file.exists(mf))next
  mem<-read.csv(mf,colClasses="character"); ft<-setNames(mem$ft_group,mem$PLT_CN); pv<-setNames(mem$prov_code,mem$PLT_CN); ow<-setNames(mem$owner4,mem$PLT_CN)
  trt<-setNames(mem$treatment,mem$PLT_CN); age<-setNames(suppressWarnings(as.numeric(mem$STDAGE)),mem$PLT_CN)
  ac<-agc_of(ABBR2FIPS[[st]]); if(is.null(ac))next; ci<-setNames(ac$agc,ac$PLT_CN)
  d<-rm[rm$STATECD==as.character(ABBR2FIPS[[st]]),]; d$c1<-ci[d$PREV_PLT_CN]; d$c2<-ci[d$CN]; d$age<-age[d$CN]; d$trt<-trt[d$CN]
  d<-d[is.finite(d$c1)&is.finite(d$c2)&is.finite(d$REMPER)&d$REMPER>=3&d$REMPER<=15&d$c1>0&d$trt=="untreated"&is.finite(d$age)&d$age>0,]
  if(nrow(d))incr[[st]]<-data.frame(state=st,cell=paste(ft[d$CN],pv[d$CN],ow[d$CN],sep="|"),ft=ft[d$CN],age=d$age,grow=(d$c2-d$c1)/d$REMPER*LBAC_TO_MGHA,stand=d$c1*LBAC_TO_MGHA,stringsAsFactors=FALSE)}
INC<-do.call(rbind,incr)
binfit<-function(age,grow){b<-BIN*(age%/%BIN)+BIN/2; m<-tapply(grow,b,mean,na.rm=TRUE); ab<-as.numeric(names(m)); o<-order(ab); ab<-ab[o]; m<-as.numeric(m[o]); if(length(m)>=3){ms<-stats::filter(m,rep(1/3,3));ms[is.na(ms)]<-m[is.na(ms)];m<-as.numeric(ms)}; approxfun(ab,pmax(m,0),rule=2)}
M<-local({nat<-binfit(INC$age,INC$grow); st<-list();for(s in unique(INC$state)){x<-INC[INC$state==s,];if(nrow(x)>=MIN_ST)st[[s]]<-binfit(x$age,x$grow)}; ft<-list();for(f in unique(INC$ft)){x<-INC[INC$ft==f,];if(nrow(x)>=MIN_FT)ft[[f]]<-binfit(x$age,x$grow)}; ce<-list();ct<-table(INC$cell);for(c0 in names(ct)[ct>=MIN_CELL]){x<-INC[INC$cell==c0,];ce[[c0]]<-binfit(x$age,x$grow)}; list(nat=nat,st=st,ft=ft,ce=ce)})
gp<-function(cell,ftg,st,a){f<-M$ce[[cell]];if(!is.null(f))return(f(a));f<-M$ft[[ftg]];if(!is.null(f))return(f(a));f<-M$st[[st]];if(!is.null(f))return(f(a));M$nat(a)}
q95<-function(x)as.numeric(quantile(x,0.95,na.rm=TRUE))
CEce<-tapply(INC$stand,INC$cell,q95); CEft<-tapply(INC$stand,INC$ft,q95); CEst<-tapply(INC$stand,INC$state,q95); CEna<-q95(INC$stand)
cap_of<-function(cell,ftg,st){v<-CEce[cell];if(is.na(v))v<-CEft[ftg];if(is.na(v))v<-CEst[st];if(is.na(v))v<-CEna;as.numeric(v)}
## hybrid fits per state
H<-list();for(st in names(ABBR2FIPS)){fp<-file.path(out,sprintf("ycx_%s_hybrid_fits.csv",st)); if(!file.exists(fp))next
  f<-read.csv(fp,stringsAsFactors=FALSE); if("response"%in%names(f))f<-f[f$response=="carbon_lbac",]
  for(i in seq_len(nrow(f))){r<-f[i,]; id<-if(r$scope=="state")paste0(st,"@@state") else paste0(st,"@@",r$cell_key); if(is.null(H[[id]]))H[[id]]<-c(r$A,r$k,r$p,r$d,r$Astar)}}
geth<-function(st,cell){k<-H[[paste0(st,"@@",cell)]]; if(!is.null(k))return(k); H[[paste0(st,"@@state")]]}
## ---- project each FIA plot, sum density per state ----
HOR<-100L; oidx<-match(offs,0:HOR)
sumd<-list(); npl<-setNames(integer(0),character(0))
for(st in names(ABBR2FIPS)){mf<-file.path(cfg,sprintf("ycx_membership_%s.csv",st)); if(!file.exists(mf))next
  mem<-read.csv(mf,colClasses="character"); mem$STDAGE<-suppressWarnings(as.numeric(mem$STDAGE)); mem<-mem[!duplicated(mem$PLT_CN)&is.finite(mem$STDAGE)&mem$STDAGE>0,]
  acc<-numeric(length(offs)); n<-0L
  for(i in seq_len(nrow(mem))){cl<-paste(mem$ft_group[i],mem$prov_code[i],mem$owner4[i],sep="|"); h<-geth(st,cl); if(is.null(h))next
    a0<-mem$STDAGE[i]; Astar<-h[5]; ages<-a0+(0:HOR)
    dh<-hyb(ages,h[1],h[2],h[3],h[4],h[5])*LBAC_TO_MGHA; dh[!is.finite(dh)|dh<0]<-0; hinc<-diff(dh)
    go<-gp(cl,mem$ft_group[i],st,ages[-1]); w<-pmax(0,pmin(1,(Astar-ages[-1])/Astar)); cinc<-pmax(w*go+(1-w)*hinc,0)
    dens<-c(dh[1],dh[1]+cumsum(cinc)); cap<-cap_of(cl,mem$ft_group[i],st); dens<-pmin(dens,cap)
    acc<-acc+dens[oidx]; n<-n+1L }
  sumd[[st]]<-acc; npl[st]<-n }
## ---- A0 anchoring (merge convention) ----
tg<-read.csv(TGF,stringsAsFactors=FALSE); TG<-setNames(tg$tg_agc,tg$state)
A0<-c()
for(st in names(sumd)){ d0<-sumd[[st]][1]; if(!is.na(TG[st]) && d0>0) A0[st]<-TG[st]*1e6/d0 }
A0med<-median(A0,na.rm=TRUE)
geta0<-function(st){ if(!is.na(A0[st])) A0[st] else A0med }
## ---- per-state + CONUS totals ----
states<-names(sumd)
long<-do.call(rbind,lapply(states,function(st){a0<-geta0(st); data.frame(state=st,year=2025+offs,fiaplot_Tg=round(sumd[[st]]*a0/1e6,3),row.names=NULL)}))
write.csv(long,file.path(rd,"conus_recal_fiaplot_100yr.csv"),row.names=FALSE)
ct0<-sum(sapply(states,function(st)sumd[[st]][1]*geta0(st)))/1e6
ct100<-sum(sapply(states,function(st)sumd[[st]][length(offs)]*geta0(st)))/1e6
cat(sprintf("[fiaplot] %d anchored states, A0med %.0f ha/plot\n",sum(!is.na(A0)),A0med))
cat(sprintf("[fiaplot] CONUS FIA-plot hybrid+recal reserve: t0=%.0f t100=%.0f Tg (%+.1f%%)\n",ct0,ct100,100*(ct100/ct0-1)))
cat("[fiaplot] wrote conus_recal_fiaplot_100yr.csv\n")
