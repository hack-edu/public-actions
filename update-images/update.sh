#!/usr/bin/env bash

skaffoldBuild() {
  local dir
  dir="$1"
  shift
  pushd $dir >&2 || exit 1
  skaffold build "$@" --quiet
  popd >&2 || exit 1
}

if [ x = x"${BUILD_JSON}" ]; then
  # shellcheck disable=SC2046
  BUILD_JSON="$(skaffoldBuild "${BUILD_DIR:-.}" "$@" | tee /dev/stderr)"
fi

CMDS="$(echo "$BUILD_JSON" | jq --argjson images "${IMAGE_MAPPING}" -r '.builds[] |
  . as $build | ($images | to_entries[] | select(. as $e | $build.imageName | test($e.value)) | .key) as $name |
  "kustomize edit set image \("\($name)=\(.tag)" | @sh)"' | tee /dev/stderr)"

if [ x = x"${DRY_RUN:-}" ]; then
  eval "$CMDS"
fi
