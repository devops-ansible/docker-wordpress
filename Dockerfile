ARG REG=""
ARG REP="devopsansiblede"
ARG IMG="apache"
ARG VRS="latest"
ARG SRC="${REG}${REP}/${IMG}:${VRS}"

FROM "${SRC}"

MAINTAINER macwinnie <dev@macwinnie.me>

# environmental variables
ENV WORDPRESS_CONFIG_EXTRA=""

# copy all relevant files
COPY files/ /

# organise file permissions and run installer
RUN chmod a+x /install.sh && \
    /install.sh && \
    rm -f /install.sh

# run on every (re)start of container
ENTRYPOINT [ "entrypoint" ]
CMD [ "apache2-foreground" ]
