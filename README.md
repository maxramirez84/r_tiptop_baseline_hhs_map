# TIPTOP Baseline Household Survey Spatial Data Analysis
Set of scripts for the spatial analysis of the baseline household survey data (Malaria in Pregnancy) executed in the context of the TIPTOP propject.

## Script 1: Geographical Distribution of Approached Households
This script is named approached_households_map.R. It plots in a map geographical coordinates of all visited households (if GPS coordinates are available) during the [TIPTOP](https://www.tiptopmalaria.org/) Baseline Household Survey (HHS). It also approximates cluster boundaries as a circle in which the center is the centroid of the cluster points and the radius the distance between this centroid and the farthest point inside the cluster.

The script receives as inputs the following datasets:
1. HHS Dataset, containing for each record (i.e. approached household) the disctrict code, the cluster code, longitude, latitude and the household ID.
2. Cluster names, which is a set of pairs cluster code and name.

and two parameters; the district code and name to be plotted.

Finally, it produces a [Leaflet](https://leafletjs.com/) map widget with all available household GPS coordinates plotted and cluster boundaries.

## Script 2: IPTp Adherence Heat Map
This script is named iptp_map.R. It builds a heat map representing the intensity of the IPTp  adherence. In this case, IPTp adherence is defined as taking at least the number of doses indicated by the parameter kIPTp. The script also plots all the households in which a woman was interviewed. And it splits them by those women who achieve the IPTp and those who not.

The script receives as inputs the following dataset:
1. HHS Dataset, containing for each record (i.e. approached household) the disctrict code, longitude, latitude, consent and SP doses number.

and one parameter; the district code to be plotted.

Finally, it produces a [Leaflet](https://leafletjs.com/) map widget with the intensity areas representing IPTp adherence.
