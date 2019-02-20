#
# maxramirez84
# 
# This script ...
#
# INPUTS : ...
# OUTPUTS: ...
#
library(leaflet)
library(KernSmooth)
library(sp)

# File names
kDataFileName <- 
  "DATA/NIG_HHS_Harmonized_withGeoLocate.csv"
  # "DATA/NIG_HHS_Harmonized_withGeoLocate.csv"
  # "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"

# Parameters
kDistrictCode <- "Akure South"
kDistrictName <- "akure"
kIPTp <- 2

# Read and pre-format GPS disctrict data for IPTp
hhs.data <- read.csv(kDataFileName)
hhs.data$longitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA
hhs.data$latitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA

district.data <- hhs.data[hhs.data$district == kDistrictCode, ]
district.data.interviewed <- district.data[district.data$consent == "Yes", ]
district.data.iptpn <- district.data[
  which(district.data$sp_doses_number >= kIPTp), ]

# Compute Kernel Density Estimation (KDE) binning the GPS coordinates according 
# to the bandwith provided.
x = district.data.iptpn[!is.na(district.data.iptpn$longitude), 
                        c("longitude", "latitude")]
kde2d <- bkde2D(
  x         = x,
  bandwidth = c(bw.ucv(x$longitude), bw.ucv(x$latitude))
)

# Calculate contour lines of bins
contour.lines = contourLines(
  x = kde2d$x1,
  y = kde2d$x2,
  z = kde2d$fhat
)

# Extract contour lines level
contour.lines.levels <- as.factor(sapply(contour.lines, `[[`, "level"))
n.levels <- length(levels(contour.lines.levels))

# Convert contour lines to a set of polygon objects
polygons <- lapply(1:length(contour.lines), function(i) {
    Polygons(
      srl = list(Polygon(cbind(contour.lines[[i]]$x, contour.lines[[i]]$y))), 
      ID  = i
    )
  }
)
spatial.polygons <- SpatialPolygons(polygons)

# Create Leaflet map widget from a tile layer (OpenStreetMap)
leaflet(spatial.polygons) %>% 
  addProviderTiles(
    provider    = providers$OpenStreetMap.Mapnik
  ) %>%
  # Add intensity areas (where the indicated number of doses is more likely)
  addPolygons(
    color       = heat.colors(n.levels, NULL)[contour.lines.levels]
  ) %>%
  # Add one point for each interviewed women in the district
  addCircleMarkers(
    lng         = district.data.interviewed$longitude,
    lat         = district.data.interviewed$latitude,
    radius      = .001,
    opacity     = .8,
    color       = "blue",
    fillColor   = "blue",
    fillOpacity = 1
  )