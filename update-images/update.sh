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

TAG_ONLY='split("@") | .[0]'
TAG_FILTER="${TAG_FILTER:-$TAG_ONLY}"
DIGEST='"\($imageName)@\(split("@") | .[1])"'
if [ digest = "${TAG_FILTER}" ]; then
  TAG_FILTER="$DIGEST"
fi

CMDS="$(
  echo "$IMAGE_MAPPING" | docker run -i --rm ghcr.io/itchyny/gojq --yaml-input --argjson builds "${BUILD_JSON}" -r '
def tag_filter($imageName):
  '"${TAG_FILTER}"';

  . as $images | $builds | .builds[] |
    . as $build | ($images | to_entries[] |
        select(. as $e | $build.imageName | test($e.value))
            | .key) as $name |
          # remove the digest from the image as it causes kustomize to include the tag in the name and confuses skaffold
          "kustomize edit set image \("\($name)=\(.tag | tag_filter($build.imageName))" | @sh)"' | tee "$DEBUG")"

if [ x = x"${DRY_RUN:-}" ]; then
  eval "$CMDS"
fi
