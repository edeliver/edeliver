#!/usr/bin/env bash
# Test running a docker release built by edeliver containing
# the echo server from https://github.com/xduludulu/erlang.eco
set -e -o pipefail

APP="eco"
GIT_REF="16da11b"
RELEASE_VERSION="0.1.0"
DOCKER_RUN_IMAGE="edeliver/echo-server"
BASE_DIR="$( cd "${0%/*}/../.." && pwd -P )"
TESTS_DIR="$( cd "${0%/*}" && pwd -P )"
DEFAULT_RUN_DIR="${BASE_DIR}/.test/run/${APP}"
RUN_DIR="${PROJECT_DIR:-"$DEFAULT_RUN_DIR"}"
START_SCRIPT="${RUN_DIR}/bin/${APP}"

_info() {
  echo $@
}

_error() {
  echo "" >&2
  echo $@ >&2
  echo "" >&2
  exit 1
}

if [ ! -d "$RUN_DIR" ]; then
  _info "Creating run dir '$RUN_DIR'"
  mkdir -p "${RUN_DIR}/bin"
fi

_info "Copying start script"
# copy start script and pin "deployed" version like edeliver does in `remote_extract_release_archive`
cat "${BASE_DIR}/docker/start_container" | sed "s/{{edeliver-version}}/${RELEASE_VERSION}-${GIT_REF}/g" > "$START_SCRIPT"
chmod u+x "$START_SCRIPT"

cd "$RUN_DIR"
export DOCKER_RUN_IMAGE APP
_info "Starting release…"
exec "$START_SCRIPT" console