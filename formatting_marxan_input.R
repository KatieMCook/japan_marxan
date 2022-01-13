#Preparing the PU layer#


library(raster)
library(sf)
library(rgdal)

setwd("D:/corona_contingency/marxan_paper")

#firstly we want to make all the feature abundances be times by area of habitat in cell

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


#SO we need to read in the biodiversity features, stack them together, change their resoltion, mask by the pu layer AND then times by pu$layer

combined_stack <- list.files(path = "D:/corona_contingency/marxan_paper/combined_projected", pattern='.tif', all.files=TRUE, full.names=FALSE)

#setwd so it knows where to find them 
setwd("D:/corona_contingency/marxan_paper/combined_projected")

allrasters <- stack(combined_stack)

#set back so we're working out the correct file 
setwd("D:/corona_contingency/marxan_paper")

#ok now make the resolution the same as the planning unit 
res(allrasters)

#disag
allrasters_disag<- disaggregate(allrasters, fact=2)

res(allrasters_disag)

plot(allrasters_disag[[1]])

#ok now times the rasters by the area covered pu 

relative_abun<- allrasters_disag*rasterise_subs

plot(relative_abun[[35]])

names(relative_abun)<-combined_stack


#ok now export into a new file
setwd("D:/corona_contingency/marxan_paper/relative_abundance_layers")
writeRaster(relative_abun, filename = names(relative_abun), bylayer=TRUE, format='GTiff')


#ok TO DO TOMORROW: get the PU layer, add a PUID column and add on the raster values (but remove the blank ones) then all I need is the cost. 
#also add a status column 
