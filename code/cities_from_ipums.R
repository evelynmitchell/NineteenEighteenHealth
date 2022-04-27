#cities_from_ipums.R
#feigenbaum
#2dec2021

# read the cities (city and stdcity) from the complete count data
# 1900-1940

# NB: this runs on the NBER server

library(tidyverse)
library(data.table)

path_census <- "/home/data/census-ipums"

census_vars <- c("city", "stdcity", "stateicp")

ys <- seq(1900L, 1940L, by = 10L)

for (y in ys) {
  
  print(y)
  
  dt_raw <- "{path_census}/current/csv/{y}.csv" %>%
    str_glue() %>%
    fread(select = census_vars) %>%
    .[, .(n = .N), by = list(city, stdcity, stateicp)]
  
  dt_raw %>% 
    fwrite(file = "data/city_xwalk/raw_{y}.csv" %>% str_glue())

}
