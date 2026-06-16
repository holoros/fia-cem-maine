## fig_conus_aggregated.R — CONUS aggregated yields across the 12 scenarios
d <- read.csv("/sessions/laughing-amazing-einstein/mnt/outputs/agg/conus_aggregated_yields.csv", stringsAsFactors=FALSE)
a <- d[d$metric=="agc_live_total",]
scen <- unique(a$scenario)
## group + color: reserve(green), harvest(red), intensive(dkred), conservation(blue); stress = dashed/lighter
base_col <- function(s){
  if(grepl("^reserve",s)) "#1b7837" else if(grepl("intensive",s)) "#7a0177" else
  if(grepl("conservation",s)) "#2166ac" else "#b2182b"}
lty_of <- function(s) if(grepl("disturbance",s)) 3 else if(grepl("mortality",s)) 2 else 1
lwd_of<- function(s) if(grepl("disturbance|mortality",s)) 1.8 else 3

png("/sessions/laughing-amazing-einstein/mnt/outputs/agg/conus_aggregated_yields.png", width=1500, height=620, res=110)
par(mfrow=c(1,2), mar=c(4.4,4.8,3.4,1.1), mgp=c(2.8,0.8,0))

## panel 1: trajectories
yl<-range(a$value)*c(0.96,1.02)
plot(NA,xlim=c(2025,2125),ylim=yl,xlab="year",ylab="CONUS above-ground live carbon (Tg C)",
     main="Aggregated CONUS yield by scenario (YC empirical engine)")
t0<-a$value[a$year==2025][1]; abline(h=t0,lty=3,col="#888888"); text(2122,t0,"2025",pos=3,cex=0.7,col="#888888")
for(s in scen){x<-a[a$scenario==s,]; x<-x[order(x$year),]; lines(x$year,x$value,col=base_col(s),lty=lty_of(s),lwd=lwd_of(s))}
legend("topleft",bty="n",cex=0.72,ncol=1,
  legend=c("reserve (no harvest)","managed (conservation)","managed (harvest)","managed (intensive)",
           "— baseline","- - mortality-stressed","·· disturbance-exposed"),
  col=c("#1b7837","#2166ac","#b2182b","#7a0177","#444444","#444444","#444444"),
  lty=c(1,1,1,1,1,2,3), lwd=c(3,3,3,3,2,2,2))

## panel 2: 100-yr change bar
chg<-sapply(scen,function(s){x<-a[a$scenario==s,]; v25<-x$value[x$year==2025]; v125<-x$value[x$year==2125]; 100*(v125/v25-1)})
o<-order(chg); chg<-chg[o]; sc<-scen[o]
cols<-sapply(sc,base_col); dens<-ifelse(grepl("disturbance|mortality",sc),NA,NA)
bp<-barplot(chg,horiz=TRUE,col=cols,border=NA,las=1,names.arg=rep("",length(chg)),
    xlab="100-yr change in CONUS AGC (%)",main="2025 → 2125 change by scenario",xlim=c(-90,130))
abline(v=0,col="#333333")
short<-function(s){s<-sub("\\(no harvest","",s);s<-gsub("managed |reserve |\\(|\\)","",s);s<-gsub("no harvest","reserve",s);trimws(s)}
text(ifelse(chg>=0,-2,2),bp,sprintf("%s",sapply(sc,function(z){z<-sub("managed ","",z);z<-sub("reserve \\(no harvest\\)","reserve",z);z<-gsub("[()]","",z);z})),
     cex=0.6,pos=ifelse(chg>=0,2,4),col="#222222")
text(chg+ifelse(chg>=0,3,-3),bp,sprintf("%+.0f%%",chg),cex=0.62,pos=ifelse(chg>=0,4,2))
dev.off()
cat("wrote conus_aggregated_yields.png\n")
