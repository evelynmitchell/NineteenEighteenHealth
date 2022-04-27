#make_figure_counterfactual_by_cause.R
#feigenbaum
#21dec2021

# probably figure 3

library(tidyverse)
library(data.table)
# library(jjfPkg)
library(RColorBrewer)
library(spatstat)

# prep data ----

# read the data
dt_main <-
  "data/prep_main.csv.gz" %>%
  fread() %>%
  group_by(year, race) %>%
  filter(race != "total") %>%
  select(year, gnis, race, inf_deaths_per_100k, tb_deaths_per_100k, flu_deaths_per_100k, water_deaths_per_100k, pop)
  
dt_pops <- dt_main %>%
  select(year, gnis, race, pop)

dt_counterfactual <- dt_main %>%
  pivot_wider(id_cols = c("gnis", "year"), names_from = "race", 
              values_from = ends_with("deaths_per_100k")) %>%
  mutate(inf_fixtb_deaths_per_100k_black = inf_deaths_per_100k_black - tb_deaths_per_100k_black + tb_deaths_per_100k_white) %>%
  mutate(inf_fixflu_deaths_per_100k_black = inf_deaths_per_100k_black - flu_deaths_per_100k_black + flu_deaths_per_100k_white) %>%
  mutate(inf_fixwater_deaths_per_100k_black = inf_deaths_per_100k_black - water_deaths_per_100k_black + water_deaths_per_100k_white) %>%
  pivot_longer(cols = matches("_deaths_per_100k"), names_to = "cause_race", values_to = "deaths_per_100k") %>%
  mutate(race = str_sub(cause_race, -5)) %>%
  group_by(year, cause_race) %>%
  full_join(dt_pops, by = c("year", "gnis", "race")) %>%
  summarize(across(.cols = ends_with("deaths_per_100k"),
                   list(median = ~ median(.x, na.rm = TRUE),
                      mean = ~ mean(.x, na.rm = TRUE),
                      weightedmean = ~ weighted.mean(.x, na.rm = TRUE, w = pop),
                      weightedmedian = ~ weighted.median(.x, w = pop, na.rm = TRUE)),
                 .names = "{.fn}")) %>%
  pivot_longer(cols = -c("year", "cause_race"), names_to = "measure", values_to = "deaths")

## colors ----
brewer_puor <- brewer.pal(4, "PuOr")
brewer_purple <- brewer.pal(5, "Purples")
brewer_orange <- brewer.pal(5, "Oranges")

# functions to plot

## plot raw mortality rates ----
make_rate_figure <- function(measure_in) {

  white_flu <- dt_counterfactual %>% 
    filter(measure == measure_in) %>%
    filter(year == 1918) %>% 
    filter(cause_race == "inf_deaths_per_100k_white") %>% 
    pull(deaths)
  
  dt_counterfactual %>%
    filter(measure == measure_in) %>%
    filter(cause_race %in% c("inf_deaths_per_100k_white", "inf_deaths_per_100k_black",
                             "inf_fixflu_deaths_per_100k_black", "inf_fixtb_deaths_per_100k_black", 
                             "inf_fixwater_deaths_per_100k_black")) %>%
    # clean up variable labels
    mutate(cause_race_label = case_when(cause_race == "inf_deaths_per_100k_white" ~ "White",
                                        cause_race == "inf_deaths_per_100k_black" ~ "Nonwhite",
                                        cause_race == "inf_fixflu_deaths_per_100k_black" ~ "Adjust Flu Deaths",
                                        cause_race == "inf_fixtb_deaths_per_100k_black" ~ "Adjust TB Deaths",
                                        cause_race == "inf_fixwater_deaths_per_100k_black" ~ "Adjust Water Deaths")) %>%
    # ordering
    mutate(cause_race_order = case_when(cause_race == "inf_deaths_per_100k_white" ~ 5L,
                                        cause_race == "inf_deaths_per_100k_black" ~ 1L,
                                        cause_race == "inf_fixflu_deaths_per_100k_black" ~ 2L,
                                        cause_race == "inf_fixtb_deaths_per_100k_black" ~ 3L,
                                        cause_race == "inf_fixwater_deaths_per_100k_black" ~ 4L)) %>%
    ggplot(aes(x = year, y = deaths, group = cause_race_label, 
               color = cause_race_label %>% fct_reorder(cause_race_order), 
               linetype = cause_race_label %>% fct_reorder(cause_race_order))) +
    geom_line(size = 1.5) +
    geom_hline(yintercept = white_flu, size = 1.25, linetype = "dashed") +
    scale_color_manual(values = c(brewer_puor[4], brewer_purple[4], brewer_purple[3], brewer_purple[2],
                                  brewer_puor[1]),
                       guide = guide_legend(byrow = TRUE, ncol = 3)) +
    scale_linetype_manual(values = c("solid", "longdash", "dotted", "dashed", "solid")) +
    xlab("Year") + ylab("Mortality Rate per 100,000") +
    theme_jjf_slides() +
    theme(text = element_text(size = 16)) +
    theme(legend.key.width = unit(1, "in")) +
    annotate("text", x = 1935, y = white_flu + 75, 
             label = "White 1918 Infectious Mortality Rate", family = "Roboto Condensed")
  
  # save it out
  ggsave(filename = "out/james/cause_counterfactual_rates_{measure_in}.pdf" %>% str_glue(), 
         device = cairo_pdf, width = 8, height = 4, units = "in")

}

## plot mortality ratios ----
make_ratio_figure <- function(measure_in) {
  
  dt_counterfactual %>%
    filter(measure == measure_in) %>%
    mutate(inf_deaths_per_100k_white = max((cause_race == "inf_deaths_per_100k_white") * (deaths))) %>%
    mutate(ratio = deaths / inf_deaths_per_100k_white) %>%
    filter(cause_race %in% c("inf_deaths_per_100k_black", "inf_fixwater_deaths_per_100k_black",
                             "inf_fixflu_deaths_per_100k_black", "inf_fixtb_deaths_per_100k_black")) %>%
    # clean up variable labels
    mutate(cause_race_label = case_when(cause_race == "inf_deaths_per_100k_white" ~ "White",
                                        cause_race == "inf_deaths_per_100k_black" ~ "Nonwhite",
                                        cause_race == "inf_fixflu_deaths_per_100k_black" ~ "Adjust Flu Deaths",
                                        cause_race == "inf_fixtb_deaths_per_100k_black" ~ "Adjust TB Deaths",
                                        cause_race == "inf_fixwater_deaths_per_100k_black" ~ "Adjust Water Deaths")) %>%
    # ordering
    mutate(cause_race_order = case_when(cause_race == "inf_deaths_per_100k_white" ~ 5L,
                                        cause_race == "inf_deaths_per_100k_black" ~ 1L,
                                        cause_race == "inf_fixflu_deaths_per_100k_black" ~ 2L,
                                        cause_race == "inf_fixtb_deaths_per_100k_black" ~ 3L,
                                        cause_race == "inf_fixwater_deaths_per_100k_black" ~ 4L)) %>%  
    ggplot(aes(x = year, y = ratio, group = cause_race_label, 
               color = cause_race_label %>% fct_reorder(cause_race_order), 
               linetype = cause_race_label %>% fct_reorder(cause_race_order))) +
    geom_line(size = 1.5) +
    scale_color_manual(values = c(brewer_purple[5], brewer_purple[4], brewer_purple[3], brewer_purple[2]),
                       guide = guide_legend(byrow = TRUE, nrow = 2)) +
    scale_linetype_manual(values = c("solid", "longdash", "dotted", "dashed")) +
    # scale_y_continuous(limits = c(1, 2.55)) +
    expand_limits(y = 1) +
    xlab("Year") + ylab("Relative to White Infectious\n Mortality Rate") +
    theme_jjf_slides() +
    theme(text = element_text(size = 16)) +
    theme(legend.key.width = unit(1, "in"))

  # save it out
  ggsave(filename = "out/james/cause_counterfactual_ratios_{measure_in}.pdf" %>% str_glue(), 
         device = cairo_pdf, width = 8, height = 4, units = "in")

}

# output figures ----

make_rate_figure("median")
make_rate_figure("weightedmedian")
make_rate_figure("weightedmean")

make_ratio_figure("median")
make_ratio_figure("weightedmedian")
make_ratio_figure("weightedmean")
