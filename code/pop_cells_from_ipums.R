#pop_cells_from_ipums.R
#feigenbaum
#2dec2021

# count the number of people in each age x sex x race cell 
# from the complete count data
# 1900-1940
# for each stdcity x city x county

# NB: this runs on the NBER server

library(tidyverse)
library(data.table)

path_census <- "/home/data/census-ipums"

# countyicp and county are the same thing...
census_vars <- c("city", "stdcity", "countyicp", "county", "stateicp",
                 "age", "sex", "race")

ys <- seq(1900L, 1940L, by = 10L)

for (y in ys) {
  
  print(y)
  
  dt_raw <- "{path_census}/current/csv/{y}.csv" %>%
    str_glue() %>%
    fread(select = census_vars) %>%
    setnames("county", "countyicp", skip_absent = TRUE) %>%
    # simplify race
    .[, race := race %/% 100] %>%
    # nyc boros
    .[stateicp == 13 & countyicp == 50, stdcity := "BRONX"] %>%
    .[stateicp == 13 & countyicp == 470, stdcity := "BROOKLYN"] %>%
    .[stateicp == 13 & countyicp == 610, stdcity := "MANHATTAN"] %>%
    .[stateicp == 13 & countyicp == 810, stdcity := "QUEENS"] %>%
    .[stateicp == 13 & countyicp == 850, stdcity := "RICHMOND"] %>%
    .[, .(n = .N), by = list(city, stdcity, stateicp, age, sex, race)]
  
  dt_raw %>% 
    fwrite(file = "data/pop_cells/age_sex_race_{y}.csv.gz" %>% str_glue())
  
}
