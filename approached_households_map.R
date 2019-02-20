#
# maxramirez84
# 
# This script plots in a map geographical coordinates of all visited households 
# (if GPS coordinates are available) during the 
# TIPTOP (https://www.tiptopmalaria.org/) Baseline Household Survey (HHS). It 
# also approximates cluster boundaries as a circle in which the center is the 
# centroid of the cluster points and the radius the distance between this 
# centroid and the farthest point inside the cluster.
#
# INPUTS : HHS dataset, Cluster Names, Code of the District to be Plotted and
#          Name of the District to be Plotted.
# OUTPUTS: A Leaflet (https://leafletjs.com/) map widget
#
library(dplyr)
library(leaflet)
library(purrr)
library(raster)

# File names
kDataFileName <- 
  "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"
  # "DATA/NIG_HHS_Harmonized_withGeoLocate.csv"
  # "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"
kClusterMetadataFileName <- 
  "DATA/TIPTOPHHSBaselineDRC_CLUSTERS_KENGE.csv"
  # "DATA/TIPTOPHHSBaselineNIG_CLUSTERS_AKURE.csv"
  # "DATA/TIPTOPHHSBaselineNIG_CLUSTERS_OHAUKWU.csv"
  # "DATA/TIPTOPHHSBaselineDRC_CLUSTERS_BULUNGU.csv"

# Parameters
kDistrictCode <- 1
kDistrictName <- "kenge"

# Column/Variable names
kDistrictClusterColumn <- paste0("cluster_", kDistrictName)
kDistrictClusterNameColumn <- paste0(kDistrictClusterColumn, "_name")

# Labels
kHouseholdLabel <- "%s | Household %s"

# Read and pre-format GPS disctrict data: Divide data by clusters
hhs.data <- read.csv(kDataFileName)
hhs.data$longitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA
hhs.data$latitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA

district.data <- hhs.data[hhs.data$district == kDistrictCode, ]
district.data.cluster <- split(district.data, 
                               district.data[kDistrictClusterColumn])

# Read clusters' metadata: names
district.clusters <- read.csv(kClusterMetadataFileName)

# Create Leaflet map widget from a tile layer (OpenStreetMap)
map <- leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik)

# Put households and clusters' boundaries on the map
names(district.data.cluster) %>%
  # For each cluster (walk), geopositionate households and boundaries 
  walk(function(cluster) {
    # Cluster boundaries defined as a circle in which the center is the centroid
    # of GPS points forming the cluster and the radius is the distance between 
    # this center and the farthest point
    centroid.lng <- mean(district.data.cluster[[cluster]]$longitude, na.rm = T)
    centroid.lat <- mean(district.data.cluster[[cluster]]$latitude, na.rm = T)
    radius <- max(pointDistance(
      p1     = c(centroid.lng, centroid.lat), 
      p2     = district.data.cluster[[cluster]][c("longitude", "latitude")],
      lonlat = T
    ), na.rm = T)
    #browser()
    
    # Look up cluster name
    cluster.name <- district.clusters[
      district.clusters[kDistrictClusterColumn] == cluster, 
      kDistrictClusterNameColumn]
    
    map <<- map %>%
      # Add a marker for each geopositionated household in the cluster
      addMarkers(
        data           = district.data.cluster[[cluster]],
        lng            = ~longitude,
        lat            = ~latitude,
        label          = ~sprintf(kHouseholdLabel, cluster.name, household),
        group          = cluster.name,
        clusterOptions = markerClusterOptions(removeOutsideVisibleBounds = F)
      ) %>%
      # Add a circle for each cluster (proxy of cluster boundaries)
      addCircles(
        lng    = centroid.lng,
        lat    = centroid.lat,
        label  = cluster.name,
        weight = 1,
        radius = radius,
        group  = cluster.name
      )
  }
)

# Put layers control to display or hide concrete clusters
map <- map %>% addLayersControl(
  overlayGroups = district.clusters[[kDistrictClusterNameColumn]])

map