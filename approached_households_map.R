library(dplyr)
library(leaflet)
library(purrr)
library(raster)

# File names
kDataFileName <- 
  "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"
kClusterMetadataFileName <- "DATA/TIPTOPHHSBaselineDRC_CLUSTERS_BULUNGU.csv"

# Parameters
kDistrictCode <- 2
kDistrictName <- "bulungu"

# Column/Variable names
kDistrictClusterColumn <- paste0("cluster_", kDistrictName)
kDistrictDlusterNameColumn <- paste0(kDistrictClusterColumn, "_name")

# Labels
kHouseholdLabel <- "%s | Household %s"

# Read and pre-format GPS disctrict data: Divide data by clusters
hhs.data <- read.csv(kDataFileName)
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
  walk(function (cluster) {
    #browser()
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
    
    # Look up cluster name
    cluster.name <- district.clusters[
      district.clusters[kDistrictClusterColumn] == cluster, 
      kDistrictDlusterNameColumn]
    
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
  overlayGroups = district.clusters[[kDistrictDlusterNameColumn]])

map