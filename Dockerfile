FROM debian:stable-slim

ARG RTPENGINE_RELEASE
ARG RTPENGINE_USER

WORKDIR /tmp

RUN apt-get update && apt-get install -y \
    wget \
    gettext \
    rsyslog

RUN wget https://rtpengine.dfx.at/latest/pool/main/r/rtpengine-dfx-repo-keyring/rtpengine-dfx-repo-keyring_1.0_all.deb && \
    dpkg -i rtpengine-dfx-repo-keyring_1.0_all.deb && \
    rm -rf rtpengine-dfx-repo-keyring_1.0_all.deb

RUN CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) && \
    echo "deb [signed-by=/usr/share/keyrings/dfx.at-rtpengine-archive-keyring.gpg] https://rtpengine.dfx.at/$RTPENGINE_RELEASE $CODENAME main" | \
    tee /etc/apt/sources.list.d/dfx.at-rtpengine.list

RUN apt-get update && apt-get install -y \
    rtpengine \
    rtpengine-utils \
    rtpengine-daemon \
    rtpengine-daemon-dbgsym \
    rtpengine-recording-daemon \
    rtpengine-recording-daemon-dbgsym \
    rtpengine-kernel-dkms \
    rtpengine-perftest \
    rtpengine-perftest-dbgsym \
    rtpengine-perftest-data

WORKDIR /usr/local/src

COPY entrypoint.sh .

COPY conf/rtpengine.conf /etc/rtpengine/conf
COPY syslog/rtpengine-logrotate.conf /etc/logrotate.d/rtpengine
COPY syslog/rtpengine-syslog.conf /etc/rsyslog.d/rtpengine.conf

ENTRYPOINT [ "./entrypoint.sh" ]
CMD ["run"]
