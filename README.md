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
  - [Kubernetes](#kubernetes)
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
- `LISTEN_IP_INTERNAL`: IP or hostname for the internal RTP interface (in Kubernetes, set automatically from StatefulSet DNS);
- `LISTEN_IP_EXTERNAL`: IP for the external RTP interface (default `127.0.0.1` in Helm; override via ArgoCD when the public IP is known);
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

## Kubernetes

Helm deploys RTPEngine as a **StatefulSet** in the **`rtpengine`** namespace, with **`hostNetwork: true`**. [`conf/rtpengine.conf`](conf/rtpengine.conf) is baked into the image; the chart only passes **environment variables** so `entrypoint.sh` can run `envsubst` at startup.

### Install

```sh
helm upgrade --install rtpengine ./helm/rtpengine-docker \
  --namespace rtpengine --create-namespace
```

Dry-run:

```sh
helm upgrade --install rtpengine ./helm/rtpengine-docker \
  --namespace rtpengine --create-namespace \
  --dry-run --debug
```

Rebuild the image after changing `conf/rtpengine.conf`.

### Values (scaling and external IP)

| Value | Default | Purpose |
|-------|---------|---------|
| `statefulset.replicas` | `1` | Number of pods |
| `rtpengine.listen.externalIP` | `127.0.0.1` | External interface IP (override when ready) |
| `rtpengine.listen.ngPort` / `cliPort` / `httpPort` | `2223` / `2224` / `2226` | Listen ports |

Per-pod **internal** listen addresses and **NG/CLI/HTTP** use StatefulSet DNS (`rtpengine-0.rtpengine.rtpengine.svc.cluster.local`, …), resolved in `entrypoint.sh` when `HEADLESS_SERVICE_NAME` and `POD_NAMESPACE` are set.

### ArgoCD example

```yaml
spec:
  destination:
    namespace: rtpengine
  source:
    helm:
      valueFiles:
        - values.yaml
      parameters:
        - name: statefulset.replicas
          value: "1"
        - name: rtpengine.listen.externalIP
          value: "203.0.113.10"
```

### Logs and recordings

- Logs: one PVC per pod via `volumeClaimTemplates` (`log-rtpengine-0`, …).
- Recordings: shared PVC `{{ release }}-recordings-pvc`.

```sh
kubectl -n rtpengine exec -it rtpengine-0 -- cat /etc/rtpengine/logs/rtpengine.log
```

### Scaling notes

With `hostNetwork`, replicas share the same ports — typically **one rtpengine pod per node**. When `replicas > 1`, configure Kamailio (or your control plane) to target each pod’s stable DNS name.

## Some considerations

- `.conf` files are copied into the image at build time; ENV var substitution runs at container start via `entrypoint.sh`;
- In Kubernetes, Helm only supplies environment variables (no ConfigMap for `rtpengine.conf`);
