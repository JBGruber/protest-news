FROM rocker/tidyverse:latest

# Install packages
RUN R -q -e 'install.packages(c("dplyr", "pak"))'
RUN R -e "pak::pak('ccs-amsterdam/amcat4r')"
# Copy the R script
COPY paperboy.r /app/

# Set working directory
WORKDIR /app

# Run the R script
CMD ["Rscript", "paperboy.r"]
