FROM debian:stretch

RUN    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
       build-essential \
       bzip2 \
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
       ssh vim less tree ack \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm Config::ZOMG && rm -rf /home/epplication/.cpanm/work/*

RUN useradd --create-home --home-dir /home/epplication \
            --user-group --shell /bin/bash epplication

COPY --chown=epplication:epplication . /home/epplication/EPPlication

WORKDIR /home/epplication/EPPlication

RUN cp /home/epplication/EPPlication/nginx.conf /etc/nginx/sites-available/epplication
RUN ln -s /etc/nginx/sites-available/epplication /etc/nginx/sites-enabled/epplication

RUN perl script/epplication_fcgi.initd get_init_file > /etc/init.d/epplication_fcgi
RUN chmod u+x /etc/init.d/epplication_fcgi
RUN update-rc.d epplication_fcgi defaults /etc/init.d/epplication_fcgi start

RUN perl script/epplication_taskrunner.initd get_init_file > /etc/init.d/epplication_taskrunner
RUN chmod u+x /etc/init.d/epplication_taskrunner
RUN update-rc.d epplication_taskrunner defaults

RUN    mkdir /var/log/epplication \
    && chown epplication:epplication /var/log/epplication \
    && mkdir /var/run/epplication \
    && chown epplication:epplication /var/run/epplication

RUN    mkdir /home/epplication/EPPlication/ssh_keys \
    && mkdir -p /home/epplication/EPPlication/root/job_exports \
    && chown -R epplication:epplication /home/epplication/EPPlication

VOLUME /home/epplication/EPPlication/ssh_keys
VOLUME /home/epplication/EPPlication/root/job_exports

USER epplication

RUN carton install && rm -rf /home/epplication/.cpanm/work/*

RUN carton exec script/epplication_config_helper.pl \
   --user epplication \
   --group epplication \
   --perl '/usr/bin/perl -I/home/epplication/EPPlication/local/lib/perl5 -I/home/epplication/EPPlication/lib' \
   --db-host db \
   --db-port 5432 \
   --db-name epplication \
   --db-user epplication \
   --db-password epplication \
   > epplication_web_local.pl

RUN carton exec script/epplication_config_helper.pl \
   --user epplication \
   --group epplication \
   --perl '/usr/bin/perl -I/home/epplication/EPPlication/local/lib/perl5 -I/home/epplication/EPPlication/lib' \
   --db-host db \
   --db-port 5432 \
   --db-name epplication_testing \
   --db-user epplication \
   --db-password epplication \
   > epplication_web_testing.pl

USER root
EXPOSE 80
RUN rm /etc/nginx/sites-enabled/default

CMD    /etc/init.d/ssh restart \
    && /etc/init.d/nginx restart \
    && /etc/init.d/epplication_fcgi restart \
    && /etc/init.d/epplication_taskrunner restart \
    && tail -f /var/log/epplication/main.log
