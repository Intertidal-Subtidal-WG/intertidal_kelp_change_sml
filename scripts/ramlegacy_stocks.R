library(ramlegacy)
library(dplyr)

#get the DB
download_ramlegacy()

#load some tables to get info on what we want
tabs <- load_ramlegacy(tables = c("stock", "bioparams"))

#let's see what's here!
stock <- tabs$stock %>%
  filter(scientificname %in%
           c("Homarus americanus",
             "Gadus morhua",
             "Strongylocentrotus droebachiensis")) %>%
  filter(region %in% c("US East Coast", "Canada East Coast")) %>%
  arrange(scientificname)

#OK, now that we have stocks, let's see get stockids from the bio parameters table
bioparams <- tabs$bioparams %>%
  filter(stocklong %in% stock$stocklong)

#LOBSTERGOM, CODGOM, GURCH4RST

ts <- load_ramlegacy(tables = "timeseries") %>%
  `[[`("timeseries") %>%
  filter(stockid %in% c("LOBSTERGOM", "CODGOM", "GURCH4RST"))

#Let's look at spawning stock of cod and lobsters in the GOM
ssb <- ts %>%
  filter(tsid == "SSB-MT")

library(ggplot2)
ggplot(ssb,
       aes(x = tsyear, y = tsvalue, color = stockid)) +
  geom_line()

#urchins in the Gulf of St. Lawrence
ts_urch <- ts %>%
  filter(stockid == "GURCH4RST")

ggplot(ts_urch,
       aes(x = tsyear, y = tsvalue, color = tsid)) +
  geom_line()
