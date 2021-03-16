#'------------------------------------------------------------
#' Combine Data Sources for Analysis
#'------------------------------------------------------------

library(readr)
library(dplyr)
library(tidyr)


# read in the original data and pull out urchins, kelps, corraline
# bare space, total fleshy algal cover, total invert cover
sml_int <- readRDS("data/combined_intertidal_abundance.RDS")

# merge in transect info

# merge in catch datasets

# merge in mean summer temps

# merge in wave ARI

# merge in Jan-May mean wave height

# filter out 2012 b/c no wave data