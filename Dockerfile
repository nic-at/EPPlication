FROM debian:bookworm-slim

RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       libdaemon-control-perl \
       libdir-self-perl \
       libmodule-install-perl \
       libconfig-zomg-perl \
       libssl-dev \
       libssh2-1-dev \
       libxml2-dev \
       libexpat1-dev \
       zlib1g-dev \
       postgresql-server-dev-15 \
       postgresql-client-15 \
       nginx \
       ssh \
       carton \
       curl \
    && rm -rf /var/lib/apt/lists/*

ARG CONTAINER_UID=1000
RUN useradd --create-home --home-dir /home/epplication \
            --uid $CONTAINER_UID --user-group --shell /bin/bash epplication

RUN mkdir /home/epplication/EPPlication && chown epplication:epplication /home/epplication/EPPlication
WORKDIR /home/epplication/EPPlication
COPY --chown=epplication:epplication . /home/epplication/EPPlication/
VOLUME /home/epplication/EPPlication

EXPOSE 80
CMD ["bash", "./docker_entrypoint.sh"]
