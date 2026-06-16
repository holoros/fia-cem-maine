## fig_fiadb_treemap.R — FIADB vs TreeMap: inventory-variability range + spatial maps
suppressMessages({library(maps)})
d  <- read.csv("/sessions/laughing-amazing-einstein/mnt/outputs/fvt/fiadb_vs_treemap_by_state.csv", stringsAsFactors=FALSE)
cn <- read.csv("/sessions/laughing-amazing-einstein/mnt/outputs/fvt/fiadb_vs_treemap_conus.csv", stringsAsFactors=FALSE)
ABBR2NAME <- c(AL="alabama",AZ="arizona",AR="arkansas",CA="california",CO="colorado",CT="connecticut",DE="delaware",FL="florida",GA="georgia",ID="idaho",IL="illinois",IN="indiana",IA="iowa",KS="kansas",KY="kentucky",LA="louisiana",ME="maine",MD="maryland",MA="massachusetts",MI="michigan",MN="minnesota",MS="mississippi",MO="missouri",MT="montana",NE="nebraska",NV="nevada",NH="new hampshire",NJ="new jersey",NM="new mexico",NY="new york",NC="north carolina",ND="north dakota",OH="ohio",OK="oklahoma",OR="oregon",PA="pennsylvania",RI="rhode island",SC="south carolina",SD="south dakota",TN="tennessee",TX="texas",UT="utah",VT="vermont",VA="virginia",WA="washington",WV="west virginia",WI="wisconsin",WY="wyoming")
d$region <- ABBR2NAME[d$state]
## diverging ramp centered at 1.0 (TreeMap == FIADB)
divcol <- function(r){ r[!is.finite(r)]<-1; z<-pmax(-1,pmin(1,(r-1)/0.6))
  R<-ifelse(z<0, 1, 1-0.87*z); G<-ifelse(z<0, 1+0.80*z, 1-0.55*z); B<-ifelse(z<0, 1+0.85*z, 1-0.27*z)
  clp<-function(x)pmin(pmax(x,0),1); rgb(clp(R),clp(G),clp(B)) }   # red TreeMap<FIADB -> white -> blue TreeMap>FIADB
paintmap <- function(col_by_region, title){
  m<-map("state",plot=FALSE,fill=TRUE); reg<-sub(":.*","",m$names)
  cols<-col_by_region[reg]; cols[is.na(cols)]<-"#eeeeee"
  map("state",fill=TRUE,col=cols,border="white",lwd=0.3,mar=c(0,0,2,0)); title(title,cex.main=0.95,font.main=2)
}
mkcols <- function(valcol){ v<-setNames(d[[valcol]],d$region); setNames(divcol(v),names(v)) }

png("/sessions/laughing-amazing-einstein/mnt/outputs/fvt/fiadb_vs_treemap.png", width=1500, height=560, res=110)
layout(matrix(c(1,2,3,3),2,2,byrow=FALSE), widths=c(1,1.15))
par(mar=c(0,0,2,0))
paintmap(mkcols("ratio_2025"), "Inventory ratio TreeMap / FIADB — 2025 (t0)")
paintmap(mkcols("ratio_2125"), "Inventory ratio TreeMap / FIADB — 2125 (t100)")
## legend strip
par(new=TRUE); par(fig=c(0.02,0.46,0.02,0.06),mar=c(0,0,0,0)); plot.new()
rs<-seq(0.4,1.6,length=100); image(matrix(rs,ncol=1),col=divcol(rs),axes=FALSE,add=FALSE)
mtext("TreeMap < FIADB                     = (1.0)                     TreeMap > FIADB",1,cex=0.6,line=-0.5)

## panel 3: per-state range (top 16 by mean carbon) as FIADB<->TreeMap dumbbells
par(fig=c(0.5,1,0,1),mar=c(4.3,5.2,3,1),new=TRUE)
d2<-d[is.finite(d$fiadb_2125)&is.finite(d$treemap_2125),]
d2$mean<-(d2$fiadb_2125+d2$treemap_2125)/2; d2<-head(d2[order(-d2$mean),],16); d2<-d2[order(d2$mean),]
yy<-seq_along(d2$state); xl<-range(c(d2$fiadb_2125,d2$treemap_2125))*c(0.9,1.05)
plot(NA,xlim=xl,ylim=c(0.5,length(yy)+0.5),yaxt="n",xlab="reserve AGC at 2125 (Tg C)",ylab="",
     main="Per-state inventory range (FIADB ↔ TreeMap)")
axis(2,at=yy,labels=d2$state,las=1,cex.axis=0.8)
segments(d2$treemap_2125,yy,d2$fiadb_2125,yy,col="#bbbbbb",lwd=3)
points(d2$fiadb_2125,yy,pch=19,col="#b2182b",cex=1.0)
points(d2$treemap_2125,yy,pch=19,col="#2166ac",cex=1.0)
legend("bottomright",bty="n",pch=19,col=c("#b2182b","#2166ac"),legend=c("FIADB (design-based)","TreeMap (pixel, spatial)"),cex=0.85)
dev.off()
cat(sprintf("CONUS 2125: FIADB %.0f vs TreeMap %.0f Tg (range %.0f, %.0f%%)\n",
  cn$agc_2125_Tg[1],cn$agc_2125_Tg[2],abs(cn$agc_2125_Tg[1]-cn$agc_2125_Tg[2]),
  100*abs(cn$agc_2125_Tg[1]-cn$agc_2125_Tg[2])/mean(cn$agc_2125_Tg)))
cat("wrote fiadb_vs_treemap.png\n")
