library(tidyverse)
library(rprojroot)
library(readxl)
library(patchwork)
library(kableExtra)
library(ompr)
library(latex2exp)
library(RColorBrewer)
library(git2rdata)
library(sf)
library(gmapsdistance)
library(rprojroot)
projroot <- find_root_file("100_design_common", "030_optimization",
                           criterion = has_file("mne-design.Rproj"))
gitroot <- find_root(is_git_root)
datapath <- file.path(projroot, "data")
rdata_path <- file.path(
    datapath,
    "binary/intermediate/objects_panflpan5.RData")
load(rdata_path)

locations <- samplinglocations_sf %>%
    dplyr::select(grts_address) %>%
    cbind(sf::st_coordinates(
        samplinglocations_sf)) %>%
    distinct() %>%
    rename(xlambert = X, ylambert = Y) %>%
    st_transform("EPSG:4326")
locations <- locations %>%
    cbind(sf::st_coordinates(
        locations)) %>%
    rename(xwgs84 = X, ywgs84 = Y) %>%
    mutate(locwgs84 = paste0(ywgs84, "+", xwgs84))

#bereken de afstand in meter
distances <- sf::st_distance(
    x = locations,
    y = locations,
    by_element = FALSE
)
rownames(distances) <- locations %>%
    st_drop_geometry() %>%
    dplyr::pull(grts_address)
colnames(distances) <- locations %>%
    st_drop_geometry() %>%
    dplyr::pull(grts_address)
distances <- units::drop_units(distances)
distances[upper.tri(distances)] <- NA
distances_long <- distances %>%
    as.data.frame() %>%
    mutate(loc1 = rownames(distances)) %>%
    pivot_longer(col = !starts_with("loc"),
                 names_to = "loc2",
                 values_to = "distance") %>%
    filter(loc1 != loc2,  !is.na(distance)) #verwijder  diagonaal elementen en upper triangle

#getting travel times from google maps but only for points that are close enough together
# https://github.com/rodazuero/gmapsdistance
# #Setting the API key:
max_dist <- 20000#max 20 kilometers euclidean distance between points.
set.api.key("AIzaSyBH1OD-AXn6gaE9FLEJB7KNIouS-ExM_g4")
distances_long <- distances_long %>%
    left_join(locations %>%
                  dplyr::select(grts_address, locwgs84) %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  st_drop_geometry(),
              by = join_by(loc1 == grts_address)) %>%
    rename(locwgs84_1 = locwgs84) %>%
    left_join(locations %>%
                  dplyr::select(grts_address, locwgs84) %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  st_drop_geometry(),
              by = join_by(loc2 == grts_address)) %>%
    rename(locwgs84_2 = locwgs84)

tt <- distances_long %>%
    dplyr::filter(distance <= max_dist) %>%
    mutate(travel_time = 0,
           travel_distance = 0,
           travel_status = "0")
# in a for-loop since the function sometimes fails and I want to be able to save results that have already been calculated
for (row in first(which(tt$travel_status == "0")):nrow(tt)) {
    traveltime <- gmapsdistance(origin = tt[row,"locwgs84_1"],
                                destination = tt[row,"locwgs84_2"],
                                mode = "driving")
    tt[row, "travel_time"] <- traveltime$Time
    tt[row, "travel_distance"] <- traveltime$Distance
    tt[row, "travel_status"] <- traveltime$Status
}


distance_long <- distances_long %>%
    # dplyr::select(-travel_time, -travel_distance,
    #               -travel_status) %>%
    left_join(tt)

ggplot(distance_long %>% dplyr::filter((travel_status != "0"))) +
    geom_point(aes(x = distance, y = travel_distance)) +
    geom_line(data = data_frame(x = c(0, 0), y = c(20000, 20000)),
              aes(x = x, y = y), color = "red")

save(distances, distances_long, distance_long,
           file = paste0(datapath, "/traveltimes.Rdata")
)


### set up a run from here
load((paste0(datapath, "/traveltimes.Rdata")
))
max_dist <- 20000#max 20 kilometers euclidean distance between points.
set.api.key("AIzaSyBH1OD-AXn6gaE9FLEJB7KNIouS-ExM_g4")
tt <- distances_long %>%
    dplyr::filter(distance <= max_dist)
tt <- tt %>% left_join(distance_long)


first(which(tt$travel_status == "0"))
for (row in first(which(tt$travel_status == "0")):nrow(tt)) {
    traveltime <- gmapsdistance(origin = tt[row,"locwgs84_1"],
                                destination = tt[row,"locwgs84_2"],
                                mode = "driving")
    tt[row, "travel_time"] <- traveltime$Time
    tt[row, "travel_distance"] <- traveltime$Distance
    tt[row, "travel_status"] <- traveltime$Status
}
distance_long <- distances_long %>%
    # dplyr::select(-travel_time, -travel_distance,
    #               -travel_status) %>%
    left_join(tt)
save(distances, distances_long, distance_long,
     file = paste0(datapath, "/traveltimes.Rdata")
)

# free google api key is fully used - continue with osrm from row 156143
library(osrm)
tt <- tt %>%
    left_join(locations %>%
                  st_drop_geometry() %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  dplyr::select(grts_address, xwgs84, ywgs84),
              by = join_by(loc1 == grts_address)) %>%
    rename(src_x = xwgs84, src_y = ywgs84)  %>%
    left_join(locations %>%
                  st_drop_geometry() %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  dplyr::select(grts_address, xwgs84, ywgs84),
              by = join_by(loc2 == grts_address)) %>%
    rename(dst_x = xwgs84, dst_y = ywgs84)

a <- which(tt$travel_status %in% c("osrm", "ROUTE_NOT_FOUND"))
a <- a[a >= 239347]
#for (row in first(which(tt$travel_status == "0")):nrow(tt)) {
for (row in a) {
    traveltime <- osrmTable(
        src = tt[row,c("src_x", "src_y")],
        dst = tt[row,c("dst_x", "dst_y")],
        measure = c('duration', 'distance'),
        osrm.profile = "car")
    tt[row, "travel_time"] <- traveltime$durations
    tt[row, "travel_distance"] <- traveltime$distances
}
tt <- tt %>%
    mutate(travel_status = ifelse(travel_status == "ROUTE_NOT_FOUND",
                                  "osrm", travel_status))
distances_long <- distances_long %>%
    dplyr::select(-travel_time, -travel_distance,
                   -travel_status) %>%
    left_join(tt)
save(distances, tt, distances_long,
     file = paste0(datapath, "/traveltimes.Rdata")
)
#adjust since the travel times in Google are in seconds and in minutes for osrm???
load(paste0(datapath, "/traveltimes.Rdata"))
distances_long <- distances_long %>%
    mutate(travel_time = ifelse(travel_status == "OK",
                                travel_time/60,
                                travel_time))
save(distances, tt, distances_long,
     file = paste0(datapath, "/traveltimes.Rdata")
)

ggplot(distances_long %>% dplyr::filter((travel_status != "0"))) +
    geom_point(aes(x = distance, y = travel_distance)) +
    facet_wrap(vars(travel_status)) +
    geom_line(data = tibble(x = c(0, 0), y = c(20000, 20000)),
              aes(x = x, y = y), color = "red", linewidth = 10)

#--------------new code 2025; nb of grts addresses roughly doubled-------------#
library(tidyverse)
library(rprojroot)
library(readxl)
library(patchwork)
library(kableExtra)
library(ompr)
library(latex2exp)
library(RColorBrewer)
library(git2rdata)
library(sf)
library(gmapsdistance)
library(rprojroot)
library(osrm)
projroot <- find_root_file("100_design_common", "030_optimization",
                           criterion = has_file("mne-design.Rproj"))
gitroot <- find_root(is_git_root)
datapath <- file.path(projroot, "data")
rdata_path <- file.path(
    datapath,
    "binary/intermediate/objects_panflpan5.RData")
load(rdata_path)

locations <- samplinglocations_sf %>%
    dplyr::select(grts_address) %>%
    cbind(sf::st_coordinates(
        samplinglocations_sf)) %>%
    distinct() %>%
    rename(xlambert = X, ylambert = Y) %>%
    st_transform("EPSG:4326")
locations <- locations %>%
    cbind(sf::st_coordinates(
        locations)) %>%
    rename(xwgs84 = X, ywgs84 = Y) %>%
    mutate(locwgs84 = paste0(ywgs84, "+", xwgs84))

#bereken de afstand in meter
distances_new <- sf::st_distance(
    x = locations,
    y = locations,
    by_element = FALSE
)
rownames(distances_new) <- locations %>%
    st_drop_geometry() %>%
    dplyr::pull(grts_address)
colnames(distances_new) <- locations %>%
    st_drop_geometry() %>%
    dplyr::pull(grts_address)
distances_new <- units::drop_units(distances_new)
distances_new[upper.tri(distances_new)] <- NA
distances_long_new <- distances_new %>%
    as.data.frame() %>%
    mutate(loc1 = rownames(distances_new)) %>%
    pivot_longer(col = !starts_with("loc"),
                 names_to = "loc2",
                 values_to = "distance") %>%
    filter(loc1 != loc2,  !is.na(distance)) #verwijder  diagonaal elementen en upper triangle

max_dist <- 20000#max 20 kilometers eucl

load((paste0(datapath, "/traveltimes.Rdata")))
tt_new <- distances_long_new %>%
    dplyr::filter(distance <= max_dist)
tt_new <- tt_new %>%
    left_join(locations %>%
                  st_drop_geometry() %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  dplyr::select(grts_address, xwgs84, ywgs84),
              by = join_by(loc1 == grts_address)) %>%
    rename(src_x = xwgs84, src_y = ywgs84)  %>%
    left_join(locations %>%
                  st_drop_geometry() %>%
                  mutate(grts_address = as.character(grts_address)) %>%
                  dplyr::select(grts_address, xwgs84, ywgs84),
              by = join_by(loc2 == grts_address)) %>%
    rename(dst_x = xwgs84, dst_y = ywgs84)

load((paste0(datapath, "/traveltimes.Rdata")))
tt_new <- tt_new %>%
    left_join(tt)

a <- which(is.na(tt_new$travel_time))#meer dan 1 miljoen!!
#for (row in first(which(tt$travel_status == "0")):nrow(tt)) {
for (row in a[seq_len(min(10000, length(a)))]) {
    traveltime <- osrmTable(
        src = tt_new[row,c("src_x", "src_y")],
        dst = tt_new[row,c("dst_x", "dst_y")],
        measure = c('duration', 'distance'),
        osrm.profile = "car")
    tt_new[row, "travel_time"] <- traveltime$durations
    tt_new[row, "travel_distance"] <- traveltime$distances
}

#There is one pair for which OSM cannot calculate a travel time and distance.
#However, these points are very close together. We therefor will manually set
#the travel distance and travel time to zero.
problem <- which(tt_new$loc1 == "6520818" & tt_new$loc2 == "229362")
tt_new[problem, c("travel_time", "travel_distance")] <- cbind(0, 0)

summary(as_factor(tt_new$travel_status))
hist(tt_new %>% dplyr::filter(is.na(travel_status)) %>% dplyr::pull(travel_time))
hist(tt_new %>% dplyr::filter(!is.na(travel_status)) %>% dplyr::pull(travel_time))#this travel time is expressed in seconds in stead of minutes
hist(tt_new %>% dplyr::filter(is.na(travel_status)) %>% dplyr::pull(travel_distance))
hist(tt_new %>% dplyr::filter(!is.na(travel_status)) %>% dplyr::pull(travel_distance))
tt_new <- tt_new %>%
    mutate(travel_time = ifelse(!is.na(travel_status),
                                travel_time/60,
                                travel_time))
distance_long_new <- distances_long_new %>%
    # dplyr::select(-travel_time, -travel_distance,
    #               -travel_status) %>%
    left_join(tt_new)
save(distances_new, tt_new, distances_long_new,
     file = paste0(datapath, "/traveltimes_new.Rdata")
)
