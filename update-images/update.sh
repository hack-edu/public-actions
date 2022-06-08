#!/usr/bin/env bash

set -eou pipefail

DEBUG="${DEBUG:-/dev/null}"

if [ "$DEBUG" != "/dev/null" ]; then
  set -x
  set - "-vdebug" "$@"
fi

env > "$DEBUG"

# skaffold build if JSON is missing
if [ x = x"${BUILD_JSON:-}" ]; then
  pushd "${BUILD_DIR:-.}" &> /dev/null || exit 1
  skaffold version > "${DEBUG}"
  BUILD_JSON="$(skaffold build "$@" --quiet | tee "$DEBUG")"
  popd &> /dev/null || exit 1
fi

CMDS="$(
  echo "$IMAGE_MAPPING" | docker run -i --rm ghcr.io/itchyny/gojq --yaml-input --argjson builds "${BUILD_JSON}" -r '
  . as $images | $builds | .builds[] |
    . as $build | ($images | to_entries[] |
        select(. as $e | $build.imageName | test($e.value))
            | .key) as $name |
          "kustomize edit set image \("\($name)=\(.tag)" | @sh)"' | tee "$DEBUG")"

if [ x = x"${DRY_RUN:-}" ]; then
  eval "$CMDS"
fi
