library(RCurl)
library(stringr)
library(purrr)
# 
# WAVE 18 AWIPS Grid - Regional - US East Coast
# (longitude-latitude grid)(4 arc minute resolution)
# Filename	Inventory
# multi_1.at_4m.tCCz.fxxx.grib2
#http://www.nco.ncep.noaa.gov/pmb/products/wave/
#ftp://polar.ncep.noaa.gov/pub/history/waves

ftpserv <- "ftp://polar.ncep.noaa.gov/pub/history/waves/multi_1/"
dest_dir <- "data/ww3/"

yearmonths <- getURL(ftpserv,
                 verbose=TRUE,
                 ftp.use.epsv=FALSE,
                 dirlistonly = TRUE, crlf = TRUE) %>%
  strsplit("\n") %>%
  `[[`(1) %>%
  str_subset("^((?![a-zA-Z]).)*$") #get rid of anything not all digits


dirs <- yearmonths %>%
  paste0(ftpserv, ., "/gribs/")


get_multi_url <- function(.x){
  #start session
  curl <- getCurlHandle()
  
  ret <- getURL(.x,
         verbose=TRUE,
         ftp.use.epsv=FALSE,
         dirlistonly = TRUE, crlf = TRUE) %>%
    strsplit("\n") %>%
    `[[`(1) %>%
    str_subset("at_4m\\.hs")
  
  #end session
  rm(curl)
  gc()
  Sys.sleep(3)
  
  return(paste0(.x, ret))
}

#get the list of files to download
files_to_download <- map(dirs, get_multi_url) %>%
  unlist() %>%
  str_subset("grb2$")


#download the files themselves
download_waves <- function(url, wait_time = 5){
  filename <- str_remove_all(url, "^(.*)/")
  dest <- paste0(dest_dir, filename)
  download.file(url, dest, method = "wget")
  
  Sys.sleep(wait_time)
}


#load in and extract SML data

######

library(raster)
a <- brick(dest)
library(rNOMADS)
waves3 <- ReadGrib(dest, levels="surface", variables="HTSGW")

a <- terra::rast(dest)

library(stars)
library(dplyr)
s <- read_stars(dest)

s %>% slice(index = 225, along = "band") %>%
  plot()


####

#rsync --copy-unsafe-links -r -v jarrett.byrnes@gibbs.umb.edu:/shared/home/jarrett.byrnes/floating-forests/FF_deep_learning/data/mod_a/validation ./
