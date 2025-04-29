# rtpengine-docker

RTPEngine build to be used in docker containers, and to easily integrate with syslog and to provide an easy way to configure their configuration file(s).

- [rtpengine-docker](#rtpengine-docker)
  - [Purpose](#purpose)
  - [What offers](#what-offers)
  - [.env file](#env-file)
  - [Networks](#networks)
  - [Integration with Kamailio](#integration-with-kamailio)
  - [Build image](#build-image)
  - [Run RTPEngine](#run-rtpengine)
    - [Run Multiple Instances](#run-multiple-instances)
  - [CLI Interface](#cli-interface)
  - [Some considerations](#some-considerations)

## Purpose

The main reasons behind the need to create this repo, are mainly:

- The need to get a easy way to switch between different `RTPEngine` versions;
- The need to make easy the process to install, test and debug `RTPEngine` in a docker container;
- The need to get a functional `backbone` that it's easy to scale and integrate with `Kamailio`;

## What offers

- `RTPEngine` working in a container;
- Easy way to manage and switch between different `RTPEngine` versions;
- Easy way to scale multiple `RTPEngine` containers, changing only some environment variables;
- `rtpengine-ctl` integration;
- Log file managing integrated;

## .env file

- `RTPENGINE_RELEASE`: RTPEngine version to be used when installing the packages;
- `RTPENGINE_USER`: User defined to handle some generated files;
- `RTPENGINE_CONF_DIR`: Folder to store the `RTPEngine` configuration files (copied from the host on build);
- `RTPENGINE_LOG_DIR`: Folder to store the generated logs (rsyslog and logrotate handling);
- `RTPENGINE_LOG_FILENAME`: Name of the log file (when scaling, update the name to be unique, between instances);
- `RTPENGINE_RECORDINGS_DIR`: Folder to store the generated recordings;
- `LISTEN_IP_DEFAULT_INTERFACE`: IP address of the default interface (if you want to use multiple interfaces, please update `rtpengine.conf` accordingly);
- `MIN_PORT_DEFAULT_INTERFACE`: Minimum port to be used by the default interface;
- `MAX_PORT_DEFAULT_INTERFACE`: Maximum port to be used by the default interface;
- `LISTEN_IP_NG`: IP to listen for the NG protocol;
- `LISTEN_PORT_NG`: Port to listen for the NG protocol;
- `LISTEN_IP_CLI`: IP to listen for the CLI (command line interface);
- `LISTEN_PORT_CLI`: Port to listen for the CLI (command line interface);

**Note:** Keep in mind that more environment variables could be introduced to make the container and the configuration more flexible.

## Networks

By default, this build was built for a local environment. But could be used for other purposes, should only be needed to changes the networks on `docker-compose` file and change the IP address on `.env` file.

Requirements:

- `common-network`: This is a external network used in common with other containers, like: `kamailio` and `postgres` container. More details about how to create the network are described in: [postgres-kamailio-docker](https://github.com/bundasmanu/postgres-kamailio-docker);

## Integration with Kamailio

The integration with `Kamailio` is quite simple. No changes are needed here.
We only need to update some env vars in [kamailio-docker](https://github.com/bundasmanu/kamailio-docker); to point to the `RTPEngine` container(s).

## Build image

```sh
docker compose build rtpengine
```

## Run RTPEngine

```sh
docker compose up rtpengine -d
```

### Run Multiple Instances

When running multiple instances, it's only required to change the env vars that are needed to be unique for each instance:

- `RTPENGINE_LOG_FILENAME`;
- `LISTEN_PORT_NG` and `LISTEN_PORT_CLI`;
  - `LISTEN_IP_NG` or `LISTEN_IP_CLI` (if you want to use different IPs for each instance);

After that, run container as usual:

```sh
docker compose up rtpengine -d
```

## CLI Interface

```sh
rtpengine-ctl -ip 172.25.0.30 -port 2224 help
```

## Some considerations

- `.conf` files are copied from the host to the container, and the ENV var substitution is done after;
- Another possible approach is to handle this files as templates, and use `ansible`, `consul`, ..., to manage this files, and use volumes instead;
