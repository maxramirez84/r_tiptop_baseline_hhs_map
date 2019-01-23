# leaflet
library(dplyr)
library(leaflet)
library(RColorBrewer)
library(data.table)
library(raster)
library(purrr)

hhs_data = read.csv("DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv")
district_data = hhs_data[hhs_data$district == 2, ]

district_data.df = split(district_data, district_data$cluster_bulungu)

l <- leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik)

names(district_data.df) %>% 
  walk(function(df) {
    #browser()
    centroid_lng = mean(district_data.df[[df]]$longitude, na.rm = T)
    centroid_lat = mean(district_data.df[[df]]$latitude, na.rm = T)
    l <<- l %>% addMarkers(
      data = district_data.df[[df]],
      lng = ~longitude,
      lat = ~latitude,
      label = ~paste("Cluster:", cluster_bulungu, "HH ID:", household),
      group = df,
      clusterOptions = markerClusterOptions(removeOutsideVisibleBounds = F)
      ) %>% addCircles(
        lng = centroid_lng,
        lat = centroid_lat,
        label = paste("Cluster:", df),
        weight = 1,
        radius = max(pointDistance(
          p1 = c(centroid_lng, centroid_lat), 
          p2 = district_data.df[[df]][c("longitude", "latitude")],
          lonlat = T
          ), na.rm = T),
        group = df
      )
  })

l <- l %>% addLayersControl(overlayGroups = names(district_data.df))
l
