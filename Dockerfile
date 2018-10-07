FROM debian:stable

ENV DOKUWIKI_VERSION="2018-04-22a" \
    DOKUWIKI_CSUM="18765a29508f96f9882349a304bffc03" \
    DOKUWIKI_HOME="/var/www/dokuwiki"

ENV DOKUWIKI_CONF_DIR="${DOKUWIKI_HOME}/conf" \
    DOKUWIKI_DATA_DIR="${DOKUWIKI_HOME}/data" \
    DOKUWIKI_PLUGIN_DIR="${DOKUWIKI_HOME}/lib/plugins" \
    DOKUWIKI_TPL_DIR="${DOKUWIKI_HOME}/lib/tpl"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      wget ca-certificates tar \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      supervisor logrotate locales nginx php-fpm \
      php-mbstring \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${DOKUWIKI_HOME}" \
 && cd "${DOKUWIKI_HOME}" \
 && wget -q -O "${DOKUWIKI_HOME}/dokuwiki.tgz" "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DOKUWIKI_VERSION}.tgz" \
 && md5sum dokuwiki.tgz | grep "${DOKUWIKI_CSUM}" \
 && tar -xz --strip 1 -f dokuwiki.tgz \
 && chown -R www-data:www-data "${DOKUWIKI_HOME}"

RUN rm -rf /etc/nginx/sites-enabled/*
COPY assets/dokuwiki-site /etc/nginx/sites-enabled/

COPY scripts/install.bash /sbin/install.bash
RUN bash /sbin/install.bash

COPY scripts/entrypoint.bash /sbin/entrypoint.bash
RUN chmod 755 /sbin/entrypoint.bash

EXPOSE 80/tcp 443/tcp

VOLUME ["${DOKUWIKI_CONF_DIR}","${DOKUWIKI_DATA_DIR}","${DOKUWIKI_PLUGIN_DIR}","${DOKUWIKI_TPL_DIR}"]
WORKDIR ${DOKUWIKI_HOME}

ENTRYPOINT ["/sbin/entrypoint.bash"]
