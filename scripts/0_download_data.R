#'-------------------------------------------------
#' Acquire fresh files for analysis
#'-------------------------------------------------
library(gh)
library(rnoaa)
library(purrr)
library(readr)
library(sf)

#SML coords 43.034352,-70.7573608

#'-----------
# SML intertidal abundance data cleaned ####
#'-----------

combined_int_url <- "https://github.com/Intertidal-Subtidal-WG/data_merge_intertidal_subtidal/blob/main/tidy_data/combined_intertidal_abundance.RDS?raw=true&login=jebyrnes"

download.file(combined_int_url, destfile = "data/combined_intertidal_abundance.RDS", method = "wget")

#'-----------
# SML Transect Info data ####
#'-----------

download.file("https://github.com/brianscheng/SEED/raw/main/data/intertidal/transect_info.csv",
              "data/transect_info.csv",
              method = "wget")

#'-----------
# Temperature Data ####
#'-----------

temp_url <- "https://github.com/Intertidal-Subtidal-WG/subtidal_appledore_temps/blob/main/data/processed_data/oisst_predicted_temps.RDS?raw=true"
download.file(temp_url, destfile = "data/oisst_projected_temps.RDS", method = "wget")

#'-----------
# Catch data ####
#'-----------

repo_dir <- gh("GET /repos/Intertidal-Subtidal-WG/additional_data_sources/git/trees/adf9605f4eac8f8770dbffe6c7286b3dcee3fc3a?recursive=1",
               username ="jebyrnes")


repo_files <- map_chr(repo_dir$tree,
                      ~.x$path) %>%
  stringr::str_subset("cleaned_data/.*catch_ts")

walk(repo_files,
     ~download.file(paste0(
       "https://raw.githubusercontent.com/Intertidal-Subtidal-WG/additional_data_sources/master/",
       .x),
       paste0("data/", stringr::str_remove_all(.x, "data/cleaned_data/")),
       method = "wget"
       )
     )

#'-----------
# Wave annual return index data ####
#'-----------

#private repo - copying for the moment
#sf::st_read("https://github.com/Intertidal-Subtidal-WG/geospatial/raw/master/data/NACCS_wave_heights/wave_height_annual_return.kml")
library(sf)
wht_ari <- readRDS("data/NACCS_wave_heights/wh_art_data.RDS") %>%
  st_as_sf()

transects <- read_csv("data/transect_info.csv") %>%
  mutate(lat = measurements::conv_unit(
    paste(Lat_deg, Lat_min),
    from = 'deg_dec_min', to = 'dec_deg'
  ) %>% as.numeric,
  lon = measurements::conv_unit(
    paste(Long_deg, Long_min),
    from = 'deg_dec_min', to = 'dec_deg'
  ) %>% as.numeric %>% `*`(-1)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = st_crs(wht_ari))


wht_tran <- st_join(transects, wht_ari,
                    join = st_nearest_feature) %>%
  select(Transect, MEAN_WH_ARI_5, MEAN_WH_ARI_20, MEAN_WH_ARI_100,
         CL95_WH_ARI_5, CL95_WH_ARI_20, CL95_WH_ARI_100)

saveRDS(wht_tran, "wave_art.RDS")

#'-----------
# Wave Height data from 44005 ####
#'-----------

fix_bad_numbers <- function(x){
  x <- ifelse(is.nan(x), NA, x)
  x <- ifelse(is.infinite(x), NA, x)
  x
}

get_bdat <- function(ayear){
  dat <- buoy(year = ayear, buoyid = 44005, dataset = "stdmet") %>%
    `[[`("data")
  
  dat <- dat %>%  mutate(time = lubridate::ymd_hms(time),
                           date = lubridate::floor_date(time, "day")) %>%
    group_by(date) %>%
    summarize(mean_wave_height = mean(wave_height, na.rm=T),
              max_wave_height = max(wave_height, na.rm = T)) %>%
    mutate_if(is.numeric, fix_bad_numbers)
    
  #out!
  dat
}

bdat <- map_df(c(1982:2012, 2014:2020), get_bdat)

readr::write_csv(bdat, "data/waves_44005.csv")
# 
# library(ggplot2)
# bdat_long <- bdat %>%
#   tidyr::pivot_longer(c(mean_wave_height, max_wave_height),
#                       names_to = "type", values_to = "wave_height") 
# 
# ggplot(bdat_long, ggplot2::aes(x = date, y = wave_height, color = type)) +
#   geom_line() +
#   facet_wrap(~type, scale = "free_y")
# 
# 
# bdat_long %>%
#   group_by(date = lubridate::floor_date(date, "month"), type) %>%
#   summarize(wave_height = mean(wave_height, na.rm=TRUE)) %>%
#   ggplot(aes(x = date, y = wave_height, 
#              color = factor(lubridate::quarter(date)))) +
#   geom_line() +
#   facet_wrap(~type)
