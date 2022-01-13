#fishnet script#

library(raster)
library(sf)
library(rgdal)

setwd("D:/corona_contingency/marxan_paper")

#making fish net for PUs over reefs, read in the reef habitat as a shp file, rasterise and conevet back to shapefile


#ok read in habitat layer
hard_sub<- readOGR('hard_substrate/JPZunoPlus_hardSubstrate_v1.shp')

#plot(hard_sub) #ok check

#rasterise to get coverage and use the cells that are partially covered as well as fully 

#import projected prediction raster for resolution 
fish1<- raster('fish_proj_template.tif')

plot(fish1)

res(fish1)

#ok increase the resoltion by double

#disaggregate 
fish_disag <- disaggregate(fish1, fact=2)
res(fish_disag)

#ok now rasterise the hard_substrate layer with this 
crs(fish_disag)
crs(hard_sub)
  
rasterise_subs<- rasterize(hard_sub, fish_disag, getCover=TRUE)

plot(rasterise_subs)

rasterise_subs[rasterise_subs==0]<-NA

par(mfrow=c(1,1))
plot(rasterise_subs)

#ok now turn back into polygon
pu_layer<- rasterToPolygons(rasterise_subs )

plot(pu_layer)

#export
pu_st<- st_as_sf(pu_layer)

#now export as it should have the crs
 #st_write(pu_st, dsn='pu_layer', layer='pu_layer.shp', driver='ESRI Shapefile')

