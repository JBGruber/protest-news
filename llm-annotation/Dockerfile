FROM rocker/tidyverse:latest

# Install packages
RUN R -q -e 'install.packages(c("dplyr", "rollama", "here", "readr", "purrr"))'
RUN R -e "pak::pak('ccs-amsterdam/amcat4r')"
# Copy the R script
COPY llm-extraction.r /app/
COPY prompt.md /app/
COPY ollama_schema.json /app/

# Set working directory
WORKDIR /app

# Run the R script
CMD ["Rscript", "llm-extraction.r"]
