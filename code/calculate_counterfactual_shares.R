#calculate_counterfactual_shares.R
#feigenbaum
#11jan2022

# numbers to describe figure 3
# got in their own table

library(tidyverse)
library(data.table)
library(spatstat)
library(gt)
library(modelsummary)

# prep data ----

# read the data
dt_main <-
  "data/prep_main.csv.gz" %>%
  fread() %>%
  group_by(year, race) %>%
  filter(race != "total") %>%
  select(year, gnis, race, inf_deaths_per_100k, tb_deaths_per_100k, flu_deaths_per_100k, water_deaths_per_100k,
         measles_deaths_per_100k, whooping_cough_deaths_per_100k, diphtheria_deaths_per_100k,
         malaria_deaths_per_100k, puerperal_deaths_per_100k, bronchitis_deaths_per_100k,
         scarlet_fever_deaths_per_100k, syphilis_deaths_per_100k,
         pop)

dt_pops <- dt_main %>%
  select(year, gnis, race, pop)

dt_long <- dt_main %>%
  select(-pop) %>%
  pivot_longer(cols = ends_with("deaths_per_100k"), names_to = "cause", values_to = "deaths") %>%
  pivot_wider(id_cols = c("gnis", "year", "cause"), names_from = "race", values_from = "deaths")

dt_long_inf <- dt_long %>% 
  filter(cause == "inf_deaths_per_100k") %>% 
  select(year, gnis, inf_deaths_per_100k_black = black, inf_deaths_per_100k_white = white)

dt_counterfactual <- dt_long %>%
  #filter(cause != "inf_deaths_per_100k") %>%
  inner_join(dt_long_inf, by = c("year", "gnis")) %>%
  mutate(fixed = inf_deaths_per_100k_black - black + white) %>%
  select(-black, -white) %>%
  rename(black = inf_deaths_per_100k_black, white = inf_deaths_per_100k_white) %>%
  pivot_longer(cols = c("black", "white", "fixed"), names_to = "race", values_to = "deaths") %>%
  mutate(raw_fixed = case_when(race == "fixed" ~ "fixed",
                               TRUE ~ "raw")) %>%
  mutate(race = case_when(race == "fixed" ~ "black",
                          TRUE ~ race)) %>%
  full_join(dt_pops, by = c("year", "gnis", "race")) %>%
  group_by(year, cause, raw_fixed, race) %>%
  summarize(across(.cols = ends_with("deaths"),
                   list(median = ~ median(.x, na.rm = TRUE),
                        mean = ~ mean(.x, na.rm = TRUE),
                        weightedmean = ~ weighted.mean(.x, na.rm = TRUE, w = pop),
                        weightedmedian = ~ weighted.median(.x, w = pop, na.rm = TRUE)),
                   .names = "{.fn}")) %>%
  pivot_longer(cols = -c("year", "cause", "race", "raw_fixed"), names_to = "measure", values_to = "deaths") %>%
  mutate(race_type = str_c(race, "_", raw_fixed)) %>%
  ungroup() %>%
  select(-race, -raw_fixed) %>%
  pivot_wider(id_cols = c("year", "cause", "measure"), names_from = "race_type", values_from = "deaths") %>%
  mutate(fixed_share = 1 - (black_fixed - white_raw) / (black_raw - white_raw)) %>%
  mutate(cause = cause %>% str_extract("[a-z]+_") %>% str_remove("_")) %>%
  filter(cause != "inf")

# calculate mean, min, max % of disparity removed
fixed_shares <-
  dt_counterfactual %>%
  group_by(cause, measure) %>%
  summarize(mean_fixed = mean(fixed_share),
            median_fixed = median(fixed_share),
            max_fixed = max(fixed_share), 
            min_fixed = min(fixed_share)) %>%
  # clean up cause names
  mutate(cause = case_when(cause == "tb" ~ "Tuberculosis",
                           cause == "flu" ~ "Influenza/Pneumonia",
                           cause == "water" ~ "Waterborne/Foodborne",
                           cause == "whooping" ~ "Whooping Cough",
                           cause == "scarlet" ~ "Scarlet Fever", 
                           TRUE ~ str_to_title(cause)))

fixed_shares %>%
  filter(measure == "weightedmedian") %>%
  arrange(desc(mean_fixed)) %>%
  select(cause, mean_fixed, max_fixed) %>%
  ungroup() %>%
  gt() %>%
  fmt_number(
    columns = ends_with("fixed"),
    decimals = 1, 
    scale_by = 100
  ) %>%
  tab_spanner(label = "TITLE", columns = ends_with("fixed")) %>%
  cols_label(
    cause = "Adjusted Cause",
    mean_fixed = "Average",
    max_fixed = "Max"
  ) %>%
  as_latex() %>%
  # remove caption setup line
  str_remove("\\\\captionsetup.+?\n") %>%
  # swap longtable for tabular
  str_replace_all("longtable", "tabular") %>%
  # make the column spanner two rows
  str_replace("\\multicolumn.+\n",
              "\\multicolumn{2}{c}{Reduction in} \\\\\\\\ \n & \\\\multicolumn{2}{c}{Disparity (\\\\%)} \\\\\\\\ \n") %>%
  cat(file = "out/james/reduction_in_disparity_weightedmedian.tex")

# and weighted mean for the appendix?
fixed_shares %>%
  filter(measure == "weightedmean") %>%
  arrange(desc(mean_fixed)) %>%
  select(cause, mean_fixed, max_fixed) %>%
  ungroup() %>%
  gt() %>%
  fmt_number(
    columns = ends_with("fixed"),
    decimals = 1, 
    scale_by = 100
  ) %>%
  tab_spanner(label = "TITLE", columns = ends_with("fixed")) %>%
  cols_label(
    cause = "Adjusted Cause",
    mean_fixed = "Average",
    max_fixed = "Max"
  ) %>%
  as_latex() %>%
  # remove caption setup line
  str_remove("\\\\captionsetup.+?\n") %>%
  # swap longtable for tabular
  str_replace_all("longtable", "tabular") %>%
  # make the column spanner two rows
  str_replace("\\multicolumn.+\n",
              "\\multicolumn{2}{c}{Reduction in} \\\\\\\\ \n & \\\\multicolumn{2}{c}{Disparity (\\\\%)} \\\\\\\\ \n") %>%
  cat(file = "out/james/reduction_in_disparity_weightedmean.tex")
