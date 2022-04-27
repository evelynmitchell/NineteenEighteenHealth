#make_figure_1918_every_year.R
#feigenbaum
#21dec2021

# probably figure 1

library(tidyverse)
library(data.table)
# library(jjfPkg)
library(RColorBrewer)
library(spatstat)

# read the data
dt_main <-
  "data/prep_main.csv.gz" %>%
  fread() %>%
  group_by(year, race) %>%
  select(year, race, pop, inf_deaths_per_100k) %>%
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
  mutate(race_label = case_when(race == "white" ~ "White Death Rate",
                                race == "black" ~ "Nonwhite Death Rate",
                                race == "total" ~ "Total Death Rate"))

# colors
brewer_puor <- brewer.pal(4, "PuOr")

# function to graph inf deaths by race
make_figure <- function(measure_in) {

  white_flu <- dt_main %>% 
    filter(year == 1918) %>% 
    filter(race == "white") %>% 
    filter(measure == measure_in) %>%
    pull(deaths_per_100k)
  
  dt_main %>%
    filter(race != "total") %>%
    filter(measure == measure_in) %>%
    ggplot(aes(x = year, y = deaths_per_100k, 
               group = race_label, 
               color = race_label)) +
    geom_line(size = 1.5) +
    geom_hline(yintercept = white_flu, size = 1.25, linetype = "dashed") +
    scale_color_manual(values = c(brewer_puor[4], brewer_puor[1])) +
    xlab("Year") + ylab("Mortality Rate per 100,000") +
    theme_jjf_slides() +
    theme(text = element_text(size = 16)) +
    theme(legend.key.width = unit(1, "in")) +
    annotate("text", x = 1935, y = white_flu + 75, 
             label = "White 1918 Infectious Mortality Rate", family = "Roboto Condensed")

  # save it out
  ggsave(filename = "out/james/1918_every_year_{measure_in}.pdf" %>% str_glue(), 
         device = cairo_pdf, width = 10, height = 5, units = "in")

}

make_figure("median")
make_figure("weightedmedian")
make_figure("weightedmean")
