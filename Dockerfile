ARG REG=""
ARG REP="devopsansiblede"
ARG IMG="apache"
ARG VRS="php8"
ARG SRC="${REG}${REP}/${IMG}:${VRS}"

FROM "${SRC}"

LABEL org.opencontainers.image.authors="macwinnie <dev@macwinnie.me>"

# environmental variables
ENV START_CRON=1
ENV WORDPRESS_CONFIG_EXTRA=""
ENV WORDPRESS_DISABLE_WP_CRON="true"

# copy all relevant files
COPY files/ /

# organise file permissions and run installer
RUN chmod a+x /install.sh && \
    /install.sh && \
    rm -f /install.sh

# run on every (re)start of container
ENTRYPOINT [ "entrypoint" ]
CMD [ "apache2-foreground" ]
