FROM rocker/rstudio

COPY . .

RUN install2.R r5r