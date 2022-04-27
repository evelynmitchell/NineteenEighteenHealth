#prep_xwalks.R
#feigenbaum
#1nov2021

# read in the raw data from the old data collection project
# dump out the causes to categorize for Aja
# and the city xwalk

library(tidyverse)
library(data.table)

dt_total <- "data/final_deaths_city_cause_1900_1950.csv.gz" %>%
  fread()

# for cause xwalk
dt_total %>%
  group_by(cause) %>%
  summarize(min_year = min(year), max_year = max(year),
            n = n(), n_nonzero = sum(deaths != 0)) %>%
  fwrite(file = "data/death_causes_to_categorize.csv")

# for city xwalk to ipums data
dt_total %>%
  group_by(gnis, city, county, state) %>%
  summarize(min_year = min(year), max_year = max(year), n = n_distinct(year), 
            has_black = (sum(race == "black", na.rm = TRUE) > 0), 
            has_white = (sum(race == "white", na.rm = TRUE) > 0),
            has_total = (sum(is.na(race)) > 0)) %>%
  # convert lgls to integers
  mutate(across(starts_with("has_"), ~ as.integer(.x))) %>%
  arrange(state, city) %>%
  fwrite(file = "data/cities_in_mortality_data.csv")
