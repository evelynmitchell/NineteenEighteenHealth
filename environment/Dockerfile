# hash:sha256:fde549b28258a53bea5c90ca7ff9f7ad47d0fa7b433348e513213188274aeaa3
FROM registry.codeocean.com/codeocean/r-studio:1.4.1106-r4.0.5-ubuntu18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN Rscript -e 'remotes::install_version("R.utils", "2.11.0")' \
    && Rscript -e 'remotes::install_version("RColorBrewer", "1.1-2")' \
    && Rscript -e 'remotes::install_version("data.table", "1.14.2")' \
    && Rscript -e 'remotes::install_version("gt", "0.4.0")' \
    && Rscript -e 'remotes::install_version("jsonlite", "1.8.0")' \
    && Rscript -e 'remotes::install_version("modelsummary", "0.9.6")' \
    && Rscript -e 'remotes::install_version("rvest", "1.0.2")' \
    && Rscript -e 'remotes::install_version("spatstat", "2.3-3")' \
    && Rscript -e 'remotes::install_version("tidyverse", "1.3.1")'
