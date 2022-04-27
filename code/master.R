print(Sys.time())

## data prep ##

# create state abb to state icpsr lookup
source("state_icpsr_lookup.R", echo = TRUE)

# create cause xwalk and city xwalk from raw data
source("prep_xwalks.R", echo = TRUE)

# create list of cities in the complete count data on the NBER server
# include code but obv this can't run here
# source("cities_from_ipums.R", echo = TRUE)

# create pop denominator raw data on the NBER server
# include code but obv this can't run here
# source("pop_cells_from_ipums.R", echo = TRUE)

# make final xwalk from cities in mort data to cities in IPUMS
source("make_xwalk_cities.R", echo = TRUE)

# make interpolated pop denominators
source("make_mort_city_denoms.R", echo = TRUE)

# classify causes
source("death_causes.R", echo = TRUE)

# make analysis data
source("prep_analysis_data.R", echo = TRUE)

## figures ##

# define my custom ggplot theme
source("theme_jjf_slides.R", echo = TRUE)

# make figure 1 (and a bunch of appendix figures that look like figure 1)
source("make_figure_1918_every_year.R", echo = TRUE)
# figure 1 == 1918_every_year_weightedmedian.pdf

# make figure 2 (and a bunch of appendix figures that look like figure 2)
source("make_figure_cause_comparison.R", echo = TRUE)
# figure 2a == cause_by_race_rate_weightedmedian.pdf
# figure 2b == cause_by_race_ratio_weightedmedian.pdf

# make figure 3 (and a bunch of appendix figures that look like figure 3)
source("make_figure_counterfactual_by_cause.R", echo = TRUE)
# figure 3a == cause_counterfactual_rates_weightedmedian.pdf
# figure 3b == cause_counterfactual_ratios_weightedmedian.pdf

## tables ##

# make table 1
source("calculate_counterfactual_shares.R", echo = TRUE)
# table 1 == reduction_in_disparity_weightedmedian.tex

