# syntax=docker/dockerfile:1
FROM rocker/r-ver:4.4.2

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        gdal-bin \
        libgdal-dev \
        libproj-dev \
        proj-bin \
        libgeos-dev \
        libudunits2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('RestRserve','data.table','terra','readr','jsonlite'), repos='https://cloud.r-project.org')"

# Install ClimateNAr from the local repo (upstream zip requires auth).
# This repo is already in an installed package layout, so we copy it directly
# into the site-library instead of running R CMD INSTALL on source.
RUN mkdir -p /usr/local/lib/R/site-library/ClimateNAr
COPY DESCRIPTION NAMESPACE INDEX README.md /usr/local/lib/R/site-library/ClimateNAr/
COPY R /usr/local/lib/R/site-library/ClimateNAr/R
COPY data /usr/local/lib/R/site-library/ClimateNAr/data
COPY help /usr/local/lib/R/site-library/ClimateNAr/help
COPY Meta /usr/local/lib/R/site-library/ClimateNAr/Meta
COPY html /usr/local/lib/R/site-library/ClimateNAr/html

COPY climatenar /srv/app
WORKDIR /srv/app

ENV PORT=8000
EXPOSE 8000

CMD ["Rscript", "/srv/app/app.R"]
