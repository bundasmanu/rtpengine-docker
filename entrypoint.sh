#!/bin/bash

set -e

trap "Ok received Exit" HUP INT QUIT TERM

update_vars() {

    TMP_BASE_FOLDER="/tmp/confs_env_subst"

    mkdir -p "$TMP_BASE_FOLDER"

    tmpfile="${TMP_BASE_FOLDER}/${2}.tmp"

    envsubst < "$1/$2" > "$tmpfile" && sudo /bin/mv -f "$tmpfile" "$1/$2"

    rm -rf "$TMP_BASE_FOLDER"

}

update_syslog_file() {
    sed -i "s|\${RTPENGINE_LOG_DIR}|$RTPENGINE_LOG_DIR|g" /etc/rsyslog.d/rtpengine.conf
    sed -i "s|\${RTPENGINE_LOG_FILENAME}|$RTPENGINE_LOG_FILENAME|g" /etc/rsyslog.d/rtpengine.conf
    sed -i "s|\${RTPENGINE_USER}|$RTPENGINE_USER|g" /etc/rsyslog.d/rtpengine.conf
}

update_rsyslog() {
    update_vars /etc/logrotate.d rtpengine
    update_syslog_file
    rsyslogd -n &
}

case "$1" in
    shell)
        exec /bin/bash --login
        ;;
    run)
        update_vars $RTPENGINE_CONF_DIR rtpengine.conf
        update_rsyslog
        rtpengine -f --config-file ${RTPENGINE_CONF_DIR}/rtpengine.conf
        ;;
    cmd)
        shift
        echo "$@"
        rtpengine "$@"
        ;;
    *)
        echo "Executing custom command"
        exec "$@"
        ;;
esac
