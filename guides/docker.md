# Docker Support 

edeliver also provides support for docker containers. It provides


  1. building in a docker container, which makes the need of a build host obsolete and …
  2. building a docker image which contains the release and can run the release as a docker container.

## Example Config

```sh
#./deliver/config

# Enable building in a docker container
BUILD_HOST="docker"

# Use this image to build the release. It must contain
# all build tools required to compile and build the release
DOCKER_BUILD_IMAGE="elixir:1.13.3" # default

# Enable embedding the release in a docker image. The
# release will be embedded into a docker image with this
# name and the release version as tag. Use the `--push` flag
# as edeliver command line arg or push it manually with
# `docker push edeliver/echo-server:<version>`.
RELEASE_STORE="docker://edeliver/echo-server"

# The image which is used to create the final release image
# specified in RELEASE_STORE which can be deployed. It should
# contain anything which is required during runtime. The default
# image just contains open ssl and expects that the erts is 
# embedded into the release.
DOCKER_RELEASE_BASE_IMAGE="edeliver/release-base:1.0" # default

# Runtime configuration if the default edeliver container start
# script is used which is deployed on `edeliver deploy release`
# command

# Forward port 8080 from the host to the container or any other
# port(s) your app exposes
DOCKER_OPTS="--publish 8080"

# Links or actually mounts the vm.args file from the (deploy) host 
# into the container at /$APP/releases/$VERSION/vm.args
# It configures the erlang / elixir node and could load e.g. additional
# config from the host with --config /etc/echo-server/sys.config
# In that case /etc/echo-server/ should also be mounted into the container,
# see below ↓
LINK_VM_ARGS="/etc/echo-server/vm.args"

# mount also configs into the container
DOCKER_OPTS+=" --mount type=bind,source=/etc/echo-server,target=/etc/echo-server"
```

## Building in a Docker Container
To build the release in a docker container (1.), `BUILD_HOST="docker"` must be set and optionally the `DOCKER_BUILD_IMAGE` which will be pulled and used to build the release, similar to a build host and should contain all tools needed. [elixir:1.13.3](https://hub.docker.com/_/elixir) is the default `DOCKER_BUILD_IMAGE` but you could also use [existing extended images](https://hub.docker.com/r/enpedasi/nodejs-phoenix), e.g. to build a [phoenix](https://phoenixframework.org/) app or build an own docker image containing everything required by your app.

## Building a Docker Image
To also embed the built release into a docker image (2.), edeliver needs to be configured to use a docker registry as release store by setting it e.g. like this in the `.deliver/config` file: `RELEASE_STORE="docker://<account-name>/<release-image-name>`, e.g. `docker://edeliver/echo-server` or `docker://eu.gcr.io/edeliver/echo-server`.

Edeliver then pulls a (runtime) base image from `DOCKER_RELEASE_BASE_IMAGE` (which defaults to [edeliver/release-base:1.0](https://hub.docker.com/r/edeliver/release-base)), copies the release into it and commits a new docker image as `/<account-name>/<release-image-name>:<release-version>-<git-rev>`, e.g. `edeliver/echo-server:1.0-f5ddf03` which can be pushed manually to the registry or automatically with the `--push` flag. This is the image which can be deployed and started on the staging or production hosts. Ensure the **docker daemon is authenticated** at the (private) registry by running `docker login` before or `gcloud auth login` etc. 
Since it is recommended to embed the erlang runtime into the release, the `DOCKER_RELEASE_BASE_IMAGE` needs to contain only libraries required during runtime, e.g. like the default image provided by edeliver:

```Docker
FROM ubuntu:focal-20220113

RUN apt update \
 && apt install -y libssl1.1 locales \
 && apt clean

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US:en"
```

## Deploying a Docker Image

`./edeliver deploy release to <staging|production> --version=<release-version>` deploys the release to a staging or production host by **pulling**  the image with the release version as tag and **extracting a script** from the path `/$APP/bin/start_container` in the container to `$DELIVER_TO/bin/$APP` on the host. If no such script is embedded, edeliver copies its own [generic script](https://github.com/edeliver/edeliver/blob/f5ddf03377141cad24af2e9e0fb704e2c06b2411/docker/start_container) there. It can also be used as template and when embedding a modified extended version. The script location in the container can be changed with `CONTAINER_START_SCRIPT`.

When extracting the script or copying the default script edeliver pins the deployed version by replacing the string `{{edeliver-version}}` with the deployed version, `{{edeliver-docker-image}}` with the image name from the `RELEASE_STORE` and other tags, like `{{edeliver-app}}` with `$APP` and `{{edeliver-docker-opts}}` with `DOCKER_OPTS` from the `.deliver/config`. They can be used e.g. to **expose ports** used by the release from inside of the container to the host, e.g. `DOCKER_OPTS="--publish 8080"`.

It is required, that the deploy host is also authenticated at the private docker registry. To list available tags / versions you can run `./edeliver show releases`. For a private registry `DOCKER_REGISTRY_TOKEN` must be set in the `.deliver/config` because listing tags requires authentication at the docker registry directly because listing is not supported by the docker daemon. For gcloud you can set it e.g. like this: `DOCKER_REGISTRY_TOKEN="$(gcloud auth print-access-token || :)"`.

## Running a Docker Image

The extracted [script](https://github.com/edeliver/edeliver/blob/f5ddf03377141cad24af2e9e0fb704e2c06b2411/docker/start_container) at `$DELIVER_TO/bin/$APP` can be used to start and control the release as usual, e.g. to start the container in the foreground run `$DELIVER_TO/bin/$APP console` or to connect to a running node `$DELIVER_TO/bin/$APP remote_console`. This script **[configures](https://github.com/edeliver/edeliver/blob/f5ddf03377141cad24af2e9e0fb704e2c06b2411/docker/start_container#L80-L107) the container and the erlang / elixir node** to be able to run in a container and to connect to a running node in the container. 

To achieve this, edeliver starts the release **epmd-les**s and with an own [epmd module](https://github.com/edeliver/edeliver/blob/f5ddf03377141cad24af2e9e0fb704e2c06b2411/src/edeliver_epmd.erl). **Ensure edeliver is embedded as application in your release** to ensure it is available when the release boots. 

By default a node started by edeliver in a container **binds to a fixed distribution port** set as `ERL_DIST_PORT` env, by default `4321`. Known nodes which are configured to run on a different port (e.g. because they run on the same host) can be configured by the `nodes` `edeliver` application config e.g. in the `sys.config` file of the release or be passed space-separated in the `EDELIVER_NODES` environment variable. The port can be specified separated by a `:` if it does not listen on the default `ERL_DIST_PORT` or `DEFAULT_DIST_PORT` respectively which precedes the latter.
e.g.
```
EDELIVER_NODES="foo@bar.local baz@bar.local:4323` bin/my-app console
```
Starts a my-app node which can connect to `foo@bar.local` at distribution port `4321` and to
node `baz@bar.local` at port `4323`. Same can be achieved when setting it in the sys.config
```
 [{kernel, [{net_ticktime. 20}, …]},
  {edeliver, [{nodes, ['foo@bar.local', 'baz@bar.local:4323']},
  …]}]
```
