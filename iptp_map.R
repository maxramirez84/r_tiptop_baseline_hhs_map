#
# maxramirez84
# 
# This script builds a heat map representing the intensity of the IPTp 
# adherence. In this case, IPTp adherence is defined as taking at least the 
# number of doses indicated by the parameter kIPTp. The script also plots all
# the households in which a woman was interviewed. And it splits them by those
# women who achieve the IPTp and those who not. 
#
# INPUTS : HHS dataset and Code of the District to be Plotted
# OUTPUTS: A Leaflet (https://leafletjs.com/) map widget
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
kDistrictCode <- "Ohaukwu"
kIPTp <- 3

# Read and pre-format GPS disctrict data for IPTp
hhs.data <- read.csv(kDataFileName, stringsAsFactors = F)
hhs.data$longitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA
hhs.data$latitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA

district.data <- hhs.data[hhs.data$district == kDistrictCode, ]
district.data$consent[district.data$consent == "No"] <- 0
district.data$consent[district.data$consent == "Yes"] <- 1
district.data.interviewed <- district.data[which(district.data$consent == 1), ]

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
    color       = heat.colors(n.levels, NULL)[contour.lines.levels],
    group       = "Intensity Areas"
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
    fillOpacity = 1,
    group       = "IPTp Achieved"
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
    fillOpacity = 1,
    group       = "IPTp Failed"
  ) %>%
  # Add layers control to display or hide different elements 
  addLayersControl(
    overlayGroups = c("Intensity Areas", "IPTp Achieved", "IPTp Failed")
  )