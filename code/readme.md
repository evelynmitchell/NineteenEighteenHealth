# 1918 Every Year Replication Package

Overview
--------

The code in this replication package replicates the 1918 Every Year AEA P&P. It first builds the analysis data from two data sources, complete count census data from IPUMS (Ruggles et al, 2018) and digitized annual data from the historical Vital Statistics of the United States using R. It then produces all the figures and the one table in the paper. One master file (`master.R`) runs all of the code to generate the input data and then the 3 figures and 1 table in the paper. The replicator should expect the code to run for less than 10 minutes on CodeOcean.

Data Availability and Provenance Statements
----------------------------

### Statement about Rights

- [X] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 

### Summary of Availability

- [ ] All data **are** publicly available.
- [X] Some data **cannot be made** publicly available.
- [ ] **No data can be made** publicly available.

### Details on each Data Source

The project relies on two sources.

The first are the mortality data previously collected by these authors from the Vital Statistics of the United States annual volumes, 1906-1942. These are included as `data/final_deaths_city_cause_1900_1950.csv.gz` (gz to save space, `data.table::fread()` can read these directly).

The second are population denominators built from the IPUMS complete count data, 1900-1940. This is cited in the manuscript as Ruggles et al (2018). The version of this data used in this project is stored on the NBER Server and requires restricted access. However, we have included two intermediate outputs in the replication folder:

1. `city_xwalk`: lists of all unique cities (using the variables `city` and `stdcity` from IPUMS) by census year (1900 to 1940) in the complete count data. We use this to build a cross walk between the complete count data and the mortality data. Saved as `csv`s.
2. `pop_cells`: aggregate counts of people by age, sex, and race in each city in the complete count data by census year (1900 to 1940). Saved as `csv.gz`s to save space.

Any other data called by other code files are built in the pipeline.

Computational requirements
---------------------------

### Software Requirements

We use R 4.1.0. We use the following R packages, version numbers indicated (all are on CRAN and in the environment on CodeOcean):

- data.table 1.14.2
- gt 0.4.0
- jsonlite 1.8.0
- modelsummary 0.9.6
- rvest 1.0.2
- R.utils 2.11.0
- RColorBrewer 1.1-2
- spatstat 2.3-3
- tidyverse 1.3.1

#### Summary

Approximate time needed to reproduce the analyses on CodeOcean:

- [X] <10 minutes
- [ ] 10-60 minutes
- [ ] 1-8 hours
- [ ] 8-24 hours
- [ ] 1-3 days
- [ ] 3-14 days
- [ ] \>14 days
- [ ] Not feasible to run on a desktop machine, as described below.

#### Details

The code was last run on CodeOcean.

Description of programs/code
----------------------------

### License for Code

The code is licensed under a MIT/BSD/GPL/Creative Commons license.

### Instructions to Replicators

We include all source code to go from input data to prepared data to output. The `master.R` file will run everything that can run on codeocean to replicate from start to finish (except for two files that can only be run on the restricted access complete count census data stored on the NBER server).

All output is stored in a folder called `out/james`, but on codeocean, this directory is created in `run` and mapped to the `results` directory.

### Details

##### Data Prep

###### Crosswalk

- `state_icpsr_lookup.R`
    - create state abb to state icpsr lookup
- `prep_xwalks.R`
    - create cause xwalk and city xwalk from raw data

###### NBER Code

- `cities_from_ipums.R`
    - create list of cities in the complete count data on the NBER server
    - include code but obv this can't run here
- `pop_cells_from_ipums.R`
    - create pop denominator raw data on the NBER server
    - include code but obv this can't run here

###### Final Steps of Data Prep

- `make_xwalk_cities.R`
    - make final xwalk from cities in mort data to cities in IPUMS
- `make_mort_city_denoms.R`
    - make interpolated pop denominators
- `death_causes.R`
    - classify causes
- `prep_analysis_data.R`
    - make analysis data

##### Figures

- `theme_jjf_slides.R`
    - define my custom ggplot theme
- `make_figure_1918_every_year.R`
    - make figure 1 (and a bunch of appendix figures that look like figure 1)
    - figure 1 == 1918_every_year_weightedmedian.pdf
- `make_figure_cause_comparison.R`
    - make figure 2 (and a bunch of appendix figures that look like figure 2)
    - figure 2a == cause_by_race_rate_weightedmedian.pdf
    - figure 2b == cause_by_race_ratio_weightedmedian.pdf
- `make_figure_counterfactual_by_cause.R`
    - make figure 3 (and a bunch of appendix figures that look like figure 3)
    - figure 3a == cause_counterfactual_rates_weightedmedian.pdf
    - figure 3b == cause_counterfactual_ratios_weightedmedian.pdf

##### Table

- `calculate_counterfactual_shares.R`
    - make table 1
    - table 1 == reduction_in_disparity_weightedmedian.tex

List of tables and programs
---------------------------

The provided code reproduces:

- [ ] All numbers provided in text in the paper
- [X] All tables and figures in the paper
- [ ] Selected tables and figures in the paper, as explained and justified below.


| Figure/Table #    | Program                  | Output file                      |
|-------------------|--------------------------|----------------------------------|
| Table 1           | calculate_counterfactual_shares.R | reduction_in_disparity_weightedmedian.tex |
| Figure 1          | make_figure_1918_every_year.R | 1918_every_year_weightedmedian.pdf |
| Figure 2A         | make_figure_cause_comparison.R | cause_by_race_rate_weightedmedian.pdf |
| Figure 2B         | make_figure_cause_comparison.R | cause_by_race_ratio_weightedmedian.pdf |
| Figure 3A         | make_figure_counterfactual_by_cause.R | cause_counterfactual_rates_weightedmedian.pdf |
| Figure 3B         | make_figure_counterfactual_by_cause.R | cause_counterfactual_ratios_weightedmedian.pdf |

## References

Ruggles, Steven, Sarah Flood, Ronald Goeken, Josiah Grover, Erin Meyer, Jose Pacas, and Matthew Sobek. 2018. IPUMS USA: Version 8.0 [dataset]. Minneapolis, MN: IPUMS

---

