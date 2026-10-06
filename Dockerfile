FROM rocker/r-ver:4.6.1

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/render/project/src

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -q -e 'install.packages(c("shiny", "shinydashboard", "dplyr", "stringr", "tm", "e1071", "ggplot2", "plotly", "DT"), repos = "https://cloud.r-project.org")'

COPY . .

EXPOSE 10000

CMD ["R", "-q", "-e", "shiny::runApp('.', host = '0.0.0.0', port = as.integer(Sys.getenv('PORT', '10000')))"]