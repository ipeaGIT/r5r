FROM rocker/geospatial:latest

RUN install2.r --error --deps TRUE r5r

RUN Rscript -e "r5r::download_r5()"
