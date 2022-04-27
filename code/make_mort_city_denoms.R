#make_mort_city_denoms.R
#feigenbaum
#2dec2021

# generate population denominators for mortality cities

library(tidyverse)
library(data.table)

# read the state icpsr codes from ipums
state_codes <- 
  fread("data/state_icpsr_lookup.csv") %>%
  select(state, stateicp)

# read city xwalk
dt_mort_cities <- "data/city_xwalk_out.csv" %>%
  fread() %>%
  setkey(year, state, city, stdcity) %>%
  # deal with NYC
  .[is.na(city) | city != 4610 | (city == 4610 & gnis == 975772)] %>%
  .[gnis == 975772, stdcity := "NEW YORK"]

dt_pop_cells <- "data/pop_cells" %>%
  list.files(pattern = "age_sex_race.*.csv.gz", full.names = TRUE) %>%
  map_dfr(~ fread(.x) %>%
            .[!(city == 0 & stdcity == "")] %>%
            .[, year := .x %>% str_extract("19..") %>% as.integer()]) %>%
  # deal w NYC
  .[city == 4610, stdcity := "NEW YORK"]

# total pop, white pop, nonwhite pop, black pop
dt_denoms <- 
  dt_pop_cells %>%
  .[, .(total = sum(n), white = sum((race == 1) * n),
        black = sum((race == 2) * n), nonwhite = sum((race != 1) * n),
        total_under5 = sum((age < 5) * n),
        white_under5 = sum((age < 5) * (race == 1) * n),
        black_under5 = sum((age < 5) * (race == 2) * n),
        nonwhite_under5 = sum((age < 5) * (race != 1) * n)),
    by = list(city, stdcity, stateicp, year)] %>%
  merge(state_codes, by = "stateicp") %>%
  setkey(year, state, city, stdcity)

dt_pops <- dt_mort_cities %>%
  merge(dt_denoms, by = c("year", "state", "city", "stdcity"), all.x = TRUE) %>%
  group_by(year, state, gnis) %>%
  summarize(across(.cols = c("total", "white", "black", "nonwhite",
                             "total_under5", "white_under5", 
                             "black_under5", "nonwhite_under5"), ~ sum(.x)))

# log-interpolate and extrapolate
dt_pops_ipo <-
  dt_pops %>%
  pivot_longer(cols = total:nonwhite_under5, names_to = "group", values_to = "pop") %>%
  as.data.table() %>%
  .[!is.na(pop)] %>%
  .[, n := .N, by = list(state, gnis, group)] %>%
  .[n > 1, approx(x = year, y = log(pop), xout = 1900:1950, rule = 2), 
    by = list(state, gnis, group)] %>%
  .[, pop := exp(y)] %>%
  .[, year := x] %>%
  select(-x, -y) %>%
  .[, pop := round(pop) %>% as.integer()] %>%
  pivot_wider(id_cols = c("state", "gnis", "year"), names_from = group, values_from = pop)

# save this out
dt_pops_ipo %>%
  fwrite(file = "data/ipo_denominators.csv")
