#!/usr/bin/env bash

[[ $DEBUG == true ]] && set -x
set -euo pipefail

configure_dokuwiki() {
    DOKUWIKI_LANG=${DOKUWIKI_LANG:-"en"}
    DOKUWIKI_TITLE=${DOKUWIKI_TITLE:-"DokuWiki"}
    DOKUWIKI_SUPERUSER=${DOKUWIKI_SUPERUSER:-"root"}
    DOKUWIKI_PASSWORD=${DOKUWIKI_PASSWORD:-"password"}
    DOKUWIKI_FULLNAME=${DOKUWIKI_FULLNAME:-"Administrator"}
    DOKUWIKI_EMAIL=${DOKUWIKI_EMAIL:-"root@$(hostname)"}

    tar -xzf dokuwiki.tgz --strip 1
    chown -hR www-data:www-data .
    rm -rf dokuwiki.tgz

    POSTDATA="submit="
    POSTDATA="${POSTDATA}&l=${DOKUWIKI_LANG}"
    POSTDATA="${POSTDATA}&d[title]=${DOKUWIKI_TITLE}"
    POSTDATA="${POSTDATA}&d[acl]=on"
    POSTDATA="${POSTDATA}&d[superuser]=${DOKUWIKI_SUPERUSER}"
    POSTDATA="${POSTDATA}&d[password]=${DOKUWIKI_PASSWORD}"
    POSTDATA="${POSTDATA}&d[confirm]=${DOKUWIKI_PASSWORD}"
    POSTDATA="${POSTDATA}&d[fullname]=${DOKUWIKI_FULLNAME}"
    POSTDATA="${POSTDATA}&d[email]=${DOKUWIKI_EMAIL}"
    POSTDATA="${POSTDATA}&d[policy]=1"
    POSTDATA="${POSTDATA}&d[license]=cc-by-sa"
    POSTDATA="${POSTDATA}&d[pop]=pop"

    INSTALL_MESSAGE="$(wget -q -O- --post-data "$POSTDATA" http://localhost/install.php)"
    if echo "$INSTALL_MESSAGE" | grep '"doku.php?id=wiki:welcome"' >/dev/null; then
        sleep 3
        rm -rf "${DOKUWIKI_HOME}/install.php"
    else
        echo "Failed to run the installer." >&2
        echo "$INSTALL_MESSAGE"
    fi
}

check_initialized_dokuwiki() {
    [[ -f "${DOKUWIKI_HOME}/install.php" && ! -f "${DOKUWIKI_CONF_DIR}/local.php" ]]
}

initialize_dokuwiki() {
    echo "Initialize DokuWiki"

    /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf >/dev/null &
    SUPERVISOR_PID=$!
    sleep 5
    configure_dokuwiki
    kill -15 $SUPERVISOR_PID
    ps h -p $SUPERVISOR_PID > /dev/null && wait $SUPERVISOR_PID
    rm -rf /var/run/supervisor.sock
}

if check_initialized_dokuwiki; then
    initialize_dokuwiki
fi

exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
