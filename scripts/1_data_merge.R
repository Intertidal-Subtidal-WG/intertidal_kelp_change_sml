#'------------------------------------------------------------
#' Combine Data Sources for Analysis
#'------------------------------------------------------------

library(readr)
library(dplyr)
library(tidyr)

#'---------------------------------------------------------------------
## read in the original data and pull out urchins, kelps, corraline
## bare space, total fleshy algal cover, total invert cover
#'---------------------------------------------------------------------

#lower intertidal
sml_int <- readRDS("data/combined_intertidal_abundance.RDS") %>%
  filter(TIDE_HEIGHT_REL_MLLW < 2) %>%  #to try it out - sems to capture almost all
  group_by(YEAR, ORGANISM, PROTOCOL, 
           INTERTIDAL_TRANSECT, SITE, 
           TIDE_HEIGHT_REL_MLLW, TYPE, SUBTYPE) %>%
  summarize(VALUE = sum(VALUE))

#urchins and kelp first
wide_dat <- sml_int %>%
  filter(ORGANISM %in%
           c("Saccharina latissima", 
             "Alaria esculenta", 
             "Strongylocentrotus droebachiensis")) %>%
  pivot_wider(names_from = ORGANISM, 
              values_from = VALUE)

#Crusts and Fleshy Algae
sml_int_aggregate <- sml_int %>%
  filter(!(ORGANISM %in%
           c("Saccharina latissima", 
             "Alaria esculenta", 
             "Strongylocentrotus droebachiensis"))) %>%
  filter(PROTOCOL == "Intertidal_Cover") %>%
  group_by(YEAR, INTERTIDAL_TRANSECT, SITE, 
           TIDE_HEIGHT_REL_MLLW, TYPE, SUBTYPE) %>%
  summarize(VALUE = sum(VALUE)) %>%
  ungroup() %>%
  pivot_wider(names_from = SUBTYPE, values_from = VALUE) %>%
  group_by(YEAR, INTERTIDAL_TRANSECT, SITE, 
           TIDE_HEIGHT_REL_MLLW) %>%
  mutate(FLESHY_ALGAE = sum(`Erect Brown Alage`,
                            `Erect Red Algae`,
                            `Green Algae`),
         INVERTS = sum(Bryozoan, Worm, Anthozoan, Hydrozoan, 
                       Sponge, Tunicate, Crustacean, Worm),
         CORRALINE = `Red Algal Crust`) %>%
  ungroup()


bare_space <- sml_int %>%
  filter(ORGANISM %in% c("Bare rock", "Brown ground", "Shell hash")) %>%
  pivot_wider(names_from = ORGANISM, values_from = VALUE) %>%
  mutate(BARE_SPACE = sum(`Bare rock`, `Brown ground`, `Shell hash`))


wide_dat <- wide_dat %>%
  left_join(sml_int_aggregate %>%
              select(YEAR, INTERTIDAL_TRANSECT, SITE, 
                     TIDE_HEIGHT_REL_MLLW, FLESHY_ALGAE, INVERTS, 
                     CORRALINE)) %>%
  left_join(bare_space %>%
              select(YEAR, INTERTIDAL_TRANSECT, SITE, 
                     TIDE_HEIGHT_REL_MLLW,  BARE_SPACE))

#'---------------------------------------------------------------------
## merge in transect info
#'---------------------------------------------------------------------

#'---------------------------------------------------------------------
## merge in catch datasets
#'---------------------------------------------------------------------

#'---------------------------------------------------------------------
## merge in mean summer temps
#'---------------------------------------------------------------------

#'---------------------------------------------------------------------
## merge in wave ARI
#'---------------------------------------------------------------------

#'---------------------------------------------------------------------
# merge in Jan-May mean wave height
#'---------------------------------------------------------------------

#'---------------------------------------------------------------------
# filter out 2012 b/c no wave data
#'---------------------------------------------------------------------
