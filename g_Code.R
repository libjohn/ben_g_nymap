library(ggplot2)
library(maptools)
library(rgeos)
library(Cairo)
library(ggmap)
library(scales)
library(RColorBrewer)
library(gpclib)
library(rgdal)
library(sp)
set.seed(8000)



#Load shape file

  setwd("/Users/bengrunwald/Documents/U Chicago/Research/Wardlow/Data")
  nyc.shp<-readShapeSpatial("Shape Files/NYC Census Tract Shape File/nyct2000_16b/nyct2000.shp")
  ny.shp<-readShapeSpatial("/Users/bengrunwald/Documents/U Chicago/Research/Wardlow/Data/Shape Files/New York State Shape File/st36_d00.shp")

#Process shape file
  as.numeric(as.character(nyc.shp$BoroCT2000))->nyc.shp$BoroCT2000

  data.frame(BoroCT2000=as.numeric(as.character(nyc.shp$BoroCT2000)),
 		     CT2000    =as.numeric(as.character(nyc.shp$CT2000)))->nyc.shp2

#Process Stop data
  summarise(group_by(stop[stop$year>=2007,], boroct00), 
  			mean.HCA=mean(AC_INCID),
  			mean.viol=mean(cr.ct.viol.index.12mo),
  			mean.hom=mean(cr.ct.hom.non.neg.12mo),
  			count=n())->ct.agg.stop

  as.numeric(as.character(ct.agg.stop$boroct00))->ct.agg.stop$boroct00

  #Drop all rows with a missing census tract
  filter(ct.agg.stop, !is.na(boroct00))->ct.agg.stop

#Join shape and stop data so that I can make sure that the data i use contains the same census tracts in both (out of about 2000 a few are missing in the stop data)
  left_join(nyc.shp2, ct.agg.stop, by=c("BoroCT2000"="boroct00"))->merge


#Create cut points for each variable
  cut(merge$mean.HCA, 
      breaks=c(0, .3, .5, .7, 1), 
  	  dig.lab=6, 
  	  right=FALSE, 
  	  include.lowest=TRUE)->merge$mean.HCA.cat

  cut(merge$count, 
      breaks=c(0, 500, 1000, 4000, 8000, 100000), 
      dig.lab=6, 
      right=FALSE)->merge$count.cat

  cut(merge$mean.viol, 
      breaks=c(0, 15, 32, 63, 120, 400), 
      dig.lab=6, 
      right=FALSE)->merge$mean.viol.cat

  cut(merge$mean.hom, 
      breaks=c(0, .09, .24, .32, .6, 400), 
      dig.lab=6, 
      right=FALSE)->merge$mean.hom.cat


  table(merge$mean.HCA.cat, useNA="always")
  table(merge$count.cat, useNA="always")
  table(merge$mean.viol.cat, useNA="always")
  
#5 observations of 2216 are missing because there was no stop in the census tract; drop those observations

  length(unique(stop$boroct00))
  table(is.na(merge$mean.HCA))
  table(is.na(merge$count))
  table(is.na(merge$mean.HCA.cat))
  table(is.na(merge$count.cat))
  
  #Drop them.
  filter(merge, !is.na(mean.HCA))->merge

#Not sure why I need to do this, but it's to format the shape file for ggplot
  gpclibPermit()
  fortify(nyc.shp, region= "BoroCT2000")->nyc.shp


#Create HCA Graph

  # setwd("/Users/bengrunwald/Dropbox/Wardlow/Output")
  # dev.off()
  # tiff("HCA Map.tiff", res=300, width=6, height=6, units="in")
  
  ggplot()+
#  geom_map(aes(0),map=ny.shp)+
  geom_map(aes(map_id=BoroCT2000, fill=mean.HCA.cat), 
		   data=merge,
   		   map=nyc.shp)+
  scale_fill_grey(start=1, end=0, name="% HCA")+
   theme(axis.text.x = element_blank(), 
  	     axis.text.y = element_blank(),
  	     axis.ticks = element_blank(), 
         axis.title.x = element_blank(), 
         axis.title.y = element_blank(),
         panel.grid.major = element_blank(), 
         panel.grid.minor = element_blank(),
         panel.background = element_rect(fill="lightskyblue1"), 
         plot.background = element_rect(fill="lightskyblue1", color="black", size=1), 
         axis.line = element_blank(),
         legend.key=element_rect(colour="black"),
         legend.background=element_rect(colour="black"))+
    expand_limits(x = nyc.shp$long, y = nyc.shp$lat)

  # dev.off()
