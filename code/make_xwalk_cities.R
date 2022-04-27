#make_xwalk_cities.R
#feigenbaum
#2dec2021

# xwalk the cities from mortality data to the complete count data

library(tidyverse)
library(data.table)
library(rvest)
library(jsonlite)

# read the ipums city variable codes
city_codes <- read_html("https://usa.ipums.org/usa-action/variables/city#codes_section") %>% 
  html_text() %>% 
  str_extract(".*categor.*") %>%
  str_extract("\\[.*\\]") %>%
  fromJSON() %>%
  as_tibble() %>%
  filter(!is.na(code)) %>%
  select(city = code, label) %>%
  mutate(city = city %>% as.integer()) %>%
  separate(label, into = c("city_proper", "state"), sep = ",") %>%
  mutate(state = state %>% str_trim()) %>%
  filter(!is.na(state))

# read the state icpsr codes from ipums
state_codes <- 
  fread("data/state_icpsr_lookup.csv") %>%
  select(state, stateicp)

# read in the ipums cities list
dt_ipums <- 
  "data/city_xwalk/" %>%
  list.files(full.names = TRUE, pattern = "raw.*csv") %>%
  map_dfr(~ fread(.x) %>%
            .[, year := .x %>% str_extract("19..") %>% as.integer()]) %>%
  # state abbrev
  left_join(state_codes, by = "stateicp") %>%
  left_join(city_codes, by = c("city", "state")) %>%
  filter(!(city == 0 & stdcity == "")) %>%
  mutate(stdcity_title = stdcity %>% str_to_title())

# read the mortality cities
dt_mort <- 
  "data/cities_in_mortality_data.csv" %>%
  fread() %>%
  rename(city_mortality = city) %>%
  rename(n_mort = n) %>%
  filter(!is.na(gnis))

# is gnis unique?
dt_mort %>% summarize(n_distinct(gnis))
# yes

dt_mort_panel <- 
  expand_grid(gnis = dt_mort$gnis, year = seq(1900, 1940, by = 10)) %>%
  left_join(dt_mort, by = "gnis")

# first, does the mortality city match on city
dt_out_1 <- dt_mort_panel %>%
  inner_join(dt_ipums, by = c("city_mortality" = "city_proper", "state", "year")) %>%
  select(gnis, city, stdcity, year)

# second, does the mortality city match on stdcity
dt_out_2 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  inner_join(dt_ipums, by = c("city_mortality" = "stdcity_title", "state", "year")) %>%
  select(gnis, city, stdcity, year)

# some cities in mortality have "Saint" that should be "St."
# or other simple typos
dt_out_3 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Saint ", "St. ")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Sainte ", "Ste. ")) %>%
  mutate(city_mortality = str_replace(city_mortality, "LaPorte", "La Porte")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Plattsburgh", "Plattsburg")) %>%
  inner_join(dt_ipums, by = c("city_mortality" = "city_proper", "state", "year")) %>%
  select(gnis, city, stdcity, year)

dt_out_4 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Saint ", "St. ")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Du Bois", "Dubois")) %>%
  mutate(city_mortality = str_replace(city_mortality, "La Salle", "Lasalle")) %>%
  mutate(city_mortality = str_replace(city_mortality, "Plattsburgh", "Plattsburg")) %>%
  inner_join(dt_ipums, by = c("city_mortality" = "stdcity_title", "state", "year")) %>%
  select(gnis, city, stdcity, year)

# some cities have improper capitalization
dt_out_5 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  anti_join(dt_out_4, by = c("gnis", "year")) %>%
  mutate(city_mortality = str_to_title(city_mortality)) %>%
  inner_join(dt_ipums, by = c("city_mortality" = "city_proper", "state", "year")) %>%
  select(gnis, city, stdcity, year)

dt_out_6 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  anti_join(dt_out_4, by = c("gnis", "year")) %>%
  anti_join(dt_out_5, by = c("gnis", "year")) %>%
  mutate(city_mortality = str_to_title(city_mortality)) %>%
  inner_join(dt_ipums, by = c("city_mortality" = "stdcity_title", "state", "year")) %>%
  select(gnis, city, stdcity, year)

# random additional fixes
dt_out_7 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  anti_join(dt_out_4, by = c("gnis", "year")) %>%
  anti_join(dt_out_5, by = c("gnis", "year")) %>%
  anti_join(dt_out_6, by = c("gnis", "year")) %>%
  as.data.table() %>%
  .[city_mortality == "Warwick" & state == "RI", city_mortality := "Warwick Town"] %>%
  .[city_mortality == "Pennsauken" & state == "NJ", city_mortality := "Pensauken"] %>%
  .[city_mortality == "Gloucester City" & state == "NJ", city_mortality := "Gloucester"] %>%
  .[city_mortality == "Ventura" & state == "CA", city_mortality := "San Buenaventura (Ventura)"] %>%
  inner_join(dt_ipums, by = c("city_mortality" = "city_proper", "state", "year")) %>%
  select(gnis, city, stdcity, year)

dt_out_8 <- dt_mort_panel %>%
  # remove the joins we already made
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  anti_join(dt_out_4, by = c("gnis", "year")) %>%
  anti_join(dt_out_5, by = c("gnis", "year")) %>%
  anti_join(dt_out_6, by = c("gnis", "year")) %>%
  anti_join(dt_out_7, by = c("gnis", "year")) %>%
  as.data.table() %>%
  .[city_mortality == "South Saint Paul" & state == "MN", city_mortality := "South St. Paul City"] %>%
  .[city_mortality == "Kearny" & state == "NJ", city_mortality := "Kearney"] %>%
  inner_join(dt_ipums, by = c("city_mortality" = "stdcity_title", "state", "year")) %>%
  select(gnis, city, stdcity, year)

# what's left?
dt_mort_panel %>%
  anti_join(dt_out_1, by = c("gnis", "year")) %>%
  anti_join(dt_out_2, by = c("gnis", "year")) %>%
  anti_join(dt_out_3, by = c("gnis", "year")) %>%
  anti_join(dt_out_4, by = c("gnis", "year")) %>%
  anti_join(dt_out_5, by = c("gnis", "year")) %>%
  anti_join(dt_out_6, by = c("gnis", "year")) %>%
  anti_join(dt_out_7, by = c("gnis", "year")) %>%
  anti_join(dt_out_8, by = c("gnis", "year")) %>%
  mutate(min_decade = min_year %/% 10 * 10) %>%
  mutate(problem = (year >= min_decade & year <= max_year)) %>%
  filter(problem == TRUE & n_mort > 1) %>%
  filter(has_black == 1) %>%
  arrange(city_mortality, state, year) %>%
  write_csv(file = "data/city_xwalk/in_mort_not_in_ipums.csv")

# biggest ipums cities unmatched
dt_ipums %>%
  anti_join(dt_out_1, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_2, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_3, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_4, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_5, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_6, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_7, by = c("city", "stdcity", "year")) %>%
  anti_join(dt_out_8, by = c("city", "stdcity", "year")) %>%
  filter(state != "HI") %>%
  arrange(desc(n)) %>%
  head(20)

# final xwalk
dt_out <- 
  dt_mort_panel %>%
  left_join(bind_rows(dt_out_1, dt_out_2, dt_out_3, dt_out_4, 
                      dt_out_5, dt_out_6, dt_out_7, dt_out_8),
            by = c("gnis", "year")) %>%
  # deal with NYC boros
  # we have sep mortality data but we only see the Bronx in 1920+
  # so just combine NYC
  mutate(stdcity = case_when(
    state == "NY" & city_mortality %in% c("Bronx", "Brooklyn", "Manhattan", "Queens", "Richmond") ~ 
      str_to_upper(city_mortality),
    TRUE ~ stdcity)) %>%
  mutate(city = case_when(
    state == "NY" & city_mortality %in% c("Bronx", "Brooklyn", "Manhattan", "Queens", "Richmond") ~ 
      4610L,
    TRUE ~ city)) %>%
  # but the bronx is part of manhattan 
  select(gnis, year, state, city, stdcity)

dt_out %>% write_csv(file = "data/city_xwalk_out.csv")
