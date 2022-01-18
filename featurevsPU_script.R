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

#now we need to work out the difference per PU for each feature 

#current 
now_layers <- list.files(path = "D:/corona_contingency/marxan_paper/abundance_change/now", pattern='.tif', all.files=TRUE, full.names=FALSE)

#setwd so it knows where to find them 
setwd("D:/corona_contingency/marxan_paper/abundance_change/now")

now_layers <- stack(now_layers)

#future 
future_layers <- list.files(path = "D:/corona_contingency/marxan_paper/abundance_change/future", pattern='.tif', all.files=TRUE, full.names=FALSE)


#setwd so it knows where to find them 
setwd("D:/corona_contingency/marxan_paper/abundance_change/future")

future_layers<- stack(future_layers)

#set to project directory
setwd("D:/corona_contingency/marxan_paper")


#make sure all the layers are the same mask (in the loop)
mask<-now_layers[[11]]
plot(mask)
#scale each layer between 0-1

scale01<-function(raster){
  raster_scale<-(raster-min(raster[], na.rm = TRUE)) / (max(raster[], na.rm=TRUE)-min(raster[], na.rm=TRUE))
  raster_scale
}

nlayers(now_layers)

rast_test<-scale01(raster)
plot(rast_test)

#set it up first to add to in the loop and then get rid of 1
now_layer_scale<-stack(rast_test)

i=1
#now apply this function to the whole stack    #couldnt get lapply to work 
for(i in 1:nlayers(now_layers)){
  masked<- mask(now_layers[[i]], mask)
  scaled<- scale01(masked)
  now_layer_scale<-stack(now_layer_scale, scaled)
}

plot(now_layer_scale)

nlayers(now_layer_scale)

#now remove the first one
now_layer_scale<-dropLayer(now_layer_scale, 1)

plot(now_layer_scale)

names(now_layer_scale)

#now repeat for future
#set it up first to add to in the loop and then get rid of 1
future_layer_scale<-stack(rast_test)

i=1
#now apply this function to the whole stack    #couldnt get lapply to work 
for(i in 1:nlayers(future_layers)){
  masked<- mask(future_layers[[i]], mask)
  scaled<- scale01(masked)
  future_layer_scale<-stack(future_layer_scale, scaled)
}

#now remove the first one
future_layer_scale<-dropLayer(future_layer_scale, 1)

nlayers(future_layer_scale)

names(now_layer_scale)
names(future_layer_scale)

plot(future_layer_scale)

#ok now change in layers

abundance_change<- future_layer_scale - now_layer_scale

plot(abundance_change) #ok

#check
par(mfrow=c(2,2))


plot(future_layer_scale[[1]])
plot(now_layer_scale[[1]])

plot(abundance_change[[1]])


par(mfrow=c(2,2))


plot(future_layer_scale[[12]])
plot(now_layer_scale[[12]])

plot(abundance_change[[12]])

#ok now extract for centroids 

#extract values of raster stack at centroid poinds 
change_centroids<- raster::extract(abundance_change, centroids)


change_centroids<- as.data.frame(change_centroids)

change_centroids$PUID<- centroids$PUID

write.csv(change_centroids, 'abundance_change/PU_abun_change.csv')

#ok now standardise each col between zero and one
abundance_change<- read.csv('abundance_change/PU_abun_change.csv')


rownames(abundance_change)<-abundance_change[,1]
abundance_change<-abundance_change[,-1]

identical(as.numeric(rownames(abundance_change)), as.numeric(abundance_change$PUID)) #ok PUID and rownames are the same so we can get rid of PUID

#remove PUID column as it is the row names 
abundance_change<-abundance_change[,-30]

abundance_change<-as.matrix(abundance_change)


#ok now sum across planning unit
PU_change<-rowSums(abundance_change_scale)

PU_change<-data.frame(PUID=rownames(abundance_change_scale), total_abun_change=PU_change)

range(PU_change$total_abun_change) #BUT NEGATIVE AND POSITIVE VALUES #it's ok I checked it through 

write.csv(PU_change, 'abundance_change/PU_change.csv')

