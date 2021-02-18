FROM rocker/geospatial:latest

RUN install2.r --error --deps TRUE r5r
