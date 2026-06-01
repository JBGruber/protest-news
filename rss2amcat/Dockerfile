FROM rocker/tidyverse:latest

# Install packages
RUN R -q -e 'install.packages(c("DBI", "dplyr", "dbplyr", "library", "stringr"))'
RUN R -e "pak::pak('ccs-amsterdam/amcat4r')"
# Copy the R script
COPY rss2amcat.r /app/

# Set working directory
WORKDIR /app

# Run the R script
CMD ["Rscript", "rss2amcat.r"]
