FROM debian:stretch

RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       carton \
       cpanminus \
       libdaemon-control-perl \
       libdir-self-perl \
       libmodule-install-perl \
       libssl-dev \
       libssh2-1-dev \
       libxml2-dev \
       zlib1g-dev \
       postgresql-server-dev-9.6 \
       postgresql-client-9.6 \
       nginx \
       ssh \
       libexpat1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm Config::ZOMG && rm -rf ~/.cpanm

RUN useradd --create-home --home-dir /home/epplication \
            --user-group --shell /bin/bash epplication

WORKDIR /home/epplication/EPPlication
COPY --chown=epplication:epplication ./cpanfile /home/epplication/EPPlication/
COPY --chown=epplication:epplication ./cpanfile.snapshot /home/epplication/EPPlication/
RUN carton install --deployment && rm -rf ~/.cpanm

COPY --chown=epplication:epplication . /home/epplication/EPPlication

RUN    cp /home/epplication/EPPlication/nginx.conf /etc/nginx/sites-available/epplication \
    && ln -s /etc/nginx/sites-available/epplication /etc/nginx/sites-enabled/epplication \
    && perl script/epplication_fcgi.initd get_init_file > /etc/init.d/epplication_fcgi \
    && chmod u+x /etc/init.d/epplication_fcgi \
    && update-rc.d epplication_fcgi defaults /etc/init.d/epplication_fcgi start \
    && perl script/epplication_taskrunner.initd get_init_file > /etc/init.d/epplication_taskrunner \
    && chmod u+x /etc/init.d/epplication_taskrunner \
    && update-rc.d epplication_taskrunner defaults \
    && mkdir /var/log/epplication \
    && touch /var/log/epplication/main.log \
    && chown -R epplication:epplication /var/log/epplication \
    && mkdir /var/run/epplication \
    && chown epplication:epplication /var/run/epplication \
    && carton exec script/epplication_config_helper.pl \
       --user epplication \
       --group epplication \
       --perl '/usr/bin/perl -I/home/epplication/EPPlication/local/lib/perl5 -I/home/epplication/EPPlication/lib' \
       --db-host epplication-db \
       --db-port 5432 \
       --db-name epplication \
       --db-user epplication \
       --db-password epplication \
       > epplication_web_local.pl \
    && carton exec script/epplication_config_helper.pl \
       --user epplication \
       --group epplication \
       --perl '/usr/bin/perl -I/home/epplication/EPPlication/local/lib/perl5 -I/home/epplication/EPPlication/lib' \
       --db-host epplication-db \
       --db-port 5432 \
       --db-name epplication_testing \
       --db-user epplication \
       --db-password epplication \
       > epplication_web_testing.pl \
    && mkdir /home/epplication/EPPlication/ssh_keys \
    && mkdir /home/epplication/EPPlication/root/job_exports \
    && chown -R epplication:epplication /home/epplication/EPPlication \
    && rm /etc/nginx/sites-enabled/default

VOLUME /home/epplication/EPPlication/ssh_keys
VOLUME /home/epplication/EPPlication/root/job_exports
EXPOSE 80
CMD ["bash", "./docker_entrypoint.sh"]
