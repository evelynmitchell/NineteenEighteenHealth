#make_figure_cause_comparison.R
#feigenbaum
#30dec2021

# probably figure 2

library(tidyverse)
library(data.table)
# library(jjfPkg)
library(RColorBrewer)
library(spatstat)

# prep data ----

## read the data ----
dt_raw <-
  "data/prep_main.csv.gz" %>%
  fread()

## prepare the data with medians, means, weights, etc ----
dt_main <- 
  dt_raw %>%
  group_by(year, race) %>%
  select(year, race, pop, 
         tb_deaths_per_100k, flu_deaths_per_100k, water_deaths_per_100k) %>%
  # four city-years report a handful of black deaths while having zero black population
  # make these na
  mutate(across(.cols = ends_with("_deaths_per_100k"),
                ~ if_else(is.infinite(.x), NA_real_, .x))) %>%
  summarize(across(.cols = ends_with("_deaths_per_100k"),
                   list(median = ~ median(.x, na.rm = TRUE),
                        mean = ~ mean(.x, na.rm = TRUE),
                        weightedmean = ~ weighted.mean(.x, na.rm = TRUE, w = pop),
                        weightedmedian = ~ weighted.median(.x, w = pop, na.rm = TRUE)),
                   .names = "{.fn}_{.col}"),
            n = n()) %>%
  filter(year <= 1948) %>%
  pivot_longer(cols = -c(year, race, n), values_to = "deaths_per_100k") %>%
  mutate(name = name %>% str_remove("_deaths_per_100k")) %>%
  separate(name, into = c("measure", "cause"), sep = "_") %>%
  # proper labels on race
  mutate(race_label = case_when(race == "white" ~ "White",
                                race == "black" ~ "Nonwhite",
                                race == "total" ~ "Total")) %>%
  # proper labels on cause
  mutate(cause_label = case_when(cause == "flu" ~ "Flu",
                                 cause == "tb" ~ "TB",
                                 cause == "water" ~ "Water")) %>%
  # never actually use n and it causes problems because it can vary by race
  select(-n)

## prepare data with ratio as well ----
dt_ratios <-
  dt_main %>%
  filter(race != "total") %>%
  select(-race_label) %>%
  pivot_wider(id_cols = c("year", "measure", "cause", "cause_label"), 
              values_from = deaths_per_100k, names_from = race) %>%
  mutate(ratio = black / white)

## colors ----
brewer_puor <- brewer.pal(4, "PuOr")
brewer_purple <- brewer.pal(5, "Purples")
brewer_orange <- brewer.pal(5, "Oranges")

# functions to graph categories of inf deaths ----

make_rate_figure <- function(measure_in) {
  
  dt_main %>%
    filter(race != "total") %>%
    filter(measure == measure_in) %>%
    ggplot(aes(x = year, y = deaths_per_100k, 
               group = interaction(cause_label, race_label, sep = " "), 
               color = interaction(cause_label, race_label, sep = " "),
               linetype = interaction(cause_label, race_label, sep = " "))) +
    geom_line(size = 1.5) +
    scale_color_manual(values = c(brewer_purple[4], brewer_purple[3], brewer_purple[2],
                                  brewer_orange[4], brewer_orange[3], brewer_orange[2]), 
                       guide = guide_legend(byrow = TRUE)) +
    scale_linetype_manual(values = c("longdash", "dotted", "dashed",
                                     "longdash", "dotted", "dashed")) +
    xlab("Year") + ylab("Mortality Rate per 100,000") +
    theme_jjf_slides() +
    theme(text = element_text(size = 16)) +
    theme(legend.key.width = unit(1, "in"))
  
  # save it out
  ggsave(filename = "out/james/cause_by_race_rate_{measure_in}.pdf" %>% str_glue(), 
         device = cairo_pdf, width = 8, height = 4, units = "in")

}

make_ratio_figure <- function(measure_in) {
  
  dt_ratios %>%
    filter(measure == measure_in) %>%
    ggplot(aes(x = year, y = ratio, 
               group = cause_label, 
               color = cause_label,
               linetype = cause_label)) +
    geom_line(size = 1.5) +
    scale_color_manual(values = c(brewer_purple[4], brewer_purple[3], brewer_purple[2]), 
                       guide = guide_legend(byrow = TRUE)) +
    scale_linetype_manual(values = c("longdash", "dotted", "dashed")) +
    xlab("Year") + ylab("Relative to White\n Mortality Rate") +
    expand_limits(y = 1) +
    theme_jjf_slides() +
    theme(text = element_text(size = 16)) +
    theme(legend.key.width = unit(1, "in"))
  
  # save it out
  ggsave(filename = "out/james/cause_by_race_ratio_{measure_in}.pdf" %>% str_glue(), 
         device = cairo_pdf, width = 8, height = 4, units = "in")
  
}

# output figures ----

make_rate_figure("median")
make_rate_figure("weightedmedian")
make_rate_figure("weightedmean")

make_ratio_figure("median")
make_ratio_figure("weightedmedian")
make_ratio_figure("weightedmean")
