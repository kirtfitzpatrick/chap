#!/usr/bin/env bash

# npm emits a big security vulnerability message if I add lodash-cli as a
# dev dependency. I only need it's output to commit to source control.
#
# lodash include=kebabCase,upperFirst,camelCase,join -o bin/util/lodash-lib.js -p
source bin/functions.sh

INCLUDES=(
  kebabCase
  upperFirst
  camelCase
  join
)
INCLUDES_STR=$(echo "${INCLUDES[@]}" | tr ' ' ',')

if ! command -v lodash &>/dev/null; then
  _echo_run "npm install -g lodash-cli"
fi

_echo_run "lodash include=${INCLUDES_STR} -o bin/util/lodash-lib.js -p"
