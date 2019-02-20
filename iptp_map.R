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

# Divide the women interviewed in two groups: (1) women who took at least the
# number of doses indicated by the parameter kIPTp and (2) the others
split.condition = !is.na(district.data.interviewed$sp_doses_number) & 
  district.data.interviewed$sp_doses_number >= kIPTp
district.data.iptpn.achieved <- district.data.interviewed[split.condition, ]
district.data.iptpn.failed <- district.data.interviewed[!split.condition, ]

# Compute Kernel Density Estimation (KDE) binning the GPS coordinates according 
# to the bandwith provided
x = district.data.iptpn.achieved[!is.na(district.data.iptpn.achieved$longitude), 
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
  # Add one point for each interviewed women in the district who took at least
  # the number of doses indicated by the parameter kIPTp
  addCircleMarkers(
    lng         = district.data.iptpn.achieved$longitude,
    lat         = district.data.iptpn.achieved$latitude,
    radius      = .001,
    opacity     = .8,
    color       = "blue",
    fillColor   = "blue",
    fillOpacity = 1
  ) %>%
  # Add one point for each interviewed women in the district who did NOT took at
  # least the number of doses indicated by the parameter kIPTp
  addCircleMarkers(
    lng         = district.data.iptpn.failed$longitude,
    lat         = district.data.iptpn.failed$latitude,
    radius      = .001,
    opacity     = .8,
    color       = "red",
    fillColor   = "red",
    fillOpacity = 1
  )