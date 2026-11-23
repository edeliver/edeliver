#!/usr/bin/env bash
# Replaces lager with the logger built into OTP in the echo server test app
# (https://github.com/xduludulu/erlang.eco). The lager version it was written
# for does not compile on current OTP versions.
set -e -o pipefail

PROJECT_DIR="${1:?usage: $0 <project-dir>}"
SRC_DIR="${PROJECT_DIR}/apps/eco/src"

perl -pi -e 's/\blager:info\(/logger:info(/' "${SRC_DIR}/eco_protocol.erl"
# logger is part of kernel, so lager is just dropped from the applications
perl -0pi -e 's/ranch,\s*lager\s*\]/ranch\n   ]/' "${SRC_DIR}/eco.app.src"

if grep -q lager "${SRC_DIR}/eco_protocol.erl" "${SRC_DIR}/eco.app.src"; then
  echo "Failed to replace lager in ${SRC_DIR}" >&2
  exit 1
fi
