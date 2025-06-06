# Base image
FROM rocker/shiny:4.3.1

# General updates
# System dependencies for CRAN packages
RUN apt-get update && apt-get install -y \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libmagick++-dev \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /srv/shiny-server/

# Install the required packages
RUN Rscript -e 'install.packages(c("ggplot2", "dplyr", "tidyr", "readr", "svglite"), dependencies = TRUE)'

# Copy the app files (scripts, data, etc.)
RUN rm -rf /srv/shiny-server/*
COPY /app/ /srv/shiny-server/

# Ensure that the expected user is present in the container
RUN if id shiny &>/dev/null && [ "$(id -u shiny)" -ne 999 ]; then \
        userdel -r shiny; \
        id -u 999 &>/dev/null && userdel -r "$(id -un 999)"; \
    fi; \
    useradd -u 999 -m -s /bin/bash shiny; \
    chown -R shiny:shiny /srv/shiny-server/ /var/lib/shiny-server/ /var/log/shiny-server/

# Other settings
USER shiny
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
