#!/usr/bin/env bash
# Test building a docker release using the echo server from
# https://github.com/xduludulu/erlang.eco
set -e -o pipefail

GIT_URL="${GIT_URL:-"https://github.com/xduludulu/erlang.eco"}"
GIT_REF="16da11b"
RELEASE_VERSION="0.1.0"
BASE_DIR="$( cd "${0%/*}/../.." && pwd -P )"
TESTS_DIR="$( cd "${0%/*}" && pwd -P )"
DEFAULT_PROJECT_DIR="${BASE_DIR}/.test/echo-server-distillery"
BRANCH_NAME="mix-distillery"
EDELIVER="${BASE_DIR}/bin/edeliver"
PROJECT_DIR="${PROJECT_DIR:-"$DEFAULT_PROJECT_DIR"}"
DOCKER_IMAGE_NAME="edeliver/echo-server-distillery"

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

_info "Applying distillery config…"
# copy mix.exs and remove rebar.config
cp "${TESTS_DIR}/../configs/mix-distillery.exs" "${PROJECT_DIR}/mix.exs"
git rm "${PROJECT_DIR}/rebar.config"
# create distillery release config
mkdir -p "${PROJECT_DIR}/rel"
cp "${TESTS_DIR}/../configs/distillery-rel-config.exs" "${PROJECT_DIR}/rel/config.exs"
cp "${TESTS_DIR}/../configs/distillery-vm.args" "${PROJECT_DIR}/rel/vm.args"
# create app config
mkdir -p "${PROJECT_DIR}/config"
cp "${TESTS_DIR}/../configs/distillery-app-config.exs" "${PROJECT_DIR}/config/config.exs"

# commit new configs
git add "${PROJECT_DIR}/mix.exs" "${PROJECT_DIR}/rel" "${PROJECT_DIR}/rel/vm.args"
git add "${PROJECT_DIR}/config/config.exs" "${PROJECT_DIR}/rel/config.exs"
git config user.email "edeliver-test@github.com"
git config user.name "Edeliver Test"
git commit -m "Add distillery mix file"
git branch -d "$BRANCH_NAME" 2>/dev/null || :
git checkout -b "$BRANCH_NAME"

GIT_REF="$(git rev-parse --short HEAD)"

_info "Building release…"
BUILD_HOST="docker" \
APP="eco" \
RELEASE_STORE="docker://${DOCKER_IMAGE_NAME}" \
BUILD_AT="/echo-server" \
BUILD_USER="root" \
MIX_ENV="prod" \
DOCKER_BUILD_IMAGE="elixir:1.11.4" \
"$EDELIVER" build release --verbose --branch="$BRANCH_NAME"

_info ""
_info "Checking whether image was built successfully…"
if [ -n "$(docker images -q ${DOCKER_IMAGE_NAME}:${RELEASE_VERSION}-${GIT_REF})" ]; then
  _info "Image was built successfully"
  echo "release_version=${RELEASE_VERSION}-${GIT_REF}" >> $GITHUB_ENV
  echo "release_store=docker://${DOCKER_IMAGE_NAME}" >> $GITHUB_ENV
else
  _error "Building image failed!"
fi