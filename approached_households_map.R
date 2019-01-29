library(dplyr)
library(leaflet)
library(purrr)
library(raster)

# File names
data_file_name <- "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"
cluster_metadata_file_name <- "DATA/TIPTOPHHSBaselineDRC_CLUSTERS_BULUNGU.csv"

# Parameters
district_code <- 2
district_name <- "bulungu"

# Column/Variable names
district_cluster_column <- paste0("cluster_", district_name)
district_cluster_name_column <- paste0(district_cluster_column, "_name")

# Labels
household_label <- "%s | Household %s"

# Read and pre-format GPS disctrict data: Divide data by clusters
hhs_data <- read.csv(data_file_name)
district_data <- hhs_data[hhs_data$district == district_code, ]
district_data.cluster <- split(district_data, district_data[district_cluster_column])

# Read clusters' metadata: names
district_clusters <- read.csv(cluster_metadata_file_name)

# Create Leaflet map widget from a tile layer (OpenStreetMap)
l <- leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik)

# Put households and clusters' boundaries on the map
names(district_data.cluster) %>%
  # For each cluster (walk), geopositionate households and boundaries 
  walk(function(cluster) {
    #browser()
    # Cluster boundaries defined as a circle in which the center is the centroid of GPS points 
    # forming the cluster and the radius is the distance between this center and the farthest point
    centroid_lng <- mean(district_data.cluster[[cluster]]$longitude, na.rm = T)
    centroid_lat <- mean(district_data.cluster[[cluster]]$latitude, na.rm = T)
    radius <- max(pointDistance(
      p1 = c(centroid_lng, centroid_lat), 
      p2 = district_data.cluster[[cluster]][c("longitude", "latitude")],
      lonlat = T
    ), na.rm = T)
    
    # Look up cluster name
    cluster_name <- district_clusters[district_clusters[district_cluster_column] == cluster,
                                      district_cluster_name_column]
    
    l <<- l %>%
      # Add a marker for each geopositionated household in the cluster
      addMarkers(
        data = district_data.cluster[[cluster]],
        lng = ~longitude,
        lat = ~latitude,
        label = ~sprintf(household_label, cluster_name, household),
        group = cluster_name,
        clusterOptions = markerClusterOptions(removeOutsideVisibleBounds = F)
      ) %>%
      # Add a circle for each cluster (proxy of cluster boundaries)
      addCircles(
        lng = centroid_lng,
        lat = centroid_lat,
        label = cluster_name,
        weight = 1,
        radius = radius,
        group = cluster_name
      )
  })

# Put layers control to display or hide concrete clusters
l <- l %>% addLayersControl(overlayGroups = district_clusters[[district_cluster_name_column]])

l
