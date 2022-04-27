#prep_analysis_data.R
#feigenbaum
#2dec2021

# read death data
# read the cause categories
# read the denominators
# put things together

library(tidyverse)
library(data.table)

# deaths 
dt_deaths <- 
  "data/final_deaths_city_cause_1900_1950.csv.gz" %>% 
  fread() %>%
  setkey(gnis, state, year, race) %>%
  .[!is.na(gnis)] %>%
  .[race == "", race := "total"]

# causes
dt_causes <- "data/death_causes_out.csv" %>%
  fread()

# denominators
dt_denoms <- "data/ipo_denominators.csv" %>%
  fread() %>%
  pivot_longer(cols = total:nonwhite, names_to = "race", values_to = "pop") %>%
  # drop black and rename nonwhite to black to match death data
  filter(race != "black") %>%
  mutate(race = if_else(race == "nonwhite", "black", race))

# region coding
dt_regions <- 
  dt_denoms %>%
  count(state) %>%
  # attach census region
  mutate(region = state.region[match(state, state.abb)] %>% as.character()) %>%
  # fix DC and convert North Central to Midwest
  mutate(region = case_when(state == "DC" ~ "South",
                            region == "North Central" ~ "Midwest",
                            TRUE ~ region)) %>%
  # set up region order
  mutate(region_order = case_when(region == "Northeast" ~ 1L,
                                  region == "Midwest" ~ 2L,
                                  region == "West" ~ 3L,
                                  region == "South" ~ 4L)) %>%
  select(state, region, region_order)

dt_out <- 
  dt_deaths %>%
  # merge on categories 
  merge(dt_causes, by = c("cause")) %>%
  # remove cardio double counting in 1949-1950
  filter(!(cardio_double == TRUE & year %in% 1949:1950)) %>%
  # keep unknown last because it is used below in the across
  .[, .(total = sum(deaths * (total == TRUE)), 
        inf = sum(deaths * (inf == TRUE)),
        noninf = sum(deaths * (non_inf == TRUE)),
        tb = sum(deaths * (tb == TRUE)),
        flu = sum(deaths * (flu_pneumonia == TRUE)),
        water = sum(deaths * (water == TRUE)),
        kid = sum(deaths * (kid == TRUE)),
        other = sum(deaths * (other == TRUE)),
        measles = sum(deaths * (measles == TRUE)),  
        whooping_cough = sum(deaths * (whooping_cough == TRUE)),  
        diphtheria = sum(deaths * (diphtheria == TRUE)),  
        malaria = sum(deaths * (malaria == TRUE)),  
        puerperal = sum(deaths * (puerperal == TRUE)),
        bronchitis = sum(deaths * (bronchitis == TRUE)),  
        scarlet_fever = sum(deaths * (scarlet_fever == TRUE)),  
        syphilis = sum(deaths * (syphilis == TRUE)),
        unknown = sum(deaths * (unknown == TRUE))),
    by = list(gnis, city, state, year, race)] %>%
  setkey(gnis, state, year, race) %>%
  merge(dt_denoms, by = c("gnis", "state", "year", "race")) %>%
  mutate(across(.cols = total:unknown, 
                ~ 1e5 * .x / pop, 
                .names = "{.col}_deaths_per_100k")) %>%
  # attach census region
  merge(dt_regions, by = "state") %>%
  arrange(year, state, gnis, race)

# save this out
dt_out %>%
  fwrite("data/prep_main.csv.gz")
