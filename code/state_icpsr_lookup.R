#state_icpsr_lookup.R
#feigenbaum
#25mar2022

# need lookup between state names, state abbreviations, and state icpsr codes
# this is to avoid calling jjfPkg from github...

library(tidyverse)
library(data.table)
library(rvest)
library(jsonlite)

# read the state icpsr codes from ipums
state_codes <- 
  read_html("https://usa.ipums.org/usa-action/variables/stateicp#codes_section") %>% 
  html_text() %>% 
  str_extract(".*categor.*") %>%
  str_extract("\\[.*\\]") %>%
  fromJSON() %>%
  as_tibble() %>%
  filter(!is.na(code)) %>%
  select(stateicp = code, state = label) %>%
  mutate(stateicp = stateicp %>% as.integer()) %>%
  mutate(stateabb = if_else(stateicp == 98, "DC", state.abb[match(state, state.name)])) %>%
  filter(!is.na(stateabb)) %>%
  select(stateicp, state_proper = state, state = stateabb)

state_codes %>%
  fwrite("data/state_icpsr_lookup.csv")