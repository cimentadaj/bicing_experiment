FROM puckel/docker-airflow:1.10.9
ENV RENV_VERSION 0.12.0
ARG AIRFLOW_HOME=/usr/local/airflow
USER root

RUN apt-get update && apt-get install -y -f r-base=3.5.2-1 && \
    apt-get -y install libcurl4-openssl-dev libssl-dev

RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

ADD renv.lock renv.lock
RUN R -e "renv::restore(confirm = FALSE, clean = TRUE)"

ADD entrypoint.sh entrypoint.sh

USER airflow
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
