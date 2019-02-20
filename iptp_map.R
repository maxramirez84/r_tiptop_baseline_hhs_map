#
# maxramirez84
# 
# This script ...
#
# INPUTS : ...
# OUTPUTS: ...
#
library(leaflet)

# File names
kDataFileName <- 
  "DATA/NIG_HHS_Harmonized_withGeoLocate.csv"
  # "DATA/NIG_HHS_Harmonized_withGeoLocate.csv"
  # "DATA/TIPTOPHHSBaselineDRC_DATA_WITH_NO_DUPS_2018-06-19_1600.csv"

# Parameters
kDistrictCode <- "Ohaukwu"
kDistrictName <- "ohaukwu"
kIPTp <- 3

# Read and pre-format GPS disctrict data for IPTp3+
hhs.data <- read.csv(kDataFileName)
hhs.data$longitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA
hhs.data$latitude[hhs.data$longitude == 0 | hhs.data$latitude == 0] <- NA

district.data <- hhs.data[hhs.data$district == kDistrictCode, ]
district.data.iptp3 <- district.data[
  which(district.data$sp_doses_number >= kIPTp), ]


# Create Leaflet map widget from a tile layer (OpenStreetMap)
map <- leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik)

map %>% addCircles(
  lng = district.data.iptp3$longitude,
  lat = district.data.iptp3$latitude,
  radius = .5,
  opacity = .8,
  col = "blue"
)