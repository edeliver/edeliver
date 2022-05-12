#!/usr/bin/env bash
# Test building a docker release using the echo server from
# https://github.com/xduludulu/erlang.eco
set -e -o pipefail

GIT_URL="${GIT_URL:-"https://github.com/xduludulu/erlang.eco"}"
GIT_REF="16da11b"
RELEASE_VERSION="0.1.0"
BASE_DIR="$( cd "${0%/*}/../.." && pwd -P )"
TESTS_DIR="$( cd "${0%/*}" && pwd -P )"
DEFAULT_PROJECT_DIR="${BASE_DIR}/.test/echo-server-rebar3"
EDELIVER="${BASE_DIR}/bin/edeliver"
PROJECT_DIR="${PROJECT_DIR:-"$DEFAULT_PROJECT_DIR"}"
DOCKER_IMAGE_NAME="edeliver/echo-server-rebar3"

_info() {
  echo $@
}

_error() {
  echo "" >&2
  echo $@ >&2
  echo "" >&2
  exit 1
}

if [ ! -x "$EDELIVER" ]; then
  _error "edeliver executable not found at '$EDELIVER'!"
fi

if [ ! -d "$PROJECT_DIR" ]; then
  _info "Creating project dir '$PROJECT_DIR'"
  mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"
_info "Cloning $GIT_URL"
git clone "$GIT_URL" .
_info "Checking out $GIT_REF"
git checkout "$GIT_REF"

_info "Building release…"
BUILD_HOST="docker" \
APP="eco" \
RELEASE_STORE="docker://${DOCKER_IMAGE_NAME}" \
BUILD_AT="/echo-server" \
BUILD_USER="root" \
REBAR_PROFILE="prod" \
DOCKER_BUILD_IMAGE="elixir:1.11.4" \
"$EDELIVER" build release --verbose --revision="$GIT_REF"

_info ""
_info "Checking whether image was built successfully…"
if [ -n "$(docker images -q ${DOCKER_IMAGE_NAME}:${RELEASE_VERSION}-${GIT_REF})" ]; then
  _info "Image was built successfully"
  echo
  echo "::set-output name=image::${DOCKER_IMAGE_NAME}:${RELEASE_VERSION}-${GIT_REF}"
else
  _error "Building image failed!"
fi