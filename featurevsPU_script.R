#now we have all the layers need to format the input pu layer with the features 

library(raster)
library(sf)
library(rgdal)

setwd("D:/corona_contingency/marxan_paper")


#Pu layer = pu_cost

pu<- st_read('pu_layer/pu_layer_cost.shp')

plot(pu)

#ok need to make the values that are zero for 2015 pop 4

navals<- (is.na(pu$X2015_pop_m))

plot(pu$geometry[navals])

pu$X2015_pop_m[navals]<-4

#also make the values below 4 4
low_vals<- which(pu$X2015_pop_m<4)

pu$X2015_pop_m[low_vals]<-4

#now repeat for 2050
navals<- (is.na(pu$X2050_pop_m))
pu$X2050_pop_m[navals]<-4
low_vals<- which(pu$X2050_pop_m<4)

pu$X2050_pop_m[low_vals]<-4


#ok cost is sorted 


#now read in features

combined_stack <- list.files(path = "D:/corona_contingency/marxan_paper/relative_abundance_layers", pattern='.tif', all.files=TRUE, full.names=FALSE)

crs(centroids)

#setwd so it knows where to find them 
setwd("D:/corona_contingency/marxan_paper/relative_abundance_layers")

allrasters <- stack(combined_stack)
crs(allrasters)
#set back so we're working out the correct file 

setwd("D:/corona_contingency/marxan_paper")

#now get the centroids
centroids<-st_read('pu_centroids/pu_centroids.shp')
crs(centroids)


#extract values of raster stack at centroid poinds 
extract_centroids<- raster::extract(allrasters, centroids)
extract_centroids<-as.data.frame(extract_centroids)

#add on PUID to extract_centroids

extract_centroids$PUID<- centroids$PUID

library(dplyr)
#ok now add onto the PU layer
pu_all<- left_join(pu, extract_centroids, by='PUID')

#ok now write
st_write(pu_all, dsn='pu_final', layer='pu_all_features.shp', driver='ESRI Shapefile')
